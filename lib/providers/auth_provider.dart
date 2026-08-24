import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  Session? _session;
  ProfileModel? _profile;
  bool _isLoading = true;

  User? get user => _user;
  Session? get session => _session;
  ProfileModel? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  bool get isAdmin => _profile?.isAdmin ?? false;

  AuthProvider() {
    _init();
  }

  void _init() {
    _user = _authService.currentUser;
    _session = _authService.currentSession;
    if (_user != null) {
      _loadProfile(_user!.id);
    } else {
      _isLoading = false;
      notifyListeners();
    }

    _authService.onAuthStateChange.listen((data) {
      final session = data.session;
      _session = session;
      _user = session?.user;

      if (_user != null) {
        _loadProfile(_user!.id);
      } else {
        _profile = null;
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  Future<void> _loadProfile(String userId) async {
    _profile = await _authService.fetchProfile(userId);
    _isLoading = false;
    notifyListeners();
  }

  Future<String?> signIn({required String email, required String password}) async {
    try {
      _isLoading = true;
      notifyListeners();
      final res = await _authService.signInWithPassword(email: email, password: password);
      _user = res.user;
      _session = res.session;
      if (_user != null) {
        await _loadProfile(_user!.id);
      }
      return null;
    } on AuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.message;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'An unexpected error occurred during login.';
    }
  }

  Future<String?> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      final res = await _authService.signUp(
        email: email,
        password: password,
        username: username,
      );
      _user = res.user;
      _session = res.session;

      // With Supabase Confirm email disabled, signUp returns a live session
      // immediately. If the session is null, the backend is still requiring
      // email confirmation, so do not pretend registration is complete.
      if (_session == null) {
        _isLoading = false;
        notifyListeners();
        return 'Account created, but Supabase is still requiring email confirmation. Disable Confirm email in Authentication -> Providers -> Email.';
      }

      if (_user != null) {
        await _loadProfile(_user!.id);
      }
      return null;
    } on AuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.message;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'An unexpected error occurred during registration.';
    }
  }

  Future<String?> signInWithGoogle() async {
    try {
      _isLoading = true;
      notifyListeners();
      await _authService.signInWithGoogle();
      // The OAuth callback is handled by Supabase and the auth-state listener
      // above. Keep loading until that callback produces a session.
      return null;
    } on AuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.message;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'Could not start Google sign-in.';
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _session = null;
    _profile = null;
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    if (_user != null) {
      await _loadProfile(_user!.id);
    }
  }
}
