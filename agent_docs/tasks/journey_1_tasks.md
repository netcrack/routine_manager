# Tasks for Journey 1: Managing Routines (Create, List, Update)

**Fulfills:** `INT-01`, `INT-02`, `INT-04`, `INT-10`
**Reference:** `agent_docs/user_journeys.md`, `agent_docs/intents.md`, `agent_docs/core_standards.md`

This document breaks down Journey 1 into actionable development tasks following the Feature-First Clean Architecture standards.

---

## Phase 0: Foundation (Core Standards)

**Goal:** Establish the Result pattern and domain errors for deterministic use case outcomes.

- [x] **Task 0.1: Define `DomainError` Enum**
  - **Path:** `lib/core/domain_error.dart`
  - **Description:** Implement `validationFailed`, `storageFailure`, `notFound`, etc.

- [x] **Task 0.2: Implement `Result` Pattern Class**
  - **Path:** `lib/core/result.dart`
  - **Description:** A generic `Result<S, F>` wrapper for standardizing success and failure returns.

---

## Phase 1: Domain Layer (Core Logic & Interfaces)

**Goal:** Establish pure Dart entities, repository interfaces, and use cases. No Flutter UI or Hive dependencies.

- [x] **Task 1.1: Define `Alarm` Entity**
  - **Path:** `lib/features/routine_manager/domain/entities/alarm.dart`
  - **Description:** Create the pure Dart entity with properties: `id` (String, UUID), `durationSeconds` (int, >0 validation), `orderIndex` (int). 
  - **Intent:** `// Fulfills INT-02, INT-04`
  - **Verification:** Unit tests confirming >0 duration validation.

- [x] **Task 1.2: Define `Routine` Entity**
  - **Path:** `lib/features/routine_manager/domain/entities/routine.dart`
  - **Description:** Create the entity with properties: `id` (String), `name` (String), `alarms` (List<Alarm>, at least 1), `createdAt` (DateTime), `updatedAt` (DateTime).
  - **Intent:** `// Fulfills INT-01, INT-04, INT-10`
  - **Verification:** Unit tests for name validation and `alarms.isNotEmpty` constraint.

- [x] **Task 1.3: Define `RoutineRepository` Interface**
  - **Path:** `lib/features/routine_manager/domain/repositories/routine_repository.dart`
  - **Description:** Define abstract methods: `saveRoutine`, `getRoutine`, `getAllRoutines`, `deleteRoutine` using `Future<Result<T, DomainError>>`.
  - **Intent:** `// Fulfills INT-01, INT-10`

- [x] **Task 1.4: Implement Domain Use Cases**
  - **Paths:** `lib/features/routine_manager/domain/usecases/...`
  - **Description:** 
    - `SaveRoutineUseCase`: Enforces `alarms.isNotEmpty` and returns `Result.failure(DomainError.validationFailed)` if invalid.
    - `GetRoutinesUseCase`: Returns `Result.success(List<Routine>)` or `Result.failure` on storage errors.
  - **Verification:** 100% test coverage verifying both `success` and `failure` Result paths.

---

## Phase 2: Data Layer (Local Persistence)

**Goal:** Implement Hive models, type adapters, and the concrete repository.

- [x] **Task 2.1: Create Hive Models**
  - **Paths:** `lib/features/routine_manager/data/models/alarm_model.dart`, `lib/features/routine_manager/data/models/routine_model.dart`
  - **Description:** Implement Hive objects matching the domain entities. Generate TypeAdapters. Add `toEntity()` and `fromEntity()` mapping functions.

- [x] **Task 2.2: Implement `RoutineRepositoryImpl`**
  - **Path:** `lib/features/routine_manager/data/repositories/routine_repository_impl.dart`
  - **Description:** Implement the `RoutineRepository` using Hive. Wrap operations in try-catch to map Hive/IO errors to `DomainError.storageFailure`.
  - **Verification:** Mock Hive to verify error mapping and data conversion.

---

## Phase 3: Presentation Layer (State Management & UI)

**Goal:** Build Riverpod providers and the Flutter UI ensuring no direct data layer access.

- [x] **Task 3.1: Implement Riverpod Controllers/Providers**
  - **Paths:** `lib/features/routine_manager/presentation/controllers/...`
  - **Description:**
    - `routine_list_provider`: Folds `Result` into `AsyncValue` to handle loading/error states.
    - `routine_builder_controller`: Returns `Result` from `save()` to let UI handle errors.

- [x] **Task 3.2: Build Routine List Screen (Home)**
  - **Path:** `lib/features/routine_manager/presentation/screens/routine_list_screen.dart`
  - **Description:** 
    - Display an empty state if no routines exist.
    - Display list view of saved routines.
    - Floating Action Button (FAB) to trigger navigation to Builder Screen for creation.
    - Enable tapping a routine card to navigate to the Builder Screen for editing.
  - **Intent:** `// Fulfills INT-01, INT-10`

- [x] **Task 3.3: Build Routine Builder Screen**
  - **Path:** `lib/features/routine_manager/presentation/screens/routine_builder_screen.dart`
  - **Description:**
    - Initialize UI with existing routine data (name, alarms, durations) if editing.
    - Unique Routine Name text field.
    - Add/Edit Alarm component with duration picker (minutes/seconds).
    - ReorderableListView for dragging and dropping alarms to update `orderIndex`.
    - "Save" button to trigger repository persistence and navigate back.
  - **Intent:** `// Fulfills INT-01, INT-02, INT-04, INT-10`

- [x] **Task 3.4: Implement Unhappy Paths UI State**
  - **Path:** Handled in the Builder Screen / Controllers.
  - **Description:**
    - **Empty Routine Prevention:** Handle `DomainError.validationFailed` in UI (disable save or show error highlight).
    - **Storage Failure Response:** Display a **standard notification** ("Failed to save routine") if the UseCase returns `DomainError.storageFailure`.
