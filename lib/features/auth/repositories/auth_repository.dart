import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../models/user_profile.dart';

class AuthRepository {
  final SupabaseClient _client = SupabaseService.client;

  User? get currentUser => _client.auth.currentUser;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final response =
          await _client.from('profiles').select().eq('id', userId).maybeSingle();
      return response == null ? null : UserProfile.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      return null;
    }
  }

  Future<AuthResponse> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? phone,
    String? customerId,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'role': role,
        if (phone != null) 'phone': phone,
        if (customerId != null) 'customer_id': customerId,
      },
    );

    final user = response.user;
    // When email confirmation is enabled, Supabase returns a user without
    // a session. The profile is created later by the database trigger.
    if (user != null && response.session != null) {
      await _upsertProfile(
        id: user.id,
        fullName: fullName,
        role: role,
        phone: phone,
        customerId: customerId,
      );
    }

    return response;
  }

  Future<void> _upsertProfile({
    required String id,
    required String fullName,
    required String role,
    String? phone,
    String? customerId,
  }) async {
    await _client.from('profiles').upsert({
      'id': id,
      'full_name': fullName,
      'phone': phone,
      'role': role,
      'customer_id': customerId,
      'is_active': true,
    });
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<void> updateProfile({
    required String userId,
    String? fullName,
    String? phone,
  }) async {
    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (phone != null) updates['phone'] = phone;

    if (updates.isNotEmpty) {
      await _client.from('profiles').update(updates).eq('id', userId);
    }
  }
}
