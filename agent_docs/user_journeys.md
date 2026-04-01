# User Journeys
**Project:** Routine Manager
**Methodology:** Intent-Driven Development (IDD) + Feature-First Clean Architecture

These mapped journeys serve as the bridge between the exact business rules (`intents.md`) and the Flutter Screen flows. They dictate how a user accomplishes the success criteria.

---

## Journey 1: Managing Routines (Create, List, Update)

This journey covers the creation and modification of routines before execution.
**Fulfills:** `INT-01`, `INT-02`, `INT-04`, `INT-10`

1.  **Routine List Screen (Home)**
    *   **Trigger:** User launches the app.
    *   **Action (INT-01 Check):** User sees an empty state or a list of saved routines. User taps the `+` FAB to create a new routine.
    *   *Result:* Navigates to the Routine Builder Screen.

2.  **Routine Builder Screen (Creation & Edit)**
    *   **Trigger:** Landing from List Screen.
    *   **Action (INT-01 Check):** User enters a unique Routine name.
    *   **Action (INT-02 Check):** User adds one or multiple Alarms. For each, they scroll a duration picker (e.g., minutes/seconds).
    *   **Action (INT-04 Check):** User drags and drops the Alarms in the list to reorder them before saving.
    *   **Action (INT-10 Check):** User taps "Save".
    *   *Result:* The routine is validated and persisted via Hive. Returns to the Routine List Screen where the new routine is visible.

---

## Journey 2: Executing a Routine (Start, Pause, Ring, Complete)

This journey covers the active session state management constraint (`INT-09`).
**Fulfills:** `INT-03`, `INT-05`, `INT-06`, `INT-07`, `INT-08`, `INT-09`, `INT-11`

1.  **Routine List Screen -> Active Session**
    *   **Trigger:** User views a saved routine and taps "Start / Play".
    *   **Action (INT-09 Enforcement):** If a routine is already running, starting a new one is disabled or triggers a blocker dialog.
    *   *Result:* Navigates to the Active Session Screen. The first Alarm begins counting down immediately (`INT-03`).

2.  **Active Session Screen (Running State)**
    *   **Trigger:** The active alarm timer is visually ticking down.
    *   **Action (INT-06 Check):** User taps "Pause". The timer halts. User taps "Resume" to continue.
    *   **Action (INT-05 Check):** At any time, User taps "Stop". A confirmation dialog appears. If confirmed, the session is destroyed, returning to the Home Screen.

3.  **Active Session Screen (Ringing State)**
    *   **Trigger:** The countdown reaches 0 duration.
    *   **Action (INT-07 & INT-08 Check):** A system notification fires ONCE. Meanwhile, continuous audio/visual ringing alerts the user persistently on the screen.
    *   **Action (INT-03 Check):** User taps "Stop Alarm / Next". The ringing stops. The current alarm is marked done, and the next sequential alarm automatically enters the "Running State".

4.  **Active Session Screen (Completion)**
    *   **Trigger:** The final alarm in the sequence reaches 0 duration and is stopped by the User.
    *   **Action (INT-11 Check):** The active session transitions to a "Completed" state. A success message is shown locally atomically, and the active session lock `INT-09` is cleared. User returns to the Routine List Screen.

---

## Journey 3: Unhappy Paths & Edge Cases

This journey explicitly defines error states to prevent the AI from generating unhandled exceptions or dead ends.

1.  **Missing Permissions (Notification / Audio)**
    *   **Trigger:** User attempts to tap "Start / Play" on a routine.
    *   **Action:** System checks for required Notification / Background Execution permissions.
    *   *Result:* If denied, the routine is blocked from starting (`INT-09` remains inactive). A persistent "Permissions Required" banner or dialog explains that accurate alarms cannot function.

2.  **Storage Failure (Routine Creation)**
    *   **Trigger:** User taps "Save" on the Routine Builder Screen.
    *   **Action:** Hive encounters an IO error or quota limit.
    *   *Result:* The UI remains on the Builder Screen. A standard snackbar is displayed: "Failed to save routine," ensuring the user's configuration is not lost (`INT-01` validation fail).

3.  **Empty Routine Prevention**
    *   **Trigger:** User taps "Save" with 0 alarms added.
    *   **Action:** Domain logic enforces the `size > 0` constraint.
    *   *Result:* The "Save" button is disabled, or tapping it highlights the "Add Alarm" button with an error color (`INT-01` constraint).
