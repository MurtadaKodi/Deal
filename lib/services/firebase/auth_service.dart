import 'package:firebase_auth/firebase_auth.dart';

class DealAuthService {
  static FirebaseAuth get instance => FirebaseAuth.instance;

  static const String _internalDomain = 'deal.app';

  static String usernameToEmail(String username) {
    final normalized = username.trim().toLowerCase();

    if (normalized.isEmpty) {
      return '';
    }

    return '$normalized@$_internalDomain';
  }

  static Stream<User?> get authStateChanges =>
      instance.authStateChanges();

  static Future<UserCredential> signInWithUsername({
    required String username,
    required String password,
  }) {
    final email = usernameToEmail(username);

    return instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  static Future<UserCredential> createSellerAccount({
    required String username,
    required String password,
  }) {
    final email = usernameToEmail(username);

    return instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> signOut() => instance.signOut();
}