# Synapse Runner

ADHD executive function support app. Mobile-first Flutter application providing persistent, non-dismissible task reminders and medication tracking.

## Core Philosophy

- **"Interrupt me BEFORE I make a mistake"** — persistent visibility combats ADHD object permanence issues
- **The Neutral Zone** — no bright red/shame colors, no gamification, no social features, no AI suggestions
- **Offline-first, privacy-focused** — local-only data (Isar NoSQL), no cloud backend
- **Vibration feedback only** — no audio alerts

## Tech Stack

| Layer | Technology | Version |
|-------|-----------|---------|
| Framework | Flutter | SDK ^3.10.4 |
| Language | Dart | ^3.10.4 |
| State Management | Riverpod | ^2.6.1 |
| Navigation | GoRouter | ^14.6.2 |
| Database | Isar (NoSQL) | ^3.1.0+1 |
| Notifications | flutter_local_notifications | ^18.0.1 |
| Alarms | android_alarm_manager_plus | ^4.0.5 |
| Permissions | permission_handler | ^11.3.1 |
| Theming | FlexColorScheme (Material 3) | ^8.1.0 |
| Haptics | vibration | ^2.0.0 |
| Code Gen | isar_generator + build_runner | ^3.1.0+1 / ^2.4.13 |

## Architecture

### Feature-First Structure

```
lib/
├── main.dart                           # Entry point
├── core/                               # Shared infrastructure
│   ├── database/isar_service.dart      # Isar singleton initialization
│   ├── theme/app_theme.dart            # FlexColorScheme definitions
│   ├── routing/app_router.dart         # GoRouter config (also hosts HomeScreen)
│   ├── providers/notification_provider.dart
│   └── services/
│       ├── foreground_service.dart     # Method channel → native Android service
│       ├── alarm_service.dart          # android_alarm_manager_plus wrapper
│       └── permission_service.dart
├── features/
│   ├── working_memory/                 # Sprint 1 — current task management
│   ├── meds/                           # Sprint 2 — medication tracker
│   ├── appointments/                   # Sprint 3 — planned
│   ├── financial_safety/               # Sprint 4 — planned
│   └── hyperfocus/                     # Sprint 5+ — planned
└── shared/
    └── widgets/                        # Reusable dumb widgets
```

Each feature follows this internal layout:

```
feature/
├── models/           # Isar entity definitions (*Entity)
├── repositories/     # CRUD operations (*Repository)
├── providers/        # Riverpod state management (*Provider)
├── screens/          # Full-page widgets (*Screen)
├── widgets/          # Feature-specific components
├── controllers/      # Stateful UX logic (e.g., undo)
└── services/         # Feature-specific services
```

### Data Flow

```
UI (ConsumerWidget) → watches Provider → calls StateNotifier
→ executes Repository → modifies Isar → StreamProvider emits → UI rebuilds
```

### Routing

```
/                       → HomeScreen (in app_router.dart)
/tasks                  → TaskScreen
/medications            → MedicationListScreen
/take-meds              → TakeMedicationScreen
/appointments           → AppointmentListScreen
/appointments/add       → AddAppointmentScreen
/appointments/:id       → AppointmentDetailScreen
/appointments/:id/edit  → AddAppointmentScreen (edit mode)
```

### Native Android Layer

Critical for non-dismissible notifications. Located in `android/app/src/main/kotlin/com/example/synapse_runner/`:

