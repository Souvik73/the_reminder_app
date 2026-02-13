import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FirebaseEngagementService {
  FirebaseEngagementService({FirebaseMessaging? messaging})
    : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized || kIsWeb) return;

    try {
      await _messaging.setAutoInitEnabled(true);
      await _messaging.requestPermission(alert: true, badge: true, sound: true);
      await _messaging.getToken();
    } catch (error, stackTrace) {
      debugPrint('Firebase messaging init skipped: $error');
      debugPrint('$stackTrace');
    }

    _initialized = true;
  }

  Future<void> dispose() async {}
}
