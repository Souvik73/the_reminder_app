import 'package:hive_ce/hive.dart';

class AuthSession {
  const AuthSession({
    required this.userId,
    required this.email,
    this.displayName,
    this.photoUrl,
  });

  final String userId;
  final String email;
  final String? displayName;
  final String? photoUrl;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'userId': userId,
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
      };

  static AuthSession? fromDynamic(dynamic value) {
    if (value is! Map) return null;
    final userId = value['userId'];
    final email = value['email'];
    if (userId is! String || email is! String) return null;
    final displayName = value['displayName'];
    final photoUrl = value['photoUrl'];
    return AuthSession(
      userId: userId,
      email: email,
      displayName: displayName is String ? displayName : null,
      photoUrl: photoUrl is String ? photoUrl : null,
    );
  }
}

class AuthSessionStore {
  static const _boxName = 'auth_session';
  static const _sessionKey = 'active';

  Future<AuthSession?> read() async {
    final box = await _openBox();
    return AuthSession.fromDynamic(box.get(_sessionKey));
  }

  Future<void> save(AuthSession session) async {
    final box = await _openBox();
    await box.put(_sessionKey, session.toMap());
  }

  Future<void> clear() async {
    final box = await _openBox();
    await box.delete(_sessionKey);
  }

  Future<Box> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box(_boxName);
    }
    return Hive.openBox(_boxName);
  }
}
