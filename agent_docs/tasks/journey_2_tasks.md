# Tasks for Journey 2: Executing a Routine (Start, Pause, Ring, Complete)

**Fulfills:** `INT-03`, `INT-05`, `INT-06`, `INT-07`, `INT-08`, `INT-09`, `INT-11`
**Reference:** `agent_docs/user_journeys.md`, `agent_docs/intents.md`, `agent_docs/core_standards.md`

This document breaks down Journey 2 into actionable development tasks following the Feature-First Clean Architecture standards.

---

## Phase 1: Domain Layer (Core Logic, State Machine & Interfaces)

**Goal:** Establish the isolated core rules for running a single active session and abstracting native hardware triggers.

- [ ] **Task 2.1: Define Session State Enums & `ActiveSession` Entity**
  - **Path:** `lib/features/routine_manager/domain/entities/active_session.dart`
  - **Description:** 
    - Create `enum SessionStatus { inactive, running, paused, ringing, completed }`.
    - Create `ActiveSession` entity with properties: `routineId` (String), `activeAlarmIndex` (int), `elapsedSeconds` (int), `status` (SessionStatus).
  - **Intent:** `// Fulfills INT-03, INT-06, INT-11`
  - **Verification:** Pure Dart unit tests verifying proper object state updates.

- [ ] **Task 2.2: Define Hardware/Native Interfaces**
  - **Paths:** 
    - `lib/features/routine_manager/domain/services/notification_service.dart`
    - `lib/features/routine_manager/domain/services/audio_service.dart`
  - **Description:** Define abstract interfaces for pushing notification events (`INT-07`) and continuous ringing logic (`INT-08`). Also include permission check definitions.

- [ ] **Task 2.3: Implement Session Use Cases**
  - **Paths:** `lib/features/routine_manager/domain/usecases/...`
  - **Description:** Implement pure Dart logic rules avoiding `dart:async`'s `Timer` dependency inside UseCases.
    - `StartSessionUseCase`: Asserts no other session is active (enforces `INT-09`), ensures required permissions are granted (or fails), and starts Alarm 0.
    - `PauseSessionUseCase` / `ResumeSessionUseCase`: Toggles active timer states (`INT-06`).
    - `StopSessionUseCase`: Permanently halts execution, resets session, clears remaining alarms (`INT-05`).
    - `NextAlarmUseCase`: Handles transitioning from `ringing` state on Alarm $N$ to `running` on Alarm $N+1$, or transitions to `completed` if last alarm (`INT-03`, `INT-11`).
  - **Verification:** Comprehensive state machine transition testing. 100% test coverage matching rules in Section 4.3 of core standards.

---

## Phase 2: Data/Infrastructure Layer (Device Native APIs)

**Goal:** Provide the actual concrete bridges to the device's audio, notifications, and background processing context.

- [ ] **Task 2.4: Implement Notification Service**
  - **Path:** `lib/core/services/local_notification_service_impl.dart` (or similarly named in infrastructure).
  - **Description:** 
    - Implement the exact alarm scheduling for background persistence.
    - Implement ONE-TIME notification firing (`INT-07`).
    - Define permission request workflows for Notifications/Exact Alarms.

- [ ] **Task 2.5: Implement Audio/Ringing Service**
  - **Path:** `lib/core/services/audio_ringer_service_impl.dart`.
  - **Description:** 
    - Implement persistent audio looping when an alarm reaches 0 continuously alerting the user (`INT-08`).
    - Provide stop mechanism.

---

## Phase 3: Presentation Layer (State Management & UI)

**Goal:** Build Riverpod providers to maintain `ActiveSession` state and display the countdown timer UI.

- [ ] **Task 2.6: Active Session State Controller (Riverpod)**
  - **Path:** `lib/features/routine_manager/presentation/controllers/active_session_controller.dart`
  - **Description:**
    - Central state holder for `ActiveSession`. Only 1 global provider to enforce the `INT-09` singleton rule.
    - Wire up internal ticking mechanisms (using Flutter/Riverpod safe context, handling AppLifecycleState for background/foreground sync).

- [ ] **Task 2.7: Update Routine List Screen to Start Sessions**
  - **Path:** `lib/features/routine_manager/presentation/screens/routine_list_screen.dart`
  - **Description:**
    - Connect "Start/Play" button on routine tiles to `StartSessionUseCase`.
    - Handle Unhappy Path: Display persistent banner/dialog if missing Permissions (Notification/Audio) and abort start (`INT-09` lock unchanged).
    - Block or disable Start buttons for other routines if a session is actively running or paused elsewhere.

- [ ] **Task 2.8: Build Active Session Screen (Running & Paused State)**
  - **Path:** `lib/features/routine_manager/presentation/screens/active_session_screen.dart`
  - **Description:** 
    - Primary display of active countdown (`elapsedSeconds`).
    - Include large "Pause/Resume" actionable controls (`INT-06`).
    - Global "Stop" button with confirmation dialog indicating loss of session (`INT-05`).

- [ ] **Task 2.9: Build Ringing & Completed State UI**
  - **Path:** In `active_session_screen.dart` or as independent overlay dialogues/widgets depending on app route structure.
  - **Description:**
    - **Ringing:** Pulsing UI animation, flashing colors indicating due state. "Stop Alarm / Next" button stops continuous alarm and audio service (`INT-03`).
    - **Completed:** When `NextAlarmUseCase` returns `completed`, display an atomic success message locally and pop the navigation stack returning to Routine List Screen (`INT-11`).
