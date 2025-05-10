import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

Future<AuthResponse> googleSignIn() async {
  const webClientId =
      '54391127653-dnmfm344ms3qv1i4gjg519rffcp6uhed.apps.googleusercontent.com';

  final GoogleSignIn googleSignIn = GoogleSignIn(
    serverClientId: webClientId,
    signInOption: SignInOption.standard,
  );

  // 👇 This will disconnect the previous account to force the picker
  try {
    await googleSignIn.disconnect();
  } catch (_) {
    // ignore if already disconnected
  }

  final googleUser = await googleSignIn.signIn();

  if (googleUser == null) {
    throw Exception('Google Sign-In was cancelled.');
  }

  final googleAuth = await googleUser.authentication;

  final accessToken = googleAuth.accessToken;
  final idToken = googleAuth.idToken;

  if (accessToken == null || idToken == null) {
    throw Exception('Missing Google Auth tokens.');
  }

  return supabase.auth.signInWithIdToken(
    provider: OAuthProvider.google,
    idToken: idToken,
    accessToken: accessToken,
  );
}
