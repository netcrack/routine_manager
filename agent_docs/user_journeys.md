# User Journeys
**Project:** Routine Manager
**Methodology:** Intent-Driven Development (IDD) + Feature-First Clean Architecture

These mapped journeys serve as the bridge between the exact business rules (`intents.md`) and the Flutter Screen flows. They dictate how a user accomplishes the success criteria.

---

## 0. Meta-Rules: User Journey Mapping & Validation
These rules serve as the definitive guardrail for defining and evolving user journeys. They ensure that all system interactions are logically derived from business intents and provide a clear blueprint for UI implementation and system flow synchronization.

### 0.1. Rules for Documentation
1. **Intent-Anchored Design**: Every user journey MUST explicitly map to one or more system intents (`INT-XX`). No journey step should exist without a supporting intent.
2. **User-System Synchronicity**: Each step MUST be decomposed into a user-facing interaction (Trigger/Action) and a corresponding internal system operation (System Flow).
3. **Atomic Journey Outcomes**: Every journey MUST lead to a deterministic "Result" that verifies the completion of the involved intents’ success criteria.
4. **Resilient Lifecycle Mapping**: Journeys MUST explicitly account for system state persistence and recovery across all lifecycle phases (Background, Interruption, and Termination).
5. **Negative Path Coverage**: Journeys MUST define "Unhappy Paths" (Edge Cases, Permissions, Failures) as first-class citizens to ensure graceful degradation and error handling.
6. **Logical Flow Integrity**: Transitions between journey steps MUST be based on valid domain state changes, ensuring no illegal or impossible user flows.
7. **Explicit AI Acknowledgement**: The AI MUST explicitly acknowledge that it has read and understands these Meta-Rules before being permitted to edit this document.

### 0.2. Document Structure
To maintain consistency, any `user_journeys.md` MUST follow this hierarchical structure:
1. **Journey Features**: Logical groupings of journeys (e.g., Managing Routines, Executing a Routine).
2. **Journey Definitions**:
    - **Trigger/Action/Result**: Definition of user-facing steps.
    - **System Flow**: Bulleted list of technical steps linked back to INT-XX.
3. **Unhappy Paths**: Specific section for error states and edge cases.

### 0.3. Evolutionary Integrity
Rules 0.1 and 0.2 are immutable across project iterations. They maintain the synchronicity between user experience and system engineering.

---

## Journey 1: Managing Routines (Create, List, Update)

This journey covers the creation and modification of routines before execution.
**Fulfills:** `INT-01`, `INT-02`, `INT-04`, `INT-10`, `INT-14`

1.  **Routine List Screen (Home)**
    *   **Trigger:** User launches the app.
    *   **Action (INT-01 Check):** User sees an empty state or a list of saved routines. User taps the `+` FAB to create a new routine.

    **System Flow:**
    * Fetch all persisted Routine entities from storage (INT-01)
    * Monitor for real-time routine updates/deletions

    *   *Result:* Navigates to the Routine Builder Screen.

2.  **Routine Builder Screen (Creation & Edit)**
    *   **Trigger:** Landing from List Screen.
    *   **Action (INT-01 Check):** User enters a unique Routine name.
    *   **Action (INT-02 Check):** User adds one or multiple Alarms. For each, they scroll a duration picker (e.g., minutes/seconds).
    *   **Action (INT-04 Check):** User drags and drops the Alarms in the list to reorder them before saving.
    *   **Action (INT-14 Check):** User sets a global duration applied to all current alarms in the list simultaneously.
    *   **Action (INT-10 Check):** User taps "Save".

    **System Flow:**
    * Validate unique routine name and minimum alarm count (INT-01)
    * Sequence alarms by user-defined order (INT-04)
    * Persist Routine entity to primary storage (INT-10)
    * Broadcast updated routine listing state

    *   *Result:* The routine is validated and persisted via Hive. Returns to the Routine List Screen where the new routine is visible.

---

## Journey 2: Executing a Routine (Start, Pause, Ring, Complete)

