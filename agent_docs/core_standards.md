# Core Architecture & Data Standards
**Project:** Routine Manager
**Methodology:** Intent-Driven Development (IDD) + Feature-First Clean Architecture

---

## 0. Meta-Rules: Core Standards Definition & Evolution
These rules serve as the project-agnostic guardrail for defining and evolving technical standards. They ensure that all architectural decisions are atomic, verifiable, and structurally sound for downstream development.

### 0.1. Rules for Documentation
1. **Architecture as Law**: This document is the definitive technical contract for the project. No implementation may deviate from these rules without an explicit update to the standards.
2. **Intent-Driven Blueprint**: Every technical standard MUST be a response to a specific Business Intent (found in `intents.md`). Engineering exists only to fulfill documented intents.
3. **Technical Invariants over Temporal Flows**: Standards MUST define "Laws" (invariants, schemas, and constraints), never "Steps" (temporal flows). Sequence logic belongs in `user_journeys.md`.
4. **Deterministic Verification**: Standards MUST require 100% test coverage of the Domain layer, with all tests mapping back to the intents they prove.
5. **Platform Idiomaticity & Excellence**: Standards MUST use the "Premium Gold Standard" of the ecosystem (e.g., Riverpod for Flutter). Never accept generic or "stock" implementation patterns.
6. **Finite State Determinism**: Every system state, transition, and edge case MUST be explicitly defined. Ambiguity in state transitions is an architectural failure.
7. **Robustness & Lifecycle Integrity**: Standards MUST explicitly mandate the handling of platform-specific challenges: background persistence, process death recovery, and asynchronous synchronization.
8. **Explicit AI Acknowledgement**: The AI MUST explicitly acknowledge that it has read and understands these Meta-Rules before being permitted to edit this document.

### 0.2. Document Structure
To maintain consistency, any `core_standards.md` MUST follow this hierarchical structure:
1. **Foundation**: Tech Stack, Feature-First Directory Structure, and Layer Responsibilities.
2. **Domain Models**: Immutable Schemas (Entities) and Source of Truth rules.
3. **System Execution**: Technical Contracts and Architectural Invariants (Atomic Rules).
4. **Concurrency & Invariants**: Rules for state transitions, atomicity, and conflict resolution.
5. **Standardized Error Handling**: Result-pattern definitions and business-logic failure mapping.
6. **Reliability & Recovery**: Background lifecycle rules, process death recovery, and persistence strategies.
7. **Data Lifecycle**: Versioning, migration logic, and retention policies.
8. **Verification Strategy**: Layer-specific test requirements and Intent-mapping for tests.
9. **Design & UX System**: Typography, color tokens, and premium interaction patterns.

### 0.3. Evolutionary Integrity
Rules 0.1 and 0.2 are immutable across project iterations. They govern how the subsequent sections are re-generated if the project's technology stack or specific goals evolve.

---

## 1. Foundation: Tech Stack, Structure & Architecture
The AI must strictly adhere to the following stack and organizational rules for all implementations:

### 1.1. Tech Stack
- **Framework:** Flutter (latest stable)
- **State Management & DI:** `riverpod` (using Code Generation `@riverpod`)
- **Local Storage:** `hive` (TypeAdapters for persisting entities)
- **Routing:** `go_router`
- **UI Styling:** Material 3 with predefined Theme variables (no hardcoded colors/sizes).

### 1.2. Directory Structure (Feature-First)
All code must be self-contained within a feature directory. No global `/models` or `/views` directory is allowed.

```text
lib/
├── core/                       # Shared utilities, router, global themes
└── features/
    └── routine_manager/        # The singular feature for this app
        ├── domain/             # Entities, Repositories (Interfaces), UseCases
        ├── data/               # Hive Models, Data Sources, Repositories (Implementation)
        └── presentation/       # Riverpod Controllers, Flutter Screens, Widgets
```

### 1.3. State Ownership & Layer Responsibility
Compliance with these roles ensures architectural integrity across the Feature-First structure.

