# Tasks for Journey 3: Unhappy Paths & Edge Cases

**Reference:** `agent_docs/user_journeys.md`, `agent_docs/core_standards.md`

This document defines the tasks for handling error states, permission denials, and system failures as first-class citizens.

--- [x] Phase 1: Permission Guarding & Validation
- [x] **Task 3.1: Implement Permission Check Service**
  - **Path:** `lib/core/services/local_notification_service_impl.dart` (Implementation)
  - **Description:** Abstract `NotificationService` for checking permissions status (Standard 6.4).
- [x] **Task 3.2: Implement Permission Guard UseCase**
  - **Path:** `lib/features/routine_manager/domain/usecases/verify_permissions.dart`
  - **Description:** Checks `notificationService.checkPermissions()` and returns a `Result.failure(DomainError.permissionDenied)` if critical requirements are missing (Standard 3.1).
- [x] **Task 3.3: UI Permission Barrier**
  - **Path:** `lib/features/routine_manager/presentation/screens/routine_list_screen.dart`
  - **Description:** Trigger `verifyPermissionsProvider` before starting any session. Displays an `AlertDialog` if permissions are denied (Standard 1.5.1).

--- [x] Phase 2: Persistence & Storage Failures
- [x] **Task 3.4: Wrap Storage Calls in Result pattern**
  - **Path:** `lib/features/routine_manager/data/repositories/session_repository_impl.dart`
  - **Description:** All repository methods now return `Result<T, DomainError>` and catch `Hive` exceptions to map them to `DomainError.storageFailure` (Standard 5.1).
- [x] **Task 3.5: STORAGE Error Feedback**
  - **Path:** `lib/features/routine_manager/presentation/screens/routine_builder_screen.dart`
  - **Description:** Listen for `storageFailure` results from the save action and display a glassmorphic error snackbar (Standard 3.2.3).

--- [x] Phase 3: Logical Constraints & Invariants
- [x] **Task 3.6: Empty Routine Validation**
  - **Path:** `lib/features/routine_manager/domain/usecases/save_routine.dart`
  - **Description:** Rigidly enforce `alarms.isNotEmpty` in `SaveRoutineUseCase` and `StartSessionUseCase` (INT-01).
- [x] **Task 3.7: Builder Validation Feedback**
  - **Path:** `lib/features/routine_manager/presentation/screens/routine_builder_screen.dart`
  - **Description:** Disable the "Save" button if the routine name is empty or alarms list is empty. Shows `invalidRoutine` error snackbar on attempted save of empty routine (Standard 3.3.3).
- [x] **Task 3.8: Add Error Snackbars to Routine Builder**
  - **Path:** `lib/features/routine_manager/presentation/screens/routine_builder_screen.dart`
  - **Description:** Displays premium snackbars for `invalidRoutine` and `storageFailure` (Standard 3.2.3).
- [x] **Task 3.9: Logic to prevent deleting a running routine**
  - **Path:** `lib/features/routine_manager/presentation/controllers/routine_list_controller.dart`
  - **Description:** `deleteRoutine` checks `activeSessionControllerProvider` and returns `DomainError.activeSessionExists` if the routine is active. UI displays a snackbar warning.
- [x] **Task 3.10: Update existing tests**
  - **Path:** `test/features/routine_manager/domain/usecases/session_state_machine_test.dart`
  - **Description:** Added unit tests verifying non-empty routine invariants and `activeSessionExists` guards.

--- [x] Phase 4: Multi-Step Transition Reliability
- [x] **Task 3.11: Atomic History Persistence (NextAlarm)**
  - **Path:** `lib/features/routine_manager/domain/usecases/next_alarm.dart`
  - **Description:** `NextAlarmUseCase` handles session completion by creating a `RoutineRun` entity and persisting it via `HistoryRepository` (INT-15).
- [x] **Task 3.12: Graceful History Degradation**
  - **Path:** `lib/features/routine_manager/domain/usecases/next_alarm.dart`
  - **Description:** If `HistoryRepository.saveRun` fails, the session completion still proceeds to clear the active session, logging but not blocking current state progression (Standard 3.2.1).
- [x] **Task 3.13: Final Session Cleanup Verification**
  - **Description:** Verified via unit tests that the session is always transitioned to `inactive` regardless of history outcome.
