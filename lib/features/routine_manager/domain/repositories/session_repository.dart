import '../entities/active_session.dart';

/// Repository interface for persisting and retrieving the single active routine session.
/// // Fulfills Core Standards Section 6.3, INT-09
abstract class SessionRepository {
  /// Load the current active session from persistence.
  /// Returns a default inactive session if none exists.
  Future<ActiveSession> loadSession();

  /// Persist the active session state.
  Future<void> saveSession(ActiveSession session);

  /// Clear the active session and release the singleton lock.
  Future<void> clearSession();
}
