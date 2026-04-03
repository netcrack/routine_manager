# Business Intents

## Vision Statement

Enable users to create, run, control, and complete a single routine composed of ordered, time-bound alarms with clear execution outcomes.

---

## 0. Meta-Rules: Intent Definition & Evolution
These rules serve as the project-agnostic guardrail for defining, mapping, and evolving system intents. They ensure that all business requirements are atomic, verifiable, and structurally sound for downstream development.

### 0.1. Rules for Documentation
1. **Outcome-Centric (Declarative)**: Intents MUST describe the desired end-state or behavior, never the implementation (UI, DB, or Framework). Avoid all project-specific technology or UI terminology.
2. **Atomic Verifiability**: Every intent MUST define a single, verifiable "Definition of Done". If an outcome cannot be tested with a binary (Pass/Fail) result, it is too vague.
3. **Identification & Traceability**: Every intent MUST have a unique, permanent ID (e.g., `INT-XX`) to enable deterministic mapping in architectural standards, user journeys, and test suites.
4. **Lifecycle Completeness**: Intents MUST account for the full lifecycle of a system capability, including its start, execution, interruption (pause/stop), and final completion.
5. **Ambiguity Elimination**: If an intent can be interpreted in multiple ways, it MUST be decomposed into smaller, atomic intents to ensure absolute clarity for AI implementation.
6. **Priority-Driven**: Every intent MUST be assigned a priority level (High, Medium, Low) to guide development sequencing and resource allocation.
7. **Explicit AI Acknowledgement**: The AI MUST explicitly acknowledge that it has read and understands these Meta-Rules before being permitted to edit this document.

### 0.2. Document Structure
To maintain consistency, any `intents.md` MUST follow this hierarchical structure:
1. **Vision Statement**: High-level goal of the system.
2. **Capabilities (CAP-XX)**: High-level system modules (Derived Layer).
3. **System Intents (INT-XX)**: Table-based definitions of business outcomes.
    - Columns: ID, Intent Name, Success Criteria (Definition of Done), Priority.

### 0.3. Evolutionary Integrity
Rules 0.1 and 0.2 are immutable across project iterations. All intents MUST collectively fulfill the project's high-level Vision Statement without contradiction.

---

## 1. Capabilities & System Intents

### CAP-01: Routine Management & Configuration
Create, update, retrieve, and delete routines, including the configuration of their alarm sequences.

| ID | Intent Name | Success Criteria (Definition of Done) | Priority |
|----|-------------|----------------------------------------|----------|
| INT-01 | Create Routine Definition | A user can create one routine with a unique name and at least one alarm, and the routine is saved and retrievable by name. | High |
| INT-02 | Define Alarm-Level Duration | A user can assign a duration to each alarm in the routine, and each alarm enters a due state when its configured duration is reached. | High |
| INT-04 | Reorder Alarms | A user can modify the sequence order of alarms before execution, and the next run follows the saved order. | High |
| INT-10 | Update Existing Routine Content | A user can edit the name, alarm durations, or alarm order of an existing routine, and the saved changes are reflected in the next run. | Medium |
| INT-14 | Bulk Update Alarm Durations | A user can apply a single duration value to all alarms within a routine simultaneously during creation or editing, and the change is persisted across all alarms in that routine. | Medium |


### CAP-02: Session Execution Engine
Control lifecycle and state transitions of a single active routine session.

| ID | Intent Name | Success Criteria (Definition of Done) | Priority |
|----|-------------|----------------------------------------|----------|
| INT-03 | Execute Routine Once | A user can start a routine in saved sequence without repetition, and each subsequent alarm only becomes active after the preceding alarm has been stopped. | High |
| INT-05 | Stop Active Routine | A user can stop an active routine at any time, and no remaining alarms in that routine continue after stop is confirmed. | High |
| INT-06 | Pause Active Routine | A user can pause an active routine at any time, and no alarm progression occurs while the routine remains paused. | High |
| INT-09 | Maintain Single Active Routine | A user can have only one active routine at a time, and any attempt to start another routine while one is active is blocked. | Medium |
| INT-11 | Confirm Routine Completion | When the final alarm is stopped, the routine transitions to a completed state and the user is informed of this outcome as a single atomic event, with no alarms remaining pending. | Medium |

### CAP-03: Alerting & Notification
Handle alarm triggering, notification delivery, and persistent alert behavior.

| ID | Intent Name | Success Criteria (Definition of Done) | Priority |
|----|-------------|----------------------------------------|----------|
| INT-07 | Notify Alarm Due Events | A user receives one notification when an alarm duration is reached, regardless of whether the app is in the foreground, background, or closed. | High |
| INT-08 | Ring Alarm Until Stopped | A due alarm remains in an active alert state until the user explicitly stops it. | High |
| INT-12 | Notification-Triggered Navigation | Tapping an active session notification reliably navigates the user to the active routine's control interface, regardless of the app's previous state (background/closed). | High |

### CAP-04: Session Persistence & Recovery
Ensure session state continuity across backgrounding, termination, and restart.

| ID | Intent Name | Success Criteria (Definition of Done) | Priority |
|----|-------------|----------------------------------------|----------|
| INT-13 | Recover Active Session | A user can reliably continue a routine after an app relaunch or system reboot, with the session state (running/paused/ringing) correctly restored based on elapsed time. | High |

### CAP-05: Routine Run History
Provide visibility into past routine executions and their outcomes.

| ID | Intent Name | Success Criteria (Definition of Done) | Priority |
|----|-------------|----------------------------------------|----------|
| INT-15 | Persist Routine Run Data | Every routine execution that concludes (reaches Completed or Stopped state) is automatically recorded with its date, session start time, and conclusion time. | High |
| INT-16 | Browse Routine Execution History | A user can view a chronological log of all past routine runs, showing the date and the specific routine that was executed. | Medium |
| INT-17 | View Individual Run Details | A user can view the specific session start time and the conclusion time (completed/stopped) for any selected run in the history log. | Medium |
| INT-18 | Maintain Sliding History Window | The system automatically prunes records older than 180 days to optimize local storage, while keeping the local database lightweight and performant. | Low |

