import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/avatar_view.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/toast_overlay.dart';
import '../../../models/ai_message_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/pegasus_service.dart';

class PegasusChatView extends StatefulWidget {
  final bool compact;

  const PegasusChatView({super.key, this.compact = false});

  @override
  State<PegasusChatView> createState() => _PegasusChatViewState();
}

class _PegasusChatViewState extends State<PegasusChatView> {
  final _pegasusService = PegasusService();
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final List<AiMessageModel> _messages = [];
  bool _isLoadingHistory = true;
  bool _isGenerating = false;
  // True only in the gap between sending a message and the first streamed
  // chunk arriving; once text starts streaming the message bubble itself
  // is the indicator, so we stop showing the separate "thinking…" row.
  bool _awaitingFirstChunk = false;
  String? _errorMessage;

  final List<String> _suggestions = [
    'Summarize this concept for me: ',
    'Help me plan a study schedule for finals in ',
    'Explain this coding error and how to fix it: ',
    'Give me high-yield exam preparation tips for ',
  ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) {
      setState(() => _isLoadingHistory = false);
      return;
    }

    try {
      final history = await _pegasusService.fetchAiHistory(user.id);
      if (mounted) {
        setState(() {
          _messages.addAll(history);
          _isLoadingHistory = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      print('[PegasusChatView] loadHistory error: $e');
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend([String? textOverride]) async {
    final text = (textOverride ?? _inputController.text).trim();
    if (text.isEmpty || _isGenerating) return;

    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) {
      ToastOverlay.show(context, 'Sign in to chat with Pegasus', type: ToastType.error);
      return;
    }

    _inputController.clear();
    setState(() {
      _errorMessage = null;
      _messages.add(
        AiMessageModel(
          id: const Uuid().v4(),
          userId: user.id,
          role: AiRole.user,
          content: text,
          createdAt: DateTime.now().toIso8601String(),
        ),
      );
      _isGenerating = true;
      _awaitingFirstChunk = true;
    });
    _scrollToBottom();

    // Persist user query
    _pegasusService.saveAiMessage(
      userId: user.id,
      role: AiRole.user,
      content: text,
    );

    // Placeholder assistant message that we fill in as chunks stream in.
    final assistantId = const Uuid().v4();
    var streamedText = '';
    var placeholderAdded = false;

    try {
      await for (final chunk in _pegasusService.askPegasusStream(_messages)) {
        if (!mounted) return;
        streamedText += chunk;

        setState(() {
          _awaitingFirstChunk = false;
          if (!placeholderAdded) {
            _messages.add(
              AiMessageModel(
                id: assistantId,
                userId: user.id,
                role: AiRole.assistant,
                content: streamedText,
                createdAt: DateTime.now().toIso8601String(),
              ),
            );
            placeholderAdded = true;
          } else {
            _messages[_messages.length - 1] =
                _messages.last.copyWith(content: streamedText);
          }
        });
        _scrollToBottom();
      }

      if (mounted) {
        setState(() => _isGenerating = false);
      }

      if (streamedText.trim().isNotEmpty) {
        // Persist assistant reply once streaming completes.
        _pegasusService.saveAiMessage(
          userId: user.id,
          role: AiRole.assistant,
          content: streamedText,
        );
      }
    } catch (e) {
      print('[PegasusChatView] Generation error: $e');
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _awaitingFirstChunk = false;
          _errorMessage = e is PegasusException
              ? e.message
              : 'Pegasus encountered a problem responding. Please try again.';
          // Drop the empty/partial placeholder bubble on failure so we don't
          // leave a blank assistant message in the thread.
          if (placeholderAdded && streamedText.trim().isEmpty) {
            _messages.removeWhere((m) => m.id == assistantId);
          }
        });
      }
    }
  }

