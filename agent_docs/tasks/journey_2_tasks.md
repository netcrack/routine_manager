# Tasks for Journey 2: Executing a Routine (Start, Pause, Ring, Complete)

**Fulfills:** `INT-03`, `INT-05`, `INT-06`, `INT-07`, `INT-08`, `INT-09`, `INT-11`
**Reference:** `agent_docs/user_journeys.md`, `agent_docs/intents.md`, `agent_docs/core_standards.md`

This document breaks down Journey 2 into actionable development tasks following the Feature-First Clean Architecture standards.

---

## Phase 1: Domain Layer (Core Logic, State Machine & Interfaces)

**Goal:** Establish the isolated core rules for running a single active session and abstracting native hardware triggers.

- [x] **Task 2.1: Define Session State Enums & `ActiveSession` Entity**
  - **Path:** `lib/features/routine_manager/domain/entities/active_session.dart`
  - **Description:** 
    - Create `enum SessionStatus { inactive, running, paused, ringing, completed }`.
    - Create `ActiveSession` entity with properties: `routineId` (String), `activeAlarmIndex` (int), `elapsedSeconds` (int), `status` (SessionStatus).
  - **Intent:** `// Fulfills INT-03, INT-06, INT-11`
  - **Verification:** Pure Dart unit tests verifying proper object state updates. Every test file must start with a comment documenting which Intent (`// Verifies INT-XX`) it is testing (Standard 8.4).

- [x] **Task 2.2: Define Native Notification Interface**
  - **Paths:** 
    - `lib/features/routine_manager/domain/services/notification_service.dart`
  - **Description:** Define abstract interface for pushing notification events (`INT-07`) and continuous ringing logic (`INT-08`) using system-level flags. Also include permission check definitions.

- [x] **Task 2.3: Implement Session Use Cases**
  - **Paths:** `lib/features/routine_manager/domain/usecases/...`
  - **Description:** Implement pure Dart logic rules avoiding `dart:async`'s `Timer` dependency inside UseCases.
    - **Result Pattern:** All UseCase signatures must return a `Result` type (Standard 5.1) to avoid throwing raw exceptions.
    - **Atomicity:** Follow the sequence: `Read (persistence) -> Validate (invariants) -> Apply (transition) -> Persist (result)` (Standard 4.2).
    - `StartSessionUseCase`: Asserts no other session is active (enforces `INT-09`), ensures required permissions are granted (or fails), and starts Alarm 0.
    - `PauseSessionUseCase` / `ResumeSessionUseCase`: Toggles active timer states (`INT-06`).
    - `StopSessionUseCase`: Permanently halts execution, resets session, clears remaining alarms (`INT-05`).
    - `NextAlarmUseCase`: Handles transitioning from `ringing` state on Alarm $N$ to `running` on Alarm $N+1$, or transitions to `completed` if last alarm (`INT-03`, `INT-11`).
  - **Verification:** Comprehensive state machine transition testing. 100% test coverage matching rules in Section 8.1 of core standards. Every test file must start with a comment documenting which Intent (`// Verifies INT-XX`) it is testing (Standard 8.4).

---

## Phase 2: Data/Infrastructure Layer (Device Native APIs)

**Goal:** Provide the actual concrete bridges to the device's audio, notifications, and background processing context.

- [x] **Task 2.4: Implement Notification Service**
  - **Path:** `lib/core/services/local_notification_service_impl.dart` (or similarly named in infrastructure).
  - **Description:** 
    - Implement the exact alarm scheduling for background persistence.
    - Implement ONE-TIME notification firing (`INT-07`).
    - Define permission request workflows for Notifications/Exact Alarms.

- [x] **Task 2.5: Consolidated Alerting Service**
  - **Description:** Verified that `NotificationService` handles both standard alerts and persistent "ringing" audio via native OS flags (`FLAG_INSISTENT` on Android, `critical` on iOS). No separate Audio Service required.

---

## Phase 3: Presentation Layer (State Management & UI)

**Goal:** Build Riverpod providers to maintain `ActiveSession` state and display the countdown timer UI.

