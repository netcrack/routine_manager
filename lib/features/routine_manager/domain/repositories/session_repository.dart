import '../entities/active_session.dart';

/// Session Repository - Interface for persisting the active routine session state.
/// // Fulfills INT-03, INT-05, INT-06, INT-11 (Persistence)
abstract class SessionRepository {
  /// Save the current session state.
  Future<void> saveSession(ActiveSession session);

  /// Load the persisted session state.
  Future<ActiveSession?> loadSession();

  /// Clear the persisted session.
  Future<void> clearSession();
}
