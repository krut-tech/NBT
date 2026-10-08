import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../repositories/auth_repository.dart';

/// Bumped on every explicit sign out; `SessionScope` (main.dart) listens to it and
/// recreates the whole ProviderScope so no data survives from one user to the next.
final ValueNotifier<int> sessionResetNotifier = ValueNotifier<int>(0);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

class AuthStateNotifier extends StateNotifier<AsyncValue<UserProfile?>> {
  final AuthRepository _repository;
  StreamSubscription? _authSub;

  // While signIn / signUp run, they own the state: the auth stream must not
  // flip it to "loading" (that would bounce the user to the splash screen and
  // throw away the login form together with its error message).
  bool _manualAuth = false;
  String? _loadingUserId;

  AuthStateNotifier(this._repository) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    _authSub = _repository.authStateChanges.listen((data) async {
      if (_manualAuth) return;

      final user = data.session?.user;
      if (user == null) {
        state = const AsyncValue.data(null);
        return;
      }

      // The stream also fires on every token refresh (about once an hour).
      // Ignore those while the profile is already loaded.
      if (state.valueOrNull?.id == user.id) return;

      await _loadProfile(user.id);
    });

    // Initial check (restores the persisted session)
    final initialUser = _repository.currentUser;
    if (initialUser != null) {
      _loadProfile(initialUser.id);
    } else {
      state = const AsyncValue.data(null);
    }
  }

  /// Loads the profile of an already signed-in user (app start / session restore).
  /// A user without a usable profile is signed out instead of being left in limbo.
  Future<void> _loadProfile(String userId) async {
    if (_loadingUserId == userId) return;
    _loadingUserId = userId;
    try {
      final profile = await _repository.getUserProfile(userId);
      if (!mounted) return;

      if (profile == null || !profile.isActive) {
        await _repository.signOut();
        if (mounted) state = const AsyncValue.data(null);
        return;
      }
      state = AsyncValue.data(profile);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    } finally {
      _loadingUserId = null;
    }
  }

  /// Fetches the profile after a manual sign in / sign up. Throws a readable error
  /// (and signs out) when the account cannot be used.
  Future<UserProfile> _profileOrSignOut(String userId) async {
    final profile = await _repository.getUserProfile(userId);
    if (profile == null) {
      await _repository.signOut();
      throw Exception(
          'Could not load your profile. Check your connection or contact the administrator.');
    }
    if (!profile.isActive) {
      await _repository.signOut();
      throw Exception(
          'Your account has been deactivated. Please contact the administrator.');
    }
    return profile;
  }

  /// Throws on failure (wrong password, inactive account, ...); the state is only
  /// changed on success, so the login screen keeps its form and error message.
  Future<void> signIn({required String email, required String password}) async {
    _manualAuth = true;
    try {
      final response = await _repository.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) {
        throw Exception('Sign in failed. Please try again.');
      }
      final profile = await _profileOrSignOut(user.id);
      if (mounted) state = AsyncValue.data(profile);
    } finally {
      _manualAuth = false;
    }
  }

  /// Registers a customer account. Returns true when the user is signed in right away,
  /// false when the project requires e-mail confirmation first (no session yet).
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    _manualAuth = true;
    try {
      final response = await _repository.signUpWithEmailAndPassword(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );
      final user = response.user;
      if (user == null || response.session == null) {
        return false;
      }
      final profile = await _profileOrSignOut(user.id);
      if (mounted) state = AsyncValue.data(profile);
      return true;
    } finally {
      _manualAuth = false;
    }
  }

  Future<void> signOut() async {
    try {
      await _repository.signOut();
    } catch (e) {
      // Offline etc.: the local session is cleared by the SDK anyway.
      debugPrint('Sign out error: $e');
    } finally {
      if (mounted) state = const AsyncValue.data(null);
      // Drop every cached provider (see SessionScope in main.dart).
      sessionResetNotifier.value++;
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}

final authProvider =
    StateNotifierProvider<AuthStateNotifier, AsyncValue<UserProfile?>>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthStateNotifier(repository);
});
