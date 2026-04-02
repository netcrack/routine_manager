# Routine Manager

**Intent-Driven Routine & Alarm Orchestrator**

Enable users to create, run, control, and complete a single routine composed of ordered, time-bound alarms with clear execution outcomes.

---

## 🌟 Project Vision

The **Routine Manager** is designed to provide high-precision, sequential alarm management. Unlike traditional alarm systems, it focuses on "Routines"—ordered sequences of time-bound events where each step's completion is an atomic event that triggers the next. 

Built with **Intent-Driven Development (IDD)**, every feature is explicitly mapped to a business outcome, ensuring the system remains verifiable, stable, and deterministic.

---

## 🚀 Key Capabilities

### 🛠️ CAP-01: Routine Management & Configuration
Full control over routine lifecycle and structure:
- **Create Routine**: Define unique routines with ordered alarm sequences.
- **Dynamic Durations**: Assign precise time-bound durations to each alarm.
- **Flexible Ordering**: Reorder, edit, and update routine steps seamlessly.

### ⚙️ CAP-02: Session Execution Engine
The core logic for routine orchestration:
- **Sequential Execution**: Subsequent alarms activate only after the preceding one is confirmed.
- **Session Control**: Start, pause, resume, and stop routines at any time.
- **Atomic Completion**: Guaranteed transition to completion when the final alarm is cleared.

### 🔔 CAP-03: Alerting & Notification
Robust alerting system for reliable routine progression:
- **Multi-State Notifications**: Alerts fire in foreground, background, and cold-start states.
- **Persistent Ringing**: Alarms remain active until explicitly dismissed by the user.
- **Deep Linking**: Tapping notifications instantly navigates back to the active session.

### 💾 CAP-04: Session Persistence & Recovery
Ensuring state continuity across system interruptions:
- **State Recovery**: Automatically restores sessions after app relaunch or device reboots.
- **Reliable Heartbeat**: Internal timers ensure precise alarm triggering even after system-level background limits.

---

## 🏛️ Architecture & Methodology

### Intent-Driven Development (IDD)
This project follows strict IDD principles to bridge the gap between business requirements and technical implementation. 
- **Atomic Intents**: Each requirement is a unique ID (e.g., `INT-01`) with clear success criteria.
- **Verifiability**: All intents are tested with binary (Pass/Fail) outcomes.

### Clean Architecture
The codebase is structured into three distinct layers:
1. **Domain**: Pure business logic, entities, and use-case definitions (the "Heart" of the system).
2. **Presentation**: Flutter UI and Riverpod providers for state orchestration.
3. **Data**: Hive-based persistence and local notification implementations.

---

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev)
- **State Management**: [Riverpod 2.0](https://riverpod.dev) (using code generation)
- **Persistence**: [Hive](https://pub.dev/packages/hive) (Lightweight NoSQL for local storage)
- **Navigation**: [GoRouter](https://pub.dev/packages/go_router)
- **Alerting**: [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)
- **Testing**: [Mocktail](https://pub.dev/packages/mocktail) for unit and widget testing.

---

## 🏁 Getting Started

### Prerequisites
- Flutter SDK (latest stable)
- Dart SDK

### Installation

1. **Clone the repository**
2. **Install dependencies**:
   ```bash
   flutter pub get
   ```
3. **Run Code Generation** (Required for Riverpod, Hive, and Data Models):
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
4. **Run the Application**:
   ```bash
   flutter run
   ```

---

## 📖 Documentation

For deeper technical details, please refer to the `agent_docs/` directory:
- [Business Intents](file:///Users/ashokm/development/flutter_test/routine_manager/agent_docs/intents.md): Vision and granular requirements.
- [Core Standards](file:///Users/ashokm/development/flutter_test/routine_manager/agent_docs/core_standards.md): Architectural rules and coding standards.
- [User Journeys](file:///Users/ashokm/development/flutter_test/routine_manager/agent_docs/user_journeys.md): Step-by-step system flow paths.

---

*Built with ❤️ using the Intent-Driven Development methodology.*
