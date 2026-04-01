import 'package:hive/hive.dart';
import '../../domain/entities/active_session.dart';
import '../../domain/repositories/session_repository.dart';
import '../models/active_session_model.dart';

/// Session Repository Hive Implementation - Persisting routine state to disk.
/// // Fulfills INT-03, INT-05, INT-06, INT-11 (Persistence)
class SessionRepositoryImpl implements SessionRepository {
  final Box<ActiveSessionModel> _box;
  static const _sessionKey = 'active_session';

  SessionRepositoryImpl(this._box);

  @override
  Future<void> saveSession(ActiveSession session) async {
    final model = ActiveSessionModel.fromEntity(session);
    await _box.put(_sessionKey, model);
  }

  @override
  Future<ActiveSession?> loadSession() async {
    final model = _box.get(_sessionKey);
    return model?.toEntity();
  }

  @override
  Future<void> clearSession() async {
    await _box.delete(_sessionKey);
  }
}
