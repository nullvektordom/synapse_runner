# PROJECT CONTEXT: ADHD Accountability App

## 1. VISION & PHILOSOPHY
**Core Purpose:** "Interrupt me BEFORE I make a mistake."
This is a mobile-first, offline-first application designed to act as an external executive function for a user with ADHD.

**Strict Boundaries (The "Anti-Vision"):**
- ❌ NO Gamification (No points, streaks, or levels).
- ❌ NO Social features (Single user only).
- ❌ NO AI/Smart suggestions (Deterministic rules only).
- ❌ NO Cloud/Backend (Local-first, privacy-focused).
- **Design Philosophy:** "The Neutral Zone." No bright red colors (anti-shame). No sounds (vibration only).

## 2. TECH STACK (Immutable)
- **Framework:** Flutter (Mobile Android First).
- **Language:** Dart.
- **State Management:** Riverpod (with ProviderObserver for context safety).
- **Navigation:** GoRouter (Deep linking is critical for notifications).
- **Database:** Isar (NoSQL, fast, synchronous watchers).
- **Notifications:** `flutter_local_notifications` + `android_alarm_manager_plus`.
- **UI Libs:** FlexColorScheme (Minimalist), GAP (Layout), FL Chart (Simple viz).

## 3. ARCHITECTURE
**Pattern:** Feature-First.
Logic, UI, and Models are grouped by *domain*, not by technical layer.

```text
lib/
├── core/                  # Global configuration (Theme, Isar setup, Router)
├── features/
│   ├── working_memory/    # Current Task Banner logic
│   ├── meds/              # Medication tracking & reminders
│   ├── appointments/      # Notification-heavy appointment system
│   ├── financial_safety/  # Impulse control logic
│   └── hyperfocus/        # Timers & Full-screen takeovers
├── shared/                # Dumb widgets (buttons, inputs)
└── main.dart              # Entry point & Service Locator (GetIt)

```

## 4. DATA MODELS (Sources of Truth)

### TaskEntity (Working Memory)

*Use for: Persistent banner showing current activity.*

* `id`: Id
* `title`: String
* `startTime`: DateTime
* `estimatedDuration`: int (minutes)
* `isHyperfocusActive`: bool

### MedicationEntity

*Use for: Daily adherence and double-dose prevention.*

* `id`: Id
* `medName`: String
* `dosage`: String
* `scheduledTime`: DateTime
* `lastTakenTimestamp`: DateTime?
* `isVital`: bool

### AppointmentEntity

*Use for: The "Killer" notification system (24h/1h/15min warnings).*

* `id`: Id
* `title`: String
* `dateTime`: DateTime
* `notificationsSent`: List<String> (IDs of sent notifications)
* `isConfirmed`: bool (Must explicitly confirm to stop nagging)

### TransactionEntity (Impulse Brake)

*Use for: Cooling-off period for purchases.*

* `id`: Id
* `amount`: double
* `category`: String
* `timestamp`: DateTime
* `coolingOffEndsAt`: DateTime
* `isConfirmed`: bool (False until cooling period ends)

## 5. PROJECT STATUS (Sprint Tracker)

**Current Phase:** MVP Construction.

* **[COMPLETED] Sprint 0: Foundation.**
* Setup Flutter, Isar, Riverpod, GoRouter.
* Theme (FlexColorScheme) implemented.


* **[COMPLETED] Sprint 1: Working Memory.**
* TaskEntity implemented.
* Persistent Notification Service functional.
* "Current Task" banner UI active.


* **[IN PROGRESS] Sprint 2: Medication Tracker.**
* [x] CRUD for medications.
* [ ] Alarm Manager implementation (07:00 daily).
* [ ] "Take Medication" screen with checklist.
* [ ] Double-dose prevention logic.


* **[NEXT UP] Sprint 3: Appointment Killer.**
* 3-tier notification logic (24h, 1h, 15min).



## 6. CODING RULES FOR AI

1. **Safety First:** Always handle null safety. Use `try/catch` specifically around Isar DB operations.
2. **State:** Use `ref.watch` inside widgets. Use `NotifierProvider` for logic.
3. **UI:** Use `Gap(x)` for spacing. Avoid nested files; keep widgets small.
4. **Tone:** Comments should be helpful but brief.
5. **Scope Guard:** If a requested feature is not in the "MVP Scope" or violates "Anti-Vision", REJECT IT and reference Section 1.