This journey covers the active session state management constraint (`INT-09`).
**Fulfills:** `INT-03`, `INT-05`, `INT-06`, `INT-07`, `INT-08`, `INT-09`, `INT-11`

1.  **Routine List Screen -> Active Session**
    *   **Trigger:** User views a saved routine and taps "Start / Play".
    *   **Action (INT-09 Enforcement):** If a routine is already running, starting a new one is disabled.
    *   **Safety Constraints:** The "Delete" action is disabled for the active routine to prevent session corruption. "Delete" remains enabled for all other routines.

    **System Flow:**
    * Check ActiveSession lock (INT-09)
    * Instantiate ActiveSession with Routine copy and set both `sessionStartTime` and `anchorTime` (INT-15/INT-03)
    * Schedule background notifications for alarm durations (INT-07)
    * Persist session state for integrity/recovery
    * Start first alarm countdown timer (INT-03)

    *   *Result:* Navigates to the Active Session Screen. The first Alarm begins counting down immediately (`INT-03`).

2.  **Active Session Screen (Running State)**
    *   **Trigger:** The active alarm timer is visually ticking down.
    *   **Action (INT-06 Check):** User taps "Pause". The timer halts. User taps "Resume" to continue.

    **System Flow:**
    * **Pause:** Halt active timer and update session state to "Paused" (INT-06). Calculate remaining duration and cancel pending notifications (INT-07).
    * **Stop:** Purge active timer, cancel all notifications (INT-07), stop ringing audio (INT-08), and release ActiveSession lock (INT-09/INT-05).

3.  **Active Session Screen (Ringing State)**
    *   **Trigger:** The countdown reaches 0 duration.

    **System Flow:**
    * **Trigger:** Transition session state to "Ringing", fire system notification (INT-07), and activate persistent audio (INT-08).
    * **Next (INT-03/INT-11):** Terminate audio (INT-08), finalize current alarm. 
        * *If not last alarm:* Action button transitions to **"Next Alarm"**, selecting next sequential alarm on tap (INT-03). **System Flow:** Update `anchorTime` while preserving `sessionStartTime`.
        * *If last alarm:* Action button transitions to **"Finish Routine"**, initiating completion sequence on tap (INT-11).

4.  **Active Session (Background & Termination)**
    *   **Trigger:** User minimizes the app or force-closes it during the "Running State".
    *   **Action (INT-07 Check):** The system-level scheduled notification remains active.

    **System Flow:**
    * OS-level alarm manager/scheduler triggers notification independently of app process lifecycle (INT-07).

    *   *Result:* When the duration is reached, the system notification fires even if the app process is dead.

5.  **Active Session (App Resume & Recovery)**
    *   **Trigger:** User taps the notification (INT-12) or manually relaunches the app after the alarm duration has passed.
    *   **Action (State Recovery Check):** The app reads the persisted `ActiveSession` and calculates that the alarm is overdue.

    **System Flow:**
    * Retrieve ActiveSession from persistence
    * **Notification Hook (INT-12):** Catch notification tap event and trigger navigation to Active Session Screen.
    * Evaluate current time vs. `anchorTime` for alarm overdue check (INT-02)
    * Evaluate current time vs. `sessionStartTime` for zombie session check (Reliability)
    * Re-calculate remaining duration or trigger overdue alarm
    * Sync system state with recovery data

    *   *Result:* The app immediately enters the "Ringing State" UI (`INT-08`) on the session screen, allowing the user to proceed to the next alarm or finish the routine.

6.  **Active Session Screen (Completion)**
    *   **Trigger:** The final alarm in the sequence reaches 0 duration and the user taps "Finish Routine".
    *   **Action (INT-11 Check):** Clicking "Finish Routine" on the final alarm is a terminal action. The user is returned to the Home Screen **immediately** while a success notification is shown. The session state transitions directly to **inactive** (clearing the ActiveSession lock `INT-09`).

    **System Flow:**
    * Verify final alarm termination (INT-11)
    * Purge ActiveSession persistence and release session lock (INT-09)
    * Record routine completion outcome and reset system state to **inactive**
    * **Apply Retention Policy (INT-18):** Prune all history records older than 180 days from the persistent history storage.
    * Broadcast session completion confirmation

    *   *Result:* The session record is cleared, and the user is redirected to the Home Screen with a **success notification**.

