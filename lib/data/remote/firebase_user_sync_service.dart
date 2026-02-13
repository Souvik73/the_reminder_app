import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:the_reminder_app/models/planner_models.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Persists authentication events to Firebase so they stay in sync with Hive.
class FirebaseUserSyncService {
  FirebaseUserSyncService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static bool _timezoneInitialized = false;
  static const String _istTimeZoneName = 'Asia/Kolkata';

  Future<void> syncLogin({
    required AppUser user,
    required String loginMethod,
  }) async {
    _ensureTimeZoneInitialized();
    final userDoc = _firestore.collection('users').doc(user.id);
    final now = FieldValue.serverTimestamp();
    final DateTime createdAtIst = _toIstDate(user.createdAt);

    final payload = <String, dynamic>{
      'email': user.email,
      'localCreatedAt': Timestamp.fromDate(createdAtIst),
      'lastLoginAt': now,
      'lastLoginMethod': loginMethod,
      'syncedAt': now,
    };

    if (user.displayName != null) {
      payload['displayName'] = user.displayName;
    }

    await userDoc.set(payload, SetOptions(merge: true));

    await userDoc.collection('login_events').add({
      'method': loginMethod,
      'loggedInAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteUserData(String userId) async {
    final userDoc = _firestore.collection('users').doc(userId);
    final loginEvents = await userDoc.collection('login_events').get();
    for (final event in loginEvents.docs) {
      await event.reference.delete();
    }
    await userDoc.delete();
  }

  void _ensureTimeZoneInitialized() {
    if (_timezoneInitialized) return;
    tz.initializeTimeZones();
    _timezoneInitialized = true;
  }

  DateTime _toIstDate(DateTime dateTime) {
    final location = tz.getLocation(_istTimeZoneName);
    return tz.TZDateTime.from(dateTime, location);
  }
}
