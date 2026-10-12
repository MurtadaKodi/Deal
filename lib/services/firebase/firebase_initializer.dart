import 'package:deal/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseInitializer {
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      debugPrint('Firebase initialized successfully');
    } on FirebaseException catch (e) {
      if (e.code == 'duplicate-app') {
        debugPrint('Firebase already initialized');
        return;
      }

      debugPrint('Firebase initialization error: ${e.code}');
      rethrow;
    } catch (e) {
      debugPrint('Firebase initialization error: $e');
      rethrow;
    }
  }
}