# Tasks for Journey 4: Reviewing Routine Run History

**Fulfills:** `INT-15`, `INT-16`, `INT-17`, `INT-18`
**Reference:** `agent_docs/user_journeys.md`, `agent_docs/core_standards.md`

This document defines the tasks for implementing the routine execution history tracking and retrieval system.

---

## Phase 1: Domain Layer (Entities & UseCases)

**Goal:** Establish the core logic for recording and querying routine execution metadata.

- [x] **Task 4.1: Define `RoutineRun` Entity**
  - **Path:** `lib/features/routine_manager/domain/entities/routine_run.dart`
  - **Description:** Properties: `id` (String), `routineId` (String), `routineName` (String), `startTime` (DateTime), `endTime` (DateTime), `status` (RunStatus).
  - **Intent:** `// Fulfills INT-15`

- [x] **Task 4.2: Define `HistoryRepository` Interface**
  - **Path:** `lib/features/routine_manager/domain/repositories/history_repository.dart`
  - **Description:** Abstract methods: `saveRun`, `getHistory`, `getRunDetail`, `pruneHistory`.
  - **Intent:** `// Fulfills INT-16, INT-18`

- [x] **Task 4.3: Implement History Use Cases**
  - **Path:** `lib/features/routine_manager/domain/usecases/...`
  - **Description:** 
    - `GetRunHistoryUseCase`: Retrieves chronological history for the last 180 days (INT-16).
    - `GetRunDetailUseCase`: Retrieves detailed metadata for a specific execution (INT-17).
  - **Verification:** Unit tests verifying 180-day window and snapshots.

---

## Phase 2: Data Layer (History Persistence)

**Goal:** Implement separate Hive storage for history records and snapshot preservation.

- [x] **Task 4.4: Create `RoutineRunModel` (Hive)**
  - **Path:** `lib/features/routine_manager/data/models/routine_run_model.dart`
  - **Description:** Hive model with TypeAdapter and mapping logic for `RoutineRun`.
  - **Intent:** `// Fulfills INT-15`

- [x] **Task 4.5: Implement `HistoryRepositoryImpl`**
  - **Path:** `lib/features/routine_manager/data/repositories/history_repository_impl.dart`
  - **Description:** Implement storage in a dedicated Hive box (`routine_history`).
  - **Intent:** `// Fulfills INT-15, INT-16, INT-18`

---

## Phase 3: Presentation Layer (History UI)

**Goal:** Provide the user with a premium interface to review their past performance.

- [x] **Task 4.6: History List Controller (Riverpod)**
  - **Path:** `lib/features/routine_manager/presentation/controllers/history_controller.dart`
  - **Description:** State holder for chronologically sorted execution records.

- [x] **Task 4.7: Build History Screen**
  - **Path:** `lib/features/routine_manager/presentation/screens/history_screen.dart`
  - **Description:** 
    - **Typography:** Apply **Outfit** font family (Standard 9.1).
    - **Aesthetics:** Use **Glassmorphism** for cards with `AppTheme.glassDecoration` (Standard 9.2).
    - List chronological executions with status icons (INT-16).
    - Empty state if no records exist (Journey 4.1.2).

- [x] **Task 4.8: Build Run Detail View**
  - **Path:** `lib/features/routine_manager/presentation/screens/run_detail_screen.dart`
  - **Description:** 
    - Detailed summary of start, end, and duration (INT-17).
    - Link back to routine builder if original routine exists.
    - Stable display for deleted routines using name snapshot (Journey 4.2.3).
  - **Intent:** `// Fulfills INT-17`

---

## Phase 4: Fix Duration Calculation Accuracy

**Goal:** Separate session start time from countdown anchor to ensure historical duration is correct.

- [ ] **Task 4.9: Update `ActiveSession` Entity**
  - **Path:** `lib/features/routine_manager/domain/entities/active_session.dart`
  - **Description:** Add `sessionStartTime` and rename `startTime` to `anchorTime`.
  - **Intent:** `// Fulfills INT-15`

- [ ] **Task 4.10: Update `ActiveSessionModel` & Regenerate**
  - **Path:** `lib/features/routine_manager/data/models/active_session_model.dart`
  - **Description:** Map new fields to Hive fields. Run `build_runner`.
  - **Intent:** `// Fulfills INT-15`

- [ ] **Task 4.11: Update Use Cases for Atomic Transitions**
  - **Paths:** `lib/features/routine_manager/domain/usecases/...`
  - **Description:** 
    - `StartSessionUseCase`: Set both `sessionStartTime` and `anchorTime`.
    - `NextAlarmUseCase`: Update `anchorTime`, preserve `sessionStartTime`. Use `sessionStartTime` for history record.
    - `StopSessionUseCase`: Use `sessionStartTime` for history record.
    - `Pause/Resume/Heartbeat`: Use `anchorTime` for drift-free logic.
  - **Intent:** `// Fulfills INT-15`

- [ ] **Task 4.12: Verify Duration Fix**
  - **Description:** Unit tests for `NextAlarmUseCase` and `StopSessionUseCase` to verify `RoutineRun` duration across multiple alarms.
  - **Verification:** Manual verification in History Screen.
