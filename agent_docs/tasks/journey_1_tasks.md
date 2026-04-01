# Tasks for Journey 1: Managing Routines (Create, List, Update)

**Fulfills:** `INT-01`, `INT-02`, `INT-04`, `INT-10`
**Reference:** `agent_docs/user_journeys.md`, `agent_docs/intents.md`, `agent_docs/core_standards.md`

This document breaks down Journey 1 into actionable development tasks following the Feature-First Clean Architecture standards.

---

## Phase 1: Domain Layer (Core Logic & Interfaces)

**Goal:** Establish pure Dart entities, repository interfaces, and use cases. No Flutter UI or Hive dependencies.

- [ ] **Task 1.1: Define `Alarm` Entity**
  - **Path:** `lib/features/routine_manager/domain/entities/alarm.dart`
  - **Description:** Create the pure Dart entity with properties: `id` (String, UUID), `durationSeconds` (int, >0 validation), `orderIndex` (int). 
  - **Intent:** `// Fulfills INT-02, INT-04`
  - **Verification:** Unit tests confirming >0 duration validation.

- [ ] **Task 1.2: Define `Routine` Entity**
  - **Path:** `lib/features/routine_manager/domain/entities/routine.dart`
  - **Description:** Create the entity with properties: `id` (String), `name` (String), `alarms` (List<Alarm>, at least 1), `createdAt` (DateTime), `updatedAt` (DateTime).
  - **Intent:** `// Fulfills INT-01, INT-04, INT-10`
  - **Verification:** Unit tests for name validation and `alarms.isNotEmpty` constraint.

- [ ] **Task 1.3: Define `RoutineRepository` Interface**
  - **Path:** `lib/features/routine_manager/domain/repositories/routine_repository.dart`
  - **Description:** Define abstract methods: `saveRoutine(Routine)`, `getRoutine(String)`, `getAllRoutines()`, `deleteRoutine(String)`.
  - **Intent:** `// Fulfills INT-01, INT-10`

- [ ] **Task 1.4: Implement Domain Use Cases**
  - **Paths:** `lib/features/routine_manager/domain/usecases/...`
  - **Description:** 
    - `SaveRoutineUseCase`: Validates routine constraints before saving to repository.
    - `GetRoutinesUseCase`: Retrieves the routines from repository.
  - **Verification:** 100% test coverage using standard pure Dart `test`.

---

## Phase 2: Data Layer (Local Persistence)

**Goal:** Implement Hive models, type adapters, and the concrete repository.

- [ ] **Task 2.1: Create Hive Models**
  - **Paths:** `lib/features/routine_manager/data/models/alarm_model.dart`, `lib/features/routine_manager/data/models/routine_model.dart`
  - **Description:** Implement Hive objects matching the domain entities. Generate TypeAdapters. Add `toEntity()` and `fromEntity()` mapping functions.

- [ ] **Task 2.2: Implement `RoutineRepositoryImpl`**
  - **Path:** `lib/features/routine_manager/data/repositories/routine_repository_impl.dart`
  - **Description:** Implement the `RoutineRepository` utilizing Hive boxes. Ensure exceptions/errors on quota limits or I/O are handled.
  - **Verification:** Mock Hive to verify data mapping between Models and Entities.

---

## Phase 3: Presentation Layer (State Management & UI)

**Goal:** Build Riverpod providers and the Flutter UI ensuring no direct data layer access.

- [ ] **Task 3.1: Implement Riverpod Controllers/Providers**
  - **Paths:** `lib/features/routine_manager/presentation/controllers/...`
  - **Description:**
    - `routine_list_provider`: Fetches and exposes `List<Routine>` state.
    - `routine_builder_controller`: Manages transient form state (name input, alarm list modification, drag-and-drop reordering state).

- [ ] **Task 3.2: Build Routine List Screen (Home)**
  - **Path:** `lib/features/routine_manager/presentation/screens/routine_list_screen.dart`
  - **Description:** 
    - Display an empty state if no routines exist.
    - Display list view of saved routines.
    - Floating Action Button (FAB) to trigger navigation to Builder Screen.
  - **Intent:** `// Fulfills INT-01`

- [ ] **Task 3.3: Build Routine Builder Screen**
  - **Path:** `lib/features/routine_manager/presentation/screens/routine_builder_screen.dart`
  - **Description:**
    - Unique Routine Name text field.
    - Add/Edit Alarm component with duration picker (minutes/seconds).
    - ReorderableListView for dragging and dropping alarms to update `orderIndex`.
    - "Save" button to trigger repository persistence and navigate back.
  - **Intent:** `// Fulfills INT-01, INT-02, INT-04, INT-10`

- [ ] **Task 3.4: Implement Unhappy Paths UI State**
  - **Path:** Handled in the Builder Screen / Controllers.
  - **Description:**
    - **Empty Routine Prevention:** Disable the save button or show error styling if user tries to save 0 alarms (INT-01 constraint).
    - **Storage Failure Response:** Display a standard Snackbar ("Failed to save routine") if the save operation throws an exception, keeping user on the builder screen.