- [x] **Task 2.6: Active Session State Controller (Riverpod)**
  - **Path:** `lib/features/routine_manager/presentation/controllers/active_session_controller.dart`
  - **Description:**
    - Central state holder for `ActiveSession`. Only 1 global provider to enforce the `INT-09` singleton rule.
    - Wire up internal ticking mechanisms (using Flutter/Riverpod safe context, handling AppLifecycleState for background/foreground sync).
  - **Verification:** Standard 8.3 & 8.4. ProviderContainer tests must verify transitions with Intent documentation in comments.

- [x] **Task 2.7: Update Routine List Screen to Start Sessions**
  - **Path:** `lib/features/routine_manager/presentation/screens/routine_list_screen.dart`
  - **Description:**
    - Connect "Start/Play" button on routine tiles to `StartSessionUseCase`.
    - Handle Unhappy Path: Display persistent banner/dialog if missing Permissions (Notification/Audio) and abort start (`INT-09` lock unchanged).
    - Block or disable Start buttons for other routines if a session is actively running or paused elsewhere.
    - Disable the "Delete" button for the active routine to prevent accidental session termination/corruption.
    - Ensure inactive routines' "Delete" buttons remain enabled regardless of whether another routine is active.

- [x] **Task 2.8: Build Active Session Screen (Running & Paused State)**
  - **Path:** `lib/features/routine_manager/presentation/screens/active_session_screen.dart`
  - **Description:** 
    - Primary display of active countdown (`elapsedSeconds`).
    - Include large "Pause/Resume" actionable controls (`INT-06`).
    - Global "Stop" button with confirmation dialog indicating loss of session (`INT-05`).

- [x] **Task 2.9: Build Ringing & Completed State UI**
  - **Path:** In `active_session_screen.dart` or as independent overlay dialogues/widgets depending on app route structure.
  - **Description:**
    - **Ringing:** Pulsing UI animation, flashing colors indicating due state.
    - **Dynamic Button:** The stop/next action button must dynamically update its label based on whether the current alarm is the final entry in the routine sequence:
        - If `session.activeAlarmIndex < routine.alarms.length - 1`: Label "**Next Alarm**" (calls `nextAlarm()`).
        - If `session.activeAlarmIndex == routine.alarms.length - 1`: Label "**Finish Routine**". On tap: Call `nextAlarm()`, show a **Success Notification** ("Routine 'X' finished!"), and navigate home immediately.
  - **Verification:** Manual UI audit against User Journey 2.3 and 2.6 outcome criteria.

---

## Phase 4: Background & State Recovery Refactor

**Goal:** Ensure the routine persists across app termination and backgrounding by transitioning to system-scheduled triggers and time-based state recovery.

- [x] **Task 2.10: Refactor `ActiveSession` Entity for Time-Based Sync**
  - **Path:** `lib/features/routine_manager/domain/entities/active_session.dart`
  - **Description:** 
    - Add `startTime` (DateTime?) to the entity.
    - Update `copyWith` and factory methods.
  - **Intent:** `// Fulfills INT-07, Core Standard 4.3`

- [x] **Task 2.11: Update UseCases for Proactive Notification Scheduling**
  - **Paths:** `lib/features/routine_manager/domain/usecases/{start_session,next_alarm}.dart`
  - **Description:** 
    - Modify use cases to calculate the target end-time and call `notificationService.scheduleNotification()` immediately upon alarm start.
    - Ensure `startTime` is set to `DateTime.now()` (or the resume time).

- [ ] **Task 2.13: Implement Notification-Triggered Navigation (Stream + Router)**
  - **Path:** `lib/core/services/local_notification_service_impl.dart`, `lib/main.dart`
  - **Description:** 
    - Update `NotificationService` to expose a `Stream<String?> onNotificationClick`.
    - Implement the stream in `LocalNotificationServiceImpl` and update `init()` to pipe native notification responses.
    - Create `notification_click_provider.dart` to expose the stream via Riverpod.
    - Update `MyApp` (`main.dart`) to listen to the provider and call `router.push('/session')` when an event is received.
    - Handle `getNotificationAppLaunchDetails()` for cold start navigation.
  - **Intent:** `// Fulfills INT-12`
  - **Verification:** Standard 8.3 & 8.4 verification. Manual check for background-to-foreground and killed-to-foreground navigation.

