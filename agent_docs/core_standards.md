# Core Architecture & Data Standards
**Project:** Routine Manager
**Methodology:** Intent-Driven Development (IDD) + Feature-First Clean Architecture

---

## 1. Tech Stack
The AI must strictly adhere to the following stack for all implementations:
- **Framework:** Flutter (latest stable)
- **State Management & DI:** `riverpod` (using Code Generation `@riverpod`)
- **Local Storage:** `hive` (TypeAdapters for persisting entities)
- **Routing:** `go_router`
- **UI Styling:** Material 3 with predefined Theme variables (no hardcoded colors/sizes).

---

## 2. Directory Structure (Feature-First)
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

---

## 3. Strict Architecture Constraints
The AI MUST follow these rules without exception:
1. **Domain Isolation:** Files inside `domain/` must **NEVER** import Flutter UI packages (`package:flutter/material.dart`) or Database packages (`hive`). They contain only pure Dart logic.
2. **State Segregation:** Flutter Widgets must **NEVER** communicate with a Repository, Data Source, or Use Case directly. Widgets only read/watch `Riverpod` controllers.
3. **Database Segregation:** Data Models (`Hive` objects) must be converted into pure Domain `Entities` before passing them to the UI or Use Cases.
4. **Intent Compliance:** Every newly created file (UseCase, Provider, or Screen) must mention the specific Intent ID (e.g., `// Fulfills INT-01`) it is resolving in a comment block at the top.

---

## 4. Source of Truth: Domain Models
The AI must use these exact schemas when building the local database and entities, derived directly from `intents.md`.

### 4.1. Entity: `Routine`
Satisfies: `INT-01`, `INT-04`, `INT-10`
*   `id`: `String` (UUID)
*   `name`: `String` (Must be unique across all routines)
*   `alarms`: `List<Alarm>` (Must contain at least 1)
*   `createdAt`: `DateTime`
*   `updatedAt`: `DateTime`

### 4.2. Entity: `Alarm`
Satisfies: `INT-02`, `INT-04`
*   `id`: `String` (UUID)
*   `durationSeconds`: `int` (Must be > 0)
*   `orderIndex`: `int` (For sequence preservation)

### 4.3. Entity: `ActiveSession` (In-Memory State)
Satisfies: `INT-03`, `INT-05`, `INT-06`, `INT-08`, `INT-09`, `INT-11`
*   `routineId`: `String` (The ID of the currently active routine)
*   `activeAlarmIndex`: `int` (Points to the currently active alarm within the routine)
*   `elapsedSeconds`: `int` (Time elapsed for the current alarm)
*   `status`: `enum SessionStatus { inactive, running, paused, ringing, completed }`

**Strict State Transitions:**
* `inactive` -> `running` (Start routine)
* `running` -> `paused` (User pauses), `ringing` (Timer reaches duration), `inactive` (User stops)
* `paused` -> `running` (User resumes), `inactive` (User stops)
* `ringing` -> `running` (User moves to next alarm), `completed` (Last alarm finished), `inactive` (User stops routine)
* `completed` -> `inactive` (User dismisses success state)

### 4.4. Domain Service: `NotificationService` / `AudioService`
Satisfies: `INT-07`
*   Must be defined as abstract interfaces in the `domain/` layer.
*   Implementation must reside in the `data/` or `core/` layer to keep the domain pure, allowing UI-agnostic execution of audio/visual ringing alerts (`INT-08`) and system-level notifications (`INT-07`).

---

## 5. Testing Strategy
To ensure deterministic and verifiable AI code generation without ambiguity:
1.  **Domain Layer (UseCases & Entities):** Must have 100% test coverage using standard pure Dart `test`. The AI must generate these before Data/Presentation.
2.  **Data Layer (Repositories):** Mock `Hive` or use an in-memory database to verify data mapping between Hive models and Domain Entities.
3.  **Presentation Layer (Riverpod):** Write `ProviderContainer` tests to verify the `ActiveSession` state machine transitions accurately without requiring a Flutter environment.
4.  **Intent Verification Check:** Every test file must start with a comment documenting which Intent (`// Verifies INT-XX`) it is testing.

---

## 6. Background Execution & Permissions
To ensure timer precision (`INT-02`) and reliable notifications (`INT-07`) when the app is backgrounded or killed:
1.  **Strict Background Rule:** Do **not** rely on standard Dart `Timer.periodic`. Implement background isolate processing or delegate scheduled alarms to system APIs (using `flutter_local_notifications` scheduling, `workmanager`, or Android `AlarmManager` / iOS `UNUserNotificationCenter`).
2.  **Permissions Required:** The app must explicitly request and verify `Notification`, `Exact Alarms` (Android 12+), and `Background Audio` routing. If denied, the UI must block routine execution and prompt the user.