---

## Journey 3: Unhappy Paths & Edge Cases

This journey explicitly defines error states to prevent the AI from generating unhandled exceptions or dead ends.

1.  **Missing Permissions (Notification / Audio)**
    *   **Trigger:** User attempts to tap "Start / Play" on a routine.
    *   **Action:** System checks for required Notification / Background Execution permissions.

    **System Flow:**
    * Validate permission status via native bridge. If denied, block `ActiveSession` instantiation (INT-09).

    *   *Result:* The routine is blocked from starting. A persistent "Permissions Required" banner or dialog explain that accurate alarms cannot function.

2.  **Storage Failure (Routine Creation)**
    *   **Trigger:** User taps "Save" on the Routine Builder Screen.
    *   **Action:** Hive encounters an IO error or quota limit.

    **System Flow:**
    * Catch persistence exceptions and map to `storageFailure` domain error. Prevent UI transition to List Screen (INT-01/INT-10).

    *   *Result:* The UI remains on the Builder Screen. A standard **error notification** is displayed: "Failed to save routine," ensuring the user's configuration is not lost.

3.  **Empty Routine Prevention**
    *   **Trigger:** User taps "Save" with 0 alarms added.
    *   **Action:** User attempts to persist an invalid invariant.

    **System Flow:**
    * Domain logic enforces `alarms.length > 0` constraint during validation phase (INT-01).

    *   *Result:* The "Save" button is disabled, or tapping it highlights the "Add Alarm" button with an error color, preventing invalid routine creation.

---

## Journey 4: Reviewing Routine Run History

This journey covers the retrieval and inspection of past routine executions, ensuring users can track their performance over time.
**Fulfills:** `INT-15`, `INT-16`, `INT-17`, `INT-18`

1.  **Routine List Screen (Home) -> History**
    *   **Trigger:** User is on the Home Screen and taps the "History" icon in the AppBar.
    *   **Action (Empty State):** If no `RoutineRun` records exist, the user sees an "Empty History" state with an encouraging action (e.g., "Start your first routine").
    *   **Action (INT-16 Check):** User views a chronological list of all routine executions from the last 180 days.
    *   **Action (INT-18 Check):** User observes that data older than 6 months is automatically pruned.

    **System Flow:**
    * Query `RoutineRun` entity from history storage, sorted by `endTime` (descending) (INT-16).
    * Map `routineId` to current routines to determine if the source routine still exists.

    *   *Result:* Navigates to the History Screen, displaying a clear log of past performance.

2.  **History Screen -> Run Detail View**
    *   **Trigger:** User taps a specific execution record in the history list.
    *   **Action (INT-17 Check):** User views the precise session start time, end time (completed or stopped), and total duration for that run.
    *   **Action (Data Integrity):** If the original routine was deleted, the user sees the captured name snapshot (e.g., "Morning Cardio") but the "View Routine" button is disabled.

    **System Flow:**
    * Fetch detailed `RoutineRun` metadata (INT-17).
    * Provide a navigational link back to the `Routine Builder Screen` ONLY if the routine still exists in primary storage.

    *   *Result:* The user obtains a detailed summary of their routine performance, with stable naming even for deleted routines.

3.  **Zombie Session Recovery (Edge Case)**
    *   **Trigger:** User relaunching the app after 24+ hours of inactivity during an active routine.
    *   **Action:** System detects a stale persisted `ActiveSession`.
    
    **System Flow:**
    * Validate session age vs. current time (Recovery Logic).
    * **State Correction:** Transition state to `Stopped`, clearing the global session lock (INT-09).
    * **State Preservation:** Automatically persist the truncated `RoutineRun` (INT-15) so the attempt is logged in history.
    
    *   *Result:* The user is returned to the Home Screen, and the "locked" state is cleared, allowing new routines to start.
