# Core Architecture & Data Standards
**Project:** Routine Manager
**Methodology:** Intent-Driven Development (IDD) + Feature-First Clean Architecture

---

## 0. Meta-Rules: Core Standards Creation & Maintenance
These rules serve as the definitive guardrail for creating and evolving any `core_standards.md` file. They ensure that architectural integrity and intent-driven logic are preserved across all project iterations.

1. **Architecture as Law**: This document MUST be the definitive source of truth for all architectural and data integrity standards.
2. **Intent-Driven Blueprint**: Every rule or model defined here MUST map back to a specific high-level system intent.
3. **Perfect Layer Isolation**: Standards MUST strictly enforce the separation of Domain, Data, and Presentation layers. No leaky abstractions (e.g., UI code in domain).
4. **Finite State Integrity**: Every system state and transition MUST be explicitly defined to prevent race conditions or ambiguous behaviors.
5. **Robustness & Lifecycle**: Standards MUST explicitly handle system-level challenges like background persistence, state recovery, and notification of time-sensitive events.
6. **Deterministic Verification**: Standards MUST mandate 100% domain-layer test coverage, with every test file mapping back to the intents they verify.
7. **Baseline Stability**: Section 0 MUST be preserved across all project iterations to maintain the integrity of the meta-standards.

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
Satisfies: `INT-01`, `INT-04`, `INT-10`
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
*   `startTime`: `DateTime?` (Timestamp when the current alarm started or was resumed)
*   `status`: `enum SessionStatus { inactive, running, paused, ringing }`

**Strict State Transitions:**
* `inactive` -> `running` (Start routine)
* `running` -> `paused` (User pauses), `ringing` (Timer reaches duration), `inactive` (User stops)
* `paused` -> `running` (User resumes), `inactive` (User stops)
* `ringing` -> `running` (User moves to next alarm), `inactive` (Last alarm finished or user stops routine)

### 2.4. Domain Service: `NotificationService`
Satisfies: `INT-07`, `INT-08`
*   Must be defined as an abstract interface in `domain/`.
*   **Ringing Requirement (`INT-08`):** Must leverage native notification flags (e.g., `FLAG_INSISTENT` on Android, `critical` sound on iOS) to ensure audio alerts loop continuously until stopped by the user.
*   **Visual Alerting:** The presentation layer must react to the `ringing` state with distinct UI patterns (e.g., pulsing animations) while the service provides the audio trigger.

### 2.5. Source of Truth Rule
- `startTime + duration` defines the absolute source of truth for progress.
- Timers are NOT the source of truth; they are UI heartbeat mechanisms.

---

## 3. System Execution & Runtime Flows

### 3.1. Routine Start Flow
1. UI triggers `StartSessionUseCase`
2. **Validate Invariants:**
   - **Single Active Session (INT-09):** Ensure no session is currently active.
   - **Permissions:** Verify required notification/alarm permissions are granted.
3. Create & Persist `ActiveSession` state.
4. Schedule system notification & AlarmManager event.
5. Emit updated state to controller -> UI reacts.

### 3.2. Alarm Completion Flow
1. Time threshold reached (system trigger or recovery logic).
2. Transition state to `ringing`.
3. `NotificationService` triggers persistent alert.
4. User stops alarm -> `NextAlarmUseCase`:
   - Move to next alarm OR
   - Transition to `completed`.

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

### 6.2. State Recovery Rule
Upon app launch or resume, the `ActiveSessionController` must calculate the elapsed time using `startTime` and current time. If `now >= startTime + totalSeconds`, the session must transition immediately to the `ringing` state, even if no Dart timer was running.

### 6.3. Persistence Rule
`ActiveSession` state must be persisted to local storage (`hive`) to ensure the routine can be recovered after the app process is terminated or the device restarts.

### 6.4. Permissions Required
The app must explicitly request and verify `Notification`, `Exact Alarms` (Android 12+), and `Background Audio` routing. If denied, the UI must block routine execution and prompt the user.

---

## 7. Data Lifecycle: Evolution & Migration

### 7.1. Backward Compatibility Rules
- All persisted models must support backward compatibility.
- New fields must have safe defaults.
- Removal of fields requires explicit migration logic.

### 7.2. ActiveSession Persistence
- Must tolerate missing or additional fields (Forward/Backward compatibility).
- Recovery logic must not fail due to schema changes; it should revert to a safe `inactive` state if data is corrupted.

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
