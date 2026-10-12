import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  NotificationService._();

  static FirebaseMessaging get messaging => FirebaseMessaging.instance;

  static StreamSubscription<User?>? _authSubscription;
  static StreamSubscription<String>? _tokenSubscription;

  static String? _registeredUid;
  static String? _registeredToken;
  static bool _enabled = false;

  // Serialize token writes and removals.
  static Future<void> _pendingOperation = Future<void>.value();

  static Future<void> _enqueue(Future<void> Function() operation) {
    final result = _pendingOperation.then((_) => operation());

    // A failed operation must not block the next operation.
    _pendingOperation = result.catchError((Object error) {
      debugPrint('FCM operation error: $error');
    });

    return result;
  }

  static bool get _isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<void> requestPermissions() async {
    final settings = await messaging.requestPermission(alert: true, badge: true, sound: true);

    debugPrint('Notification permission: ${settings.authorizationStatus}');
  }

  static Future<String?> getToken() async {
    if (kIsWeb) {
      debugPrint('FCM Web setup pending.');
      return null;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      final apnsToken = await messaging.getAPNSToken();
      if (apnsToken == null) return null;
    }

    return messaging.getToken();
  }

  static String get _platform {
    if (kIsWeb) return 'web';

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      default:
        return 'unsupported';
    }
  }

  static String _tokenId(String token) {
    return sha256.convert(utf8.encode(token)).toString();
  }

  static DocumentReference<Map<String, dynamic>> _tokenRef(String uid, String token) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('fcmTokens')
        .doc(_tokenId(token));
  }

  static Future<void> _saveToken(String uid, String token) async {
    if (_platform == 'unsupported') return;

    await _tokenRef(
      uid,
      token,
    ).set({'token': token, 'platform': _platform, 'updatedAt': FieldValue.serverTimestamp()});

    debugPrint('FCM token saved successfully.');
  }

  static Future<void> _deleteToken(String uid, String token) async {
    await _tokenRef(uid, token).delete();
    debugPrint('FCM token removal requested.');
  }

  static Future<void> _registerToken(String uid, String token) {
    return _enqueue(() async {
      if (!_enabled || _registeredUid != uid || FirebaseAuth.instance.currentUser?.uid != uid) {
        return;
      }

      final previousToken = _registeredToken;

      await _saveToken(uid, token);

      _registeredToken = token;

      if (previousToken != null && previousToken != token) {
        await _deleteToken(uid, previousToken);
      }
    });
  }

  static Future<void> initialize() async {
    if (_authSubscription != null) return;

    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user?.uid == _registeredUid) return;

      _enabled = false;
      _registeredUid = null;
      _registeredToken = null;
    });

    if (_isAndroid) {
      _tokenSubscription = messaging.onTokenRefresh.listen(
        (token) {
          final uid = _registeredUid;

          if (!_enabled || uid == null) return;

          _registerToken(uid, token).catchError((Object error) {
            debugPrint('FCM refresh error: $error');
          });
        },
        onError: (Object error) {
          debugPrint('FCM token stream error: $error');
        },
      );
    }
  }

  // Temporary Android test from the seller dashboard.

  static Future<bool> testAndroidFcm() async {
    if (!_isAndroid) return false;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.isAnonymous) {
      debugPrint('FCM: Seller login required.');
      return false;
    }

    try {
      final settings = await messaging.requestPermission(alert: true, badge: true, sound: true);

      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        debugPrint('FCM: Notification permission denied.');
        return false;
      }

      final token = await getToken();

      if (token == null) {
        debugPrint('FCM: Token unavailable.');
        return false;
      }

      if (FirebaseAuth.instance.currentUser?.uid != user.uid) {
        return false;
      }

      _registeredUid = user.uid;
      _enabled = true;

      await _registerToken(user.uid, token);

      final success = _enabled && _registeredUid == user.uid && _registeredToken == token;

      if (success) {
        debugPrint('FCM: Seller device registered.');
      }

      return success;
    } catch (e) {
      debugPrint('FCM Android error: $e');
      return false;
    }
  }

  static Future<void> unregisterCurrentDevice() async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = _registeredUid ?? user?.uid;

    // Stop new registrations immediately.
    _enabled = false;
    _registeredUid = null;

    final token = _registeredToken;
    _registeredToken = null;

    // Wait for earlier writes, then remove the registered token.
    await _enqueue(() async {
      if (uid == null) return;

      final tokenToRemove = token ?? await getToken();
      if (tokenToRemove == null) return;

      await _deleteToken(uid, tokenToRemove);
    });
  }

  static Future<void> dispose() async {
    _enabled = false;
    _registeredUid = null;
    _registeredToken = null;

    await _authSubscription?.cancel();
    await _tokenSubscription?.cancel();

    _authSubscription = null;
    _tokenSubscription = null;
  }
}