  Future<void> _clearHistory() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    setState(() => _messages.clear());
    await _pegasusService.clearAiHistory(user.id);
    ToastOverlay.show(context, 'Conversation cleared', type: ToastType.info);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final profile = auth.profile;

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppColors.darkGlassBorder : AppColors.lightGlassBorder,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  gradient: AppColors.pegasusGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pegasus AI',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Your campus study assistant',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkInk400 : AppColors.lightInk400,
                      ),
                    ),
                  ],
                ),
              ),
              if (_messages.isNotEmpty)
                IconButton(
                  tooltip: 'Clear conversation',
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  onPressed: _isGenerating ? null : _clearHistory,
                ),
            ],
          ),
        ),

        // Message Thread Area
        Expanded(
          child: _isLoadingHistory
              ? ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: 3,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, __) => const SkeletonLoader(height: 60),
                )
              : _messages.isEmpty
                  ? Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: AppColors.pegasusGradient,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.auto_awesome_rounded,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Ask Pegasus anything',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Homework help, summaries, study schedules, and coding explanations.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: isDark ? AppColors.darkInk400 : AppColors.lightInk400,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Quick Suggestions Chips
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: _suggestions.map((s) {
                                return ActionChip(
                                  backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(
                                      color: isDark ? AppColors.darkGlassBorder : AppColors.lightGlassBorder,
                                    ),
                                  ),
                                  label: Text(
                                    s.trim(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppColors.darkInk200 : AppColors.lightInk200,
                                    ),
                                  ),
                                  onPressed: () {
                                    _inputController.text = s;
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length + (_awaitingFirstChunk ? 1 : 0),
                      itemBuilder: (context, i) {
                        if (i == _messages.length && _awaitingFirstChunk) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 26,
                                  height: 26,
                                  decoration: const BoxDecoration(
                                    gradient: AppColors.pegasusGradient,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 14),
                                ),
                                const SizedBox(width: 10),
                                const Text('Pegasus is thinking…', style: TextStyle(fontSize: 12, color: AppColors.violet300)),
                              ],
                            ),
                          );
                        }

                        final msg = _messages[i];
                        final isMe = msg.role == AiRole.user;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                            children: [
                              if (!isMe) ...[
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: const BoxDecoration(
                                    gradient: AppColors.pegasusGradient,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 14),
                                ),
                                const SizedBox(width: 10),
                              ],
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? AppColors.violet500
                                        : (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04)),
                                    borderRadius: BorderRadius.circular(16),
                                    border: !isMe
                                        ? Border.all(
                                            color: isDark ? AppColors.darkGlassBorder : AppColors.lightGlassBorder,
                                          )
                                        : null,
                                  ),
                                  child: isMe
                                      ? Text(
                                          msg.content,
                                          style: const TextStyle(color: Colors.white, fontSize: 13.5),
                                        )
                                      : MarkdownBody(
                                          data: msg.content,
                                          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                                            p: TextStyle(
                                              fontSize: 13.5,
                                              height: 1.45,
                                              color: isDark ? AppColors.darkInk100 : AppColors.lightInk100,
                                            ),
                                            code: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.lime400,
                                              backgroundColor: isDark ? Colors.black45 : Colors.black12,
                                            ),
                                            codeblockDecoration: BoxDecoration(
                                              color: isDark ? Colors.black87 : const Color(0xFF1E1E2E),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                              if (isMe) ...[
                                const SizedBox(width: 10),
                                AvatarView(
                                  url: profile?.avatarUrl,
                                  name: profile?.fullName ?? profile?.username ?? 'Me',
                                  size: 28,
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
        ),

        // Error message warning banner
        if (_errorMessage != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.coral500.withOpacity(0.15),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.coral400, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppColors.coral400, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

        // Input Field
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.darkGlassBorder : AppColors.lightGlassBorder,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inputController,
                  style: const TextStyle(fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: 'Ask Pegasus…',
                    hintStyle: TextStyle(
                      fontSize: 13.5,
                      color: isDark ? AppColors.darkInk500 : AppColors.lightInk500,
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.darkGlassBorder : AppColors.lightGlassBorder,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.darkGlassBorder : AppColors.lightGlassBorder,
                      ),
                    ),
                  ),
                  onSubmitted: (_) => _handleSend(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.violet500,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(10),
                ),
                icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                onPressed: _isGenerating ? null : () => _handleSend(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
