import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:the_reminder_app/models/planner_models.dart';

/// Persists authentication events to Firebase so they stay in sync with Hive.
class FirebaseUserSyncService {
  FirebaseUserSyncService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> syncLogin({
    required AppUser user,
    required String loginMethod,
  }) async {
    final userDoc = _firestore.collection('users').doc(user.id);
    final now = FieldValue.serverTimestamp();

    final payload = <String, dynamic>{
      'email': user.email,
      'localCreatedAt': Timestamp.fromDate(user.createdAt.toUtc()),
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
}
