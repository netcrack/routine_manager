import 'package:hive/hive.dart';
import '../../../../core/domain_error.dart';
import '../../../../core/result.dart';
import '../../domain/entities/active_session.dart';
import '../../domain/repositories/session_repository.dart';
import '../models/active_session_model.dart';

/// Session Repository Hive Implementation - Persisting routine state to disk.
/// // Fulfills INT-03, INT-05, INT-06, INT-11 (Persistence), Standard 5.1, Standard 5.2
class SessionRepositoryImpl implements SessionRepository {
  final Box<ActiveSessionModel> _box;
  static const _sessionKey = 'active_session';

  SessionRepositoryImpl(this._box);

  @override
  Future<Result<void, DomainError>> saveSession(ActiveSession session) async {
    try {
      final model = ActiveSessionModel.fromEntity(session);
      await _box.put(_sessionKey, model);
      return const Result.success(null);
    } catch (e) {
      return const Result.failure(DomainError.storageFailure);
    }
  }

  @override
  Future<Result<ActiveSession, DomainError>> loadSession() async {
    try {
      final model = _box.get(_sessionKey);
      return Result.success(model?.toEntity() ?? const ActiveSession());
    } catch (e) {
      return const Result.failure(DomainError.storageFailure);
    }
  }

  @override
  Future<Result<void, DomainError>> clearSession() async {
    try {
      await _box.delete(_sessionKey);
      return const Result.success(null);
    } catch (e) {
      return const Result.failure(DomainError.storageFailure);
    }
  }
}
