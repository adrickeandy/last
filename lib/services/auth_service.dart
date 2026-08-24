import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import '../core/config/env.dart';
import 'package:url_launcher/url_launcher.dart';
import 'supabase_service.dart';

class AuthService {
  final SupabaseClient _client = SupabaseService.client;

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: {'username': username},
    );
  }

  Future<void> signInWithGoogle() async {
    final response = await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: AppEnv.authRedirectUrl,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );

    if (!response) {
      throw AuthException('Could not start Google sign-in.');
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<ProfileModel?> fetchProfile(String userId) async {
    try {
      final data = await _client
          .from('profiles')
          .select('*')
          .eq('id', userId)
          .maybeSingle();

      if (data != null) {
        return ProfileModel.fromJson(data);
      }
      return null;
    } catch (e) {
      print('[AuthService] fetchProfile error: $e');
      return null;
    }
  }
}
