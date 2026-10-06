import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

class AuthStateNotifier extends StateNotifier<AsyncValue<UserProfile?>> {
  final AuthRepository _repository;

  AuthStateNotifier(this._repository) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    _repository.authStateChanges.listen((data) async {
      final user = data.session?.user;
      if (user != null) {
        await fetchProfile(user.id);
      } else {
        state = const AsyncValue.data(null);
      }
    });

    // Initial check
    final initialUser = _repository.currentUser;
    if (initialUser != null) {
      fetchProfile(initialUser.id);
    } else {
      state = const AsyncValue.data(null);
    }
  }

  Future<void> fetchProfile(String userId) async {
    state = const AsyncValue.loading();
    try {
      final profile = await _repository.getUserProfile(userId);
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      final response = await _repository.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (response.user != null) {
        await fetchProfile(response.user!.id);
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? phone,
    String? customerId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final response = await _repository.signUpWithEmailAndPassword(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
        phone: phone,
        customerId: customerId,
      );
      if (response.user != null) {
        await fetchProfile(response.user!.id);
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _repository.signOut();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final authProvider =
    StateNotifierProvider<AuthStateNotifier, AsyncValue<UserProfile?>>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthStateNotifier(repository);
});
