import '../../../../core/domain_error.dart';
import '../../../../core/result.dart';
import '../entities/active_session.dart';

/// Repository interface for persisting and retrieving the single active routine session.
/// // Fulfills Core Standards Section 6.3, INT-09, Standard 5.1
abstract class SessionRepository {
  /// Load the current active session from persistence.
  /// Returns a default inactive session if none exists.
  Future<Result<ActiveSession, DomainError>> loadSession();

  /// Persist the active session state.
  Future<Result<void, DomainError>> saveSession(ActiveSession session);

  /// Clear the active session and release the singleton lock.
  Future<Result<void, DomainError>> clearSession();
}