| Layer        | Responsibility                                |
| ------------ | --------------------------------------------- |
| **Domain**   | Business rules, validation, state transitions |
| **Data**     | Persistence and system integrations           |
| **Presentation** | State observation and UI rendering        |

### 1.4. Strict Architecture Constraints
- **Domain Isolation:** Files inside `domain/` must **NEVER** import Flutter UI packages (`package:flutter/material.dart`) or Database packages (`hive`). They contain only pure Dart logic.
- **State Segregation:** Flutter Widgets must **NEVER** communicate with a Repository, Data Source, or Use Case directly. Widgets only read/watch `Riverpod` controllers.
- **Database Segregation:** Data Models (`Hive` objects) must be converted into pure Domain `Entities` before passing them to the UI or Use Cases.
- **Intent Compliance:** Every newly created file (UseCase, Provider, or Screen) must mention the specific Intent ID (e.g., `// Fulfills INT-01`) it is resolving in a comment block at the top.

---

## 2. Domain Models: Truth & Integrity
The AI must use these exact schemas derived directly from `intents.md`.

### 2.1. Entity: `Routine`
Satisfies: `INT-01`, `INT-04`, `INT-10`, `INT-14`
*   `id`: `String` (UUID)
*   `name`: `String` (Must be unique across all routines)
*   `alarms`: `List<Alarm>` (Must contain at least 1)
*   `createdAt`: `DateTime`
*   `updatedAt`: `DateTime`

### 2.2. Entity: `Alarm`
Satisfies: `INT-02`, `INT-04`
*   `id`: `String` (UUID)
*   `durationSeconds`: `int` (Must be > 0)
*   `orderIndex`: `int` (For sequence preservation)

### 2.3. Entity: `ActiveSession` (In-Memory State)
Satisfies: `INT-03`, `INT-05`, `INT-06`, `INT-08`, `INT-09`, `INT-11`
*   `routineId`: `String` (The ID of the currently active routine)
*   `activeAlarmIndex`: `int` (Points to the currently active alarm within the routine)
*   `elapsedSeconds`: `int` (Time elapsed for the current alarm)
*   `sessionStartTime`: `DateTime?` (Timestamp when the entire routine session was first initiated. Used for history recording (INT-15).)
*   `anchorTime`: `DateTime?` (Timestamp when the current alarm started or was resumed. Used as the drift-free calculation anchor (INT-02).)
*   `status`: `enum SessionStatus { inactive, running, paused, ringing }`

**Strict State Transitions:**
* `inactive` -> `running` (Start routine)
* `running` -> `paused` (User pauses), `ringing` (Timer reaches duration), `inactive` (User stops)
* `paused` -> `running` (User resumes), `inactive` (User stops)
* `ringing` -> `running` (User moves to next alarm), `inactive` (Last alarm finished or user stops routine)

### 2.4. Entity: `RoutineRun`
Satisfies: `INT-15`, `INT-16`, `INT-17`
*   `id`: `String` (UUID)
*   `routineId`: `String` (Relationship to the original routine)
*   `routineName`: `String` (Snapshot of the name at execution time to handle deleted routines)
*   `startTime`: `DateTime`
*   `endTime`: `DateTime`
*   `status`: `enum RunStatus { completed, stopped }`

### 2.5. Domain Service: `NotificationService`
Satisfies: `INT-07`, `INT-08`
*   Must be defined as an abstract interface in `domain/`.
*   **Ringing Requirement (`INT-08`):** Must leverage native notification flags (e.g., `FLAG_INSISTENT` on Android, `critical` sound on iOS) to ensure audio alerts loop continuously until stopped by the user.
*   **Visual Alerting:** The presentation layer must react to the `ringing` state with distinct UI patterns (e.g., pulsing animations) while the service provides the audio trigger.

### 2.6. Source of Truth Rule
- `anchorTime + duration - elapsedSeconds` defines the absolute source of truth for the *current* alarm progress.
- Timers are NOT the source of truth; they are UI heartbeat mechanisms.

---

