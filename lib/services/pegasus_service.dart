import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/env.dart';
import '../models/ai_message_model.dart';
import 'supabase_service.dart';

/// Thrown for any Pegasus/Gemini failure that should be surfaced to the UI
/// with a readable message (bad key, network error, API error, etc).
class PegasusException implements Exception {
  final String message;
  PegasusException(this.message);
  @override
  String toString() => message;
}

class _RateLimitException implements Exception {}

/// A request-level failure that would fail identically on every key (e.g. a
/// malformed request body, or an invalid/revoked API key returning 400/401/403).
/// Not worth burning the remaining keys retrying it.
class _PermanentException implements Exception {
  final String message;
  _PermanentException(this.message);
}

/// Pegasus — CampusX's built-in AI assistant.
///
/// Wraps the Gemini API with:
///  - true token-by-token streaming (streamGenerateContent over SSE), so the
///    UI can render partial replies as they arrive instead of waiting on a
///    single blocking request;
///  - automatic key rotation/failover across AppEnv.geminiApiKeys when one
///    key is rate-limited;
///  - a bounded conversation window (AppEnv.geminiMaxHistoryTurns) so token
///    usage/cost doesn't grow unbounded on long chats;
///  - a proper `system_instruction` field (rather than faking it as a first
///    chat turn), and a hard `maxOutputTokens` cap;
///  - Supabase-backed persistence of the conversation per signed-in user.
class PegasusService {
  final http.Client _client;
  final SupabaseClient _db = SupabaseService.client;
  int _currentKeyIndex = 0;

  PegasusService({http.Client? client}) : _client = client ?? http.Client();

  // ---------------------------------------------------------------------
  // Persistence (Supabase) — unchanged contract used by PegasusChatView.
  // ---------------------------------------------------------------------