- **TaskForegroundService.kt** — persistent foreground notification (FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
- **TaskNotificationListener.kt** — detects and recreates dismissed notifications on Android 14+
- **MainActivity.kt** — method channel bridge (`synapse_runner/foreground_service`)

Method channel methods: `startService`, `updateService`, `stopService`

## Database

Isar NoSQL with singleton initialization via `IsarService.instance`. Collections:

- **TaskEntity** — title (indexed), description, startTime, durationMinutes, reminderFrequencyMinutes, isCompleted
- **MedicationEntity** — medName (indexed), dosage, scheduledTime, scheduledTimesMinutes[], takenDoses[], isVital
- **AppointmentEntity** — title (indexed), description, dateTime (indexed), isCompleted, notificationTiers[]

Generated files (`*.g.dart`) are produced by `isar_generator`. Regenerate with:

```bash
dart run build_runner build
```

## Android Configuration

- **Package:** `com.example.synapse_runner`
- **compileSdk:** 36 / **minSdk:** 24 / **targetSdk:** 35
- **Java:** 17
- Key permissions: `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_SPECIAL_USE`, `WAKE_LOCK`, `VIBRATE`, `RECEIVE_BOOT_COMPLETED`

## Conventions

### Naming

| Element | Convention | Example |
|---------|-----------|---------|
| Files | snake_case | `task_entity.dart` |
| Classes | PascalCase | `TaskScreen`, `MedicationEntity` |
| Variables/Functions | camelCase | `_selectedTime`, `createTask()` |
| Private members | Underscore prefix | `_isar`, `_selectedTime` |
| Entities | `*Entity` | `TaskEntity` |
| Repositories | `*Repository` | `MedicationRepository` |
| Providers | `*Provider` (camelCase var) | `medicationProvider` |
| Screens | `*Screen` | `AddMedicationScreen` |
| Services | `*Service` | `AlarmService` |

### Dart/Flutter Patterns

- `ConsumerWidget` for read-only provider access; `ConsumerStatefulWidget` when local state is also needed
- `ref.watch()` in build methods; `ref.read()` for one-shot calls; `ref.listen()` for side effects
- Null safety enforced — use `try/catch` around Isar operations specifically
- `ValueKey` on list items to prevent rebuild issues
- Proper `dispose()` for controllers

### Import Order

```dart
import 'dart:async';                    // Standard library
import 'package:flutter/material.dart'; // Flutter SDK
import 'package:flutter_riverpod/...';  // Third-party packages
import '../models/task_entity.dart';    // Relative project imports
```

### Anti-Patterns (Do Not)

- No gamification (points, streaks, levels)
- No social features
- No AI/smart suggestions — deterministic rules only
- No audio alerts — vibration only
- No bright red colors or shame-inducing UI
- Do not add features outside the current sprint scope
- `get_it` is in pubspec but unused — Riverpod handles DI

## Sprint Roadmap

| Sprint | Feature | Status |
|--------|---------|--------|
| 0 | Foundation (Flutter + Isar + Riverpod + GoRouter + Theme) | Done |
| 1 | Working Memory — persistent task banner + foreground service | Done |
| 2 | Medication Tracker — CRUD, alarm scheduling, double-dose prevention | Done |
| 3 | Appointment Killer — 3-tier notification warnings (24h, 1h, 15min) | In Progress |
| 4 | Financial Safety — impulse purchase cooling-off periods | Planned |
| 5+ | Hyperfocus — session timers, full-screen takeover, DND integration | Planned |

## Build & Run

```bash
flutter run                              # Run on connected device
flutter run --release                    # Release mode
dart run build_runner build              # Regenerate Isar entities
flutter analyze                          # Run linter
flutter clean && flutter pub get         # Clean rebuild
flutter build apk                        # Build APK
```

## Testing

No automated test suite yet beyond the default `test/widget_test.dart`. Manual testing follows the checklist in `Documentation/TESTING_CHECKLIST.md` covering:

1. Installation & permissions flow
2. Task creation & notification display
3. Notification persistence (backgrounding, sleep)
4. Dismissal prevention (swipe-away blocked)
5. Task completion flow
6. Multiple tasks behavior
7. Edge cases & error handling
8. Performance & battery usage (<2% per hour target)

ADB diagnostics:

```bash
adb shell dumpsys activity services | grep TaskForeground
adb shell dumpsys notification | grep synapse_runner
adb logcat | grep TaskForegroundService
```

## Documentation

Detailed docs live in `Documentation/`:

- `FOREGROUND_SERVICE_IMPLEMENTATION.md` — architecture of non-dismissible notifications
- `ANDROID_14_WORKAROUND.md` — NotificationListenerService for Android 14+ dismissal issue
- `CRITICAL_FIX_SWIPE_DISMISS.md` — swipe dismiss bug fixes
- `TROUBLESHOOTING_SWIPE_DISMISS.md` — debugging guide
- `SETUP_ADB_AND_DIAGNOSE.md` — ADB setup and diagnostic procedures
- `TESTING_CHECKLIST.md` — comprehensive Sprint 1 test plan

Project planning docs are in the Obsidian vault at `/home/nullvektor/obsidian/projects/synapse_runner`.

## Git Workflow

- **Main branch:** `main`
- **Development branch:** `develop`
- PRs go from feature branches → `develop` → `main`
- No CI/CD pipeline configured yet

## Project Config

`nexus.toml` links this repo to the Obsidian vault and tracks the active sprint:

```toml
[state.active_sprint]
current = "sprint-2-medication-tracker"
status = "in_progress"
```
