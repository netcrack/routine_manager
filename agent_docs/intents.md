# Business Intents

## Vision Statement

Enable users to create, run, control, and complete a single routine composed of ordered, time-bound alarms with clear execution outcomes.

---

## Rules for Intent Creation

| Rule | Description |
|------|-------------|
| **Declarative** | Describe the desired end-state, not the implementation. |
| **Atomic** | One outcome per intent. |
| **Verifiable** | Define exactly what 'success' looks like. |
| **Constraint** | Do not mention technology stacks or UI elements. |

---

## Intents Table

| ID | Intent Name | Success Criteria (Definition of Done) | Priority |
|----|-------------|----------------------------------------|----------|
| INT-01 | Create Routine Definition | A user can create one routine with a unique name and at least one alarm, and the routine is saved and retrievable by name. | High |
| INT-02 | Define Alarm-Level Duration | A user can assign a duration to each alarm in the routine, and each alarm enters a due state when its configured duration is reached. | High |
| INT-03 | Execute Routine Once | A user can start a routine in saved sequence without repetition, and each subsequent alarm only becomes active after the preceding alarm has been stopped. | High |
| INT-04 | Reorder Alarms | A user can modify the sequence order of alarms before execution, and the next run follows the saved order. | High |
| INT-05 | Stop Active Routine | A user can stop an active routine at any time, and no remaining alarms in that routine continue after stop is confirmed. | High |
| INT-06 | Pause Active Routine | A user can pause an active routine at any time, and no alarm progression occurs while the routine remains paused. | High |
| INT-07 | Notify Alarm Due Events | A user receives one notification when an alarm duration is reached. | High |
| INT-08 | Ring Alarm Until Stopped | A due alarm remains in an active alert state until the user explicitly stops it. | High |
| INT-09 | Maintain Single Active Routine | A user can have only one active routine at a time, and any attempt to start another routine while one is active is blocked. | Medium |
| INT-10 | Update Existing Routine Content | A user can edit the name, alarm durations, or alarm order of an existing routine, and the saved changes are reflected in the next run. | Medium |
| INT-11 | Confirm Routine Completion | When the final alarm is stopped, the routine transitions to a completed state and the user is informed of this outcome as a single atomic event, with no alarms remaining pending. | Medium |