## 3. System Execution: Contracts & Invariants
These rules define the mandatory technical execution requirements. For the exact temporal sequence (step-by-step) of user and system interactions, refer to the [User Journeys](file:///Users/ashokm/development/flutter_test/routine_manager/agent_docs/user_journeys.md).

### 3.1. Execution Invariants (Atomic Rules)
- **Global Session Lock (INT-09):** The domain layer MUST enforce a singular active session by checking for an existing persisted `ActiveSession` before any new routine execution is allowed.
- **Permission Guard:** Routine execution MUST be blocked if critical permissions (Notifications, Alarm Manager) are not verified at the start of the session.
- **Intent Mapping:** Every UseCase and Controller MUST be mapped to a specific Intent ID in a top-level comment to ensure traceability.

### 3.2. Alarm Lifecycle Contracts
- **Trigger Integrity (INT-02, INT-07):** The transition to the `ringing` state MUST be driven by the system-level notification trigger. Internal timers are for UI heartbeat only and are NOT the source of truth for alarm completion.
- **Alert Persistence (INT-08):** Once the `ringing` state is activated, the alert MUST continue (audio loop and visual focus) until the user provides an explicit terminal input (Next Alarm or Finish Routine).

### 3.3. Session Finalization & Cleanup
- **Atomic Finalization (INT-11, INT-15):** The transition from the final alarm to the `inactive` state MUST be handled as a single atomic operation that:
    1. Finalizes the current alarm.
    2. Persists the `RoutineRun` metadata.
    3. Clears the `ActiveSession` persistence (releasing the lock).
    4. Triggers the data retention pruning (INT-18) logic.

---

## 4. Concurrency & Invariant Enforcement

### 4.1. Concurrency Rules
- All state transitions must be based on the latest **persisted** state.
- No blind overwrites are allowed; the domain layer must validate current state before applying transitions.

### 4.2. Atomicity Requirement
Each UseCase must follow this sequence:
1. **Read** current state from persistence.
2. **Validate** invariants.
3. **Apply** the specified transition.
4. **Persist** the final result.

---

## 5. Business Logic: Domain Error Handling

### 5.1. Rule
UseCases must NOT throw raw exceptions for business logic failures. They must return structured results using a Result pattern.

### 5.2. Standard Domain Errors
- `validationFailed`
- `permissionDenied`
- `activeSessionExists`
- `storageFailure`

### 5.3. Enforcement
- UI must react to failure states defined by the domain.
- Domain layer defines all business failure scenarios.

---

## 6. Reliability: Background, Recovery & Permissions
To ensure timer precision (`INT-02`) and reliable notifications (`INT-07`) when the app is backgrounded or killed:

### 6.1. Strict Background Rule
Do **not** rely on standard Dart `Timer.periodic` for the source of truth. Delegate scheduled alarms to system APIs (using `flutter_local_notifications` scheduling or native Alarm Managers) at the *start* of an alarm.
- **Payload Requirement (INT-12):** Scheduled notifications MUST include a data payload containing the `routineId` to enable deterministic navigation when the user interacts with the alert.

### 6.2. State Recovery Rule (Satisfies INT-13, INT-15)
Upon app launch or resume, the `ActiveSessionController` must calculate elapsed time:
1. If `now >= anchorTime + (duration - elapsedSeconds)`, the active alarm is overdue and should transition to `ringing`.
2. **Zombie Session (Reliability):** Or, if `now > sessionStartTime + 24_HOURS`, the session has effectively "died" or was interrupted by a crash/termination. 
3. **Outcome:** In the Zombie case, the system MUST transition the session directly to `Stopped`, persist a `RoutineRun` record with the `sessionStartTime` (INT-15), and release the `ActiveSession` lock (INT-09).

### 6.3. Persistence Rule
`ActiveSession` state must be persisted to local storage (`hive`) to ensure the routine can be recovered after the app process is terminated or the device restarts.

### 6.4. Permissions Required
The app must explicitly request and verify `Notification`, `Exact Alarms` (Android 12+), and `Background Audio` routing. If denied, the UI must block routine execution and prompt the user.

### 6.5. Notification Interaction (Satisfies INT-12)
- **Payload Capture:** The system must capture the notification payload at the App entry point.
- **Deterministic Navigation:** Tapping a session-related notification MUST trigger the router to navigate directly to the Active Session UI, even during a cold start or background-to-foreground transition.

---

## 7. Data Lifecycle: Evolution & Migration

### 7.1. Backward Compatibility Rules
- All persisted models must support backward compatibility.
- New fields must have safe defaults.
- Removal of fields requires explicit migration logic.

### 7.2. ActiveSession Persistence
- Must tolerate missing or additional fields (Forward/Backward compatibility).
- Recovery logic must not fail due to schema changes; it should revert to a safe `inactive` state if data is corrupted.

### 7.3. RoutineRun History Persistence
- Run history must be persisted in a dedicated Hive box separate from Routine definitions.
- The history list should be optimized for chronological retrieval (`INT-16`).
- **Detail Retrieval (INT-17):** The `RoutineRun` entity must capture sufficient snapshot data (start/end times, final status, and original routine name) to allow the user to view run details even if the source routine is later modified or deleted.

### 7.4. Data Retention Policy (Satisfies INT-18)
- To prevent storage overflow, the system MUST implement a "6-Month Sliding Window" for history.
- Any `RoutineRun` record with an `endTime` older than 180 days MUST be purged.
- **Cleanup Trigger:** Pruning MUST occur at the end of every new execution during the `Routine Finalization Flow`.

---

## 8. Verification: Testing Strategy
To ensure deterministic and verifiable AI code generation:

### 8.1. Domain Layer (UseCases & Entities)
Must have 100% test coverage using standard pure Dart `test`. The AI must generate these before Data/Presentation layers.

### 8.2. Data Layer (Repositories)
Mock `Hive` or use an in-memory database to verify data mapping between Hive models and Domain Entities.

### 8.3. Presentation Layer (Riverpod)
Write `ProviderContainer` tests to verify the `ActiveSession` state machine transitions accurately without requiring a Flutter environment.

### 8.4. Intent Verification Check
Every test file must start with a comment documenting which Intent (`// Verifies INT-XX`) it is testing.

---

## 9. Design & UX Standards: Premium Productivity
To ensure a consistent, high-end experience across all visual and interactive components.

### 9.1. Brand Identity & Typography
- **Typography:** The **Outfit** font family (via `google_fonts`) is the mandatory typeface for all UI elements.
- **Color Palette:**
    - **Primary:** Deep Teal (`#006064`) - Used for core branding and primary actions.
    - **Accent:** Vivid Purple (`#6A1B9A`) - Used for highlights and secondary interactions.
    - **Status Colors:** Use standard Material 3 semantic colors (Error, Success) but styled to match the premium palette.

### 9.2. Visual Language (Glassmorphism)
- **Containers:** Use `AppTheme.glassDecoration` (or equivalent) for cards and sheets.
    - **Borders:** Subtle, semi-translucent borders (width: 0.5 - 1.0).
    - **Shadows:** Soft, diffused shadows instead of hard elevations.
    - **Opacity:** Use `withValues(alpha: ...)` for translucent backgrounds to create depth.

### 9.3. Interaction & Haptics
- **Tactile Inputs:** All duration, time, or sequence pickers MUST use a wheel-style interface (`ListWheelScrollView`) rather than basic +/- buttons.
- **Haptic Feedback:** Interactive wheel pickers and primary session actions (Start/Stop) MUST trigger `HapticFeedback.selectionClick()` or equivalent to provide physical confirmation.
- **Motion:** State transitions (especially `ringing`) should incorporate subtle scale and opacity animations to feel "alive."

### 9.4. Component Hierarchy
- **Dialogs:** Prefer **Modal Bottom Sheets** for mobile pickers and quick actions to improve one-handed ergonomics.
- **Banners:** Active session indicators should be floating, rounded, and visually distinct from static content.
