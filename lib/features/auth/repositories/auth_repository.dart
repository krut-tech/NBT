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
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        return UserProfile.fromJson(response);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      return null;
    }
  }

  Future<AuthResponse> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Self-registration. The database trigger `handle_new_user` creates the profile row
  /// (always with role `customer`) from the metadata below. The client must never choose
  /// a role: staff roles are assigned by an admin from the Staff screen afterwards.
  Future<AuthResponse> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      },
    );
  }

  /// Admin / manager only (enforced by RLS): change the role of an existing profile.
  Future<void> updateRole({required String userId, required String role}) async {
    await _client.from('profiles').update({'role': role}).eq('id', userId);
  }

  /// Admin / manager only (enforced by RLS + a database trigger): link a customer
  /// login to its customer record so the customer portal shows the right data.
  Future<void> updateCustomerLink({
    required String userId,
    required String? customerId,
  }) async {
    await _client
        .from('profiles')
        .update({'customer_id': customerId}).eq('id', userId);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> updateProfile({
    required String userId,
    String? fullName,
    String? phone,
  }) async {
    final Map<String, dynamic> updates = {};
    if (fullName != null) updates['full_name'] = fullName;
    if (phone != null) updates['phone'] = phone;

    if (updates.isNotEmpty) {
      await _client.from('profiles').update(updates).eq('id', userId);
    }
  }
}
