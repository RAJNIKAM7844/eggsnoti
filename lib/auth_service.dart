import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  /// Sign up with email and password
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String location,
  }) async {
    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      final user = response.user;

      if (user != null) {
        await supabase.from('users').insert({
          'id': user.id,
          'email': email,
          'full_name': fullName,
          'location': location,
        });
      }
    } catch (e) {
      print('Signup error: $e');
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Login error: $e');
      rethrow;
    }
  }

  /// Fetch user profile from Supabase `users` table
  Future<Map<String, dynamic>?> fetchUserProfile() async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        print("No user is currently logged in.");
        return null;
      }

      final response = await supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle(); // avoid exception if 0 or >1 rows

      return response;
    } catch (e) {
      print("Error fetching profile: $e");
      return null;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await supabase.auth.signOut();
  }
}