  Future<List<AiMessageModel>> fetchAiHistory(String userId) async {
    final data = await _db
        .from('ai_messages')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', ascending: true)
        .limit(200);

    return (data as List)
        .map((json) => AiMessageModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveAiMessage({
    required String userId,
    required AiRole role,
    required String content,
  }) async {
    await _db.from('ai_messages').insert({
      'user_id': userId,
      'role': role == AiRole.assistant ? 'assistant' : 'user',
      'content': content,
    });
  }

  Future<void> clearAiHistory(String userId) async {
    await _db.from('ai_messages').delete().eq('user_id', userId);
  }

  // ---------------------------------------------------------------------
  // Gemini call — streaming + key rotation.
  // ---------------------------------------------------------------------

  static const String _systemInstruction = '''
You are Pegasus AI, the campus assistant built into CampusX. You help students with:
- Homework and studying
- Text summaries and lecture notes
- Explaining coding errors and concepts
- Exam preparation and study scheduling
- Ideas and general campus advice

Be helpful, clear, accurate, and encouraging. Format responses in clean
Markdown (headers, lists, code blocks, bold text where appropriate). Do not
invent university-specific fake policies — if unsure of something
campus-specific, say so. If asked your name or what model you are, you are
Pegasus; never mention Gemini or Google's model names.
''';

  /// Streams reply text chunks as they arrive. [history] is prior turns
  /// (oldest first), NOT including the newest user message, which must
  /// already be the last element passed in via [fullConversation].
  Stream<String> askPegasusStream(List<AiMessageModel> fullConversation) async* {
    final keys = AppEnv.geminiApiKeys;
    if (keys.isEmpty) {
      throw PegasusException(
        'Pegasus AI key is not configured. Build with '
        '--dart-define=GEMINI_API_KEY=your_key (see README).',
      );
    }
    if (fullConversation.isEmpty) {
      throw PegasusException('Nothing to send.');
    }

    PegasusException? lastError;

    for (int attempt = 0; attempt < keys.length; attempt++) {
      final index = (_currentKeyIndex + attempt) % keys.length;
      final key = keys[index];

      try {
        var succeeded = false;
        await for (final chunk in _streamApi(fullConversation, key)) {
          succeeded = true;
          yield chunk;
        }
        if (succeeded) {
          _currentKeyIndex = index;
          return;
        }
      } on _RateLimitException {
        lastError = PegasusException('All configured Pegasus keys are rate-limited.');
        continue;
      } on _PermanentException catch (e) {
        // Not worth retrying on other keys — the request itself is invalid
        // (e.g. malformed body), so every key would fail the same way.
        throw PegasusException(e.message);
      } on PegasusException catch (e) {
        // Anything else (5xx, network blip, timeout) is treated as
        // retryable: move on to the next key rather than failing the whole
        // request on one bad response.
        lastError = e;
        continue;
      }
    }

    throw lastError ?? PegasusException('Pegasus is temporarily unavailable.');
  }

  Stream<String> _streamApi(
    List<AiMessageModel> fullConversation,
    String apiKey,
  ) async* {
    final uri = Uri.parse(
      '${AppEnv.geminiBaseUrl}/${AppEnv.geminiModel}:streamGenerateContent?alt=sse',
    );

    final windowed = fullConversation.length > AppEnv.geminiMaxHistoryTurns * 2
        ? fullConversation.sublist(
            fullConversation.length - AppEnv.geminiMaxHistoryTurns * 2)
        : fullConversation;

    final contents = windowed
        .map((m) => {
              'role': m.role == AiRole.assistant ? 'model' : 'user',
              'parts': [
                {'text': m.content}
              ],
            })
        .toList();

    final body = jsonEncode({
      'system_instruction': {
        'parts': [
          {'text': _systemInstruction}
        ],
      },
      'contents': contents,
      'generationConfig': {
        'maxOutputTokens': AppEnv.geminiMaxOutputTokens,
        'thinkingConfig': {'thinkingLevel': AppEnv.geminiThinkingLevel},
      },
    });

    final request = http.Request('POST', uri)
      ..headers['x-goog-api-key'] = apiKey
      ..headers['content-type'] = 'application/json'
      ..body = body;

    http.StreamedResponse response;
    try {
      response = await _client.send(request).timeout(const Duration(seconds: 60));
    } catch (e) {
      throw PegasusException('Network error — check your connection.');
    }

    if (response.statusCode == 429) {
      throw _RateLimitException();
    }

    if (response.statusCode == 400 ||
        response.statusCode == 401 ||
        response.statusCode == 403) {
      final raw = await response.stream.bytesToString();
      throw _PermanentException(
        'Pegasus API error (${response.statusCode}): ${_extractErrorMessage(raw)}',
      );
    }

    if (response.statusCode != 200) {
      final raw = await response.stream.bytesToString();
      throw PegasusException(
        'Pegasus API error (${response.statusCode}): ${_extractErrorMessage(raw)}',
      );
    }

    // Server-Sent Events: each event is a line starting with "data: "
    // followed by a JSON chunk. Buffer partial lines since SSE frames
    // don't always align with TCP packet boundaries.
    String buffer = '';
    await for (final bytes in response.stream) {
      buffer += utf8.decode(bytes, allowMalformed: true);
      final lines = buffer.split('\n');
      buffer = lines.removeLast();

      for (final line in lines) {
        final trimmedLine = line.trim();
        if (!trimmedLine.startsWith('data: ')) continue;
        final jsonStr = trimmedLine.substring(6).trim();
        if (jsonStr.isEmpty || jsonStr == '[DONE]') continue;

        try {
          final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
          final candidates = decoded['candidates'] as List?;
          if (candidates == null || candidates.isEmpty) continue;
          final parts = candidates[0]['content']?['parts'] as List?;
          if (parts == null) continue;
          final text = parts.map((p) => p['text'] as String? ?? '').join();
          if (text.isNotEmpty) yield text;
        } catch (_) {
          continue;
        }
      }
    }
  }

  String _extractErrorMessage(String rawBody) {
    try {
      final decoded = jsonDecode(rawBody) as Map<String, dynamic>;
      return decoded['error']?['message'] as String? ?? 'Unknown error';
    } catch (_) {
      return 'Unknown error';
    }
  }

  void dispose() => _client.close();
}
