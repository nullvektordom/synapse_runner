# Synapse Runner - Testing Checklist

## Sprint 1: Current Task Banner - Device Testing

**Status:** ⏸️ Awaiting device connection
**Last Updated:** 2025-12-27

---

## Pre-Test Setup

### Requirements
- [ ] Android device with USB debugging enabled
- [ ] Device running Android 10+ (API level 29+)
- [ ] USB cable connected to development machine
- [ ] Device authorized for debugging

### Verification Commands
```bash
# Verify device connected
adb devices

# Should show your device like:
# List of devices attached
# ABC123XYZ    device

# Install and run app
flutter run

# Monitor logs (optional, run in separate terminal)
adb logcat | grep -i "notification\|permission\|flutter"
```

---

## Test Suite 1: Initial Installation & Permissions

### Test 1.1: Fresh Install Permission Flow
**Goal:** Verify notification permissions are requested on first launch

- [ ] Uninstall app if previously installed: `adb uninstall com.example.synapse_runner`
- [ ] Run `flutter run` to install fresh
- [ ] **Expected:** Permission dialog appears requesting notification access
- [ ] Grant permission
- [ ] **Expected:** App continues to home screen without errors
- [ ] Check logcat for permission-related errors

**Pass Criteria:**
- Permission dialog appears on Android 13+
- No crashes or errors in logs
- App starts successfully after granting permission

---

## Test Suite 2: Task Creation & Notification Display

### Test 2.1: Create First Task
**Goal:** Verify task creation and notification appearance

- [ ] Navigate to Tasks screen (tap "Manage Tasks" button)
- [ ] Tap "Add Task" FAB
- [ ] Enter task details:
  - Title: "Test Task 1"
  - Description: "Testing notification persistence"
  - Duration: 30 minutes
- [ ] Tap "Create Task"
- [ ] **Expected:** Task appears in banner at top of screen
- [ ] Pull down notification tray
- [ ] **Expected:** Notification shows with title "Current Task: Test Task 1"

**Pass Criteria:**
- Task banner visible in app
- Notification visible in system tray
- Notification shows correct task title and description

### Test 2.2: Notification Content Verification
**Goal:** Verify notification displays all required information

- [ ] Expand notification in tray
- [ ] **Expected:** Shows BigText style with full description
- [ ] **Expected:** Shows duration timer ("Running for X min")
- [ ] Note: Check if notification is in "Ongoing" section (non-dismissible)

**Pass Criteria:**
- Full description visible when expanded
- Duration counter present
- Notification in "Ongoing" section of notification tray

---

## Test Suite 3: Notification Persistence

### Test 3.1: App Switching Persistence
**Goal:** Verify notification survives app backgrounding

- [ ] With task active and notification showing
- [ ] Press Home button to background app
- [ ] **Expected:** Notification remains in tray
- [ ] Open another app (Chrome, Settings, etc.)
- [ ] **Expected:** Notification still visible
- [ ] Return to Synapse Runner
- [ ] **Expected:** Task banner still shows same task

**Pass Criteria:**
- Notification visible after backgrounding app
- Notification visible while using other apps
- Task state preserved when returning to app

### Test 3.2: Device Sleep Persistence
**Goal:** Verify notification survives device lock/sleep

- [ ] With task active and notification showing
- [ ] Lock device (press power button)
- [ ] Wait 10 seconds
- [ ] Unlock device
- [ ] **Expected:** Notification still in tray
- [ ] Open app
- [ ] **Expected:** Task banner still shows same task

**Pass Criteria:**
- Notification survives device lock
- Task state preserved after unlock
- No "stale" or duplicate notifications

### Test 3.3: Extended Background Duration
**Goal:** Verify foreground service keeps notification alive

- [ ] With task active and notification showing
- [ ] Background app for 5 minutes
- [ ] Use device normally (other apps, browsing, etc.)
- [ ] Check notification tray periodically
- [ ] **Expected:** Notification persists entire time
- [ ] Return to app after 5 minutes
- [ ] **Expected:** Task still active, duration timer updated

**Pass Criteria:**
- Notification visible after 5+ minutes backgrounded
- No system notification about "app running in background"
- Duration timer continues counting
- Android doesn't kill notification

---

## Test Suite 4: Notification Dismissal Prevention

### Test 4.1: Swipe-Away Prevention
**Goal:** Verify notification cannot be dismissed by swipe

- [ ] With task active and notification showing
- [ ] Open notification tray
- [ ] Attempt to swipe notification away
- [ ] **Expected:** Notification resists dismissal (stays in "Ongoing" section)
- [ ] Try long-press → "Remove notification"
- [ ] **Expected:** No dismiss option available, or dismiss doesn't remove it

**Pass Criteria:**
- Notification cannot be swiped away
- Notification stays in "Ongoing" section
- Only way to remove is completing task in app

---

## Test Suite 5: Task Completion Flow

### Test 5.1: Complete Task via Banner
**Goal:** Verify completing task removes notification

- [ ] With task active and notification showing
- [ ] In app, tap "Complete" button in banner
- [ ] **Expected:** Banner disappears from app
- [ ] Pull down notification tray
- [ ] **Expected:** Notification no longer present
- [ ] Verify no "ghost" notifications remain

**Pass Criteria:**
- Task banner disappears immediately
- Notification removed from system tray
- No duplicate or leftover notifications

### Test 5.2: Create Second Task After Completion
**Goal:** Verify notification updates for new task

- [ ] After completing first task
- [ ] Create new task: "Test Task 2"
- [ ] **Expected:** New notification appears with new task title
- [ ] Verify only one notification present (no duplicates)
- [ ] Complete this task
- [ ] **Expected:** Notification removed again

**Pass Criteria:**
- New task triggers new notification
- No duplicate notifications
- Notification correctly updates with new task details

---

## Test Suite 6: Multiple Tasks Behavior

### Test 6.1: Task List Filtering
**Goal:** Verify current task doesn't appear in list view

- [ ] Create first task
- [ ] Navigate to Tasks screen
- [ ] **Expected:** Current task shown in banner, NOT in list
- [ ] Create second task (first still active)
- [ ] **Expected:** Only first task in banner, second in list
- [ ] Create third task
- [ ] **Expected:** First task in banner, second and third in list

**Pass Criteria:**
- Current task never duplicated in list
- Incomplete tasks show correctly in list
- Completed tasks removed from list

---

## Test Suite 7: Edge Cases & Error Handling

### Test 7.1: Permission Denied Flow
**Goal:** Verify app handles denied permissions gracefully

- [ ] Uninstall app
- [ ] Reinstall and deny permission when prompted
- [ ] **Expected:** App continues to function
- [ ] Create task
- [ ] **Expected:** No notification appears, but banner works
- [ ] Note: Check if app provides way to re-request permission

### Test 7.2: App Force Stop Recovery
**Goal:** Verify notification behavior after force stop

- [ ] With task active and notification showing
- [ ] Go to Settings → Apps → Synapse Runner
- [ ] Force Stop the app
- [ ] Check notification tray
- [ ] **Expected:** Notification likely disappears (Android limitation)
- [ ] Reopen app
- [ ] **Expected:** Task still active in database, notification recreates

---

## Test Suite 8: Performance & Battery

### Test 8.1: Battery Drain Check
**Goal:** Verify app doesn't cause excessive battery drain

- [ ] Fully charge device
- [ ] Create task and background app
- [ ] Leave device for 1 hour with task active
- [ ] Check battery usage: Settings → Battery → App usage
- [ ] **Expected:** Synapse Runner uses <2% battery per hour
- [ ] Check for "running in background" warnings

**Pass Criteria:**
- Battery drain <2% per hour
- No "high battery usage" warnings from system
- App not in "restricted" or "optimized" battery mode

---

## Critical Bugs to Watch For

### High Priority Issues
- [ ] Notification doesn't appear at all
- [ ] Notification appears but disappears when app backgrounded
- [ ] Multiple duplicate notifications
- [ ] App crashes when creating task
- [ ] Permission request never appears
- [ ] Task banner shows wrong task

### Medium Priority Issues
- [ ] Notification shows stale data after task update
- [ ] Duration timer doesn't update
- [ ] Notification not in "Ongoing" section (dismissible)
- [ ] Lag when switching between app and background

### Low Priority Issues
- [ ] Notification icon not displaying correctly
- [ ] Text overflow in notification
- [ ] Banner styling issues

---

## Logcat Monitoring

### Key Error Patterns to Watch For
```bash
# Run in separate terminal while testing
adb logcat | grep -E "ERROR|FATAL|exception|permission|notification"

# Specific patterns indicating issues:
# - "Permission denied" → Permission handling broken
# - "NotificationChannel not found" → Channel creation failed
# - "SecurityException" → Missing manifest permissions
# - "NullPointerException" → State management bug
```

---

## Test Results Summary

### Test Date: _____________
### Device: _____________
### Android Version: _____________

| Test Suite | Pass | Fail | Notes |
|------------|------|------|-------|
| 1. Installation & Permissions | ☐ | ☐ | |
| 2. Task Creation | ☐ | ☐ | |
| 3. Notification Persistence | ☐ | ☐ | |
| 4. Dismissal Prevention | ☐ | ☐ | |
| 5. Task Completion | ☐ | ☐ | |
| 6. Multiple Tasks | ☐ | ☐ | |
| 7. Edge Cases | ☐ | ☐ | |
| 8. Performance | ☐ | ☐ | |

**Overall Sprint 1 Status:** ☐ PASS ☐ FAIL

---

## Known Limitations

### Android System Constraints
- **Force Stop:** Android always kills notifications when app force-stopped (expected behavior)
- **Battery Optimization:** Aggressive battery savers may still kill notifications on some devices
- **Android Versions:** Behavior may vary between Android 10, 11, 12, 13, 14
- **OEM Modifications:** Samsung, Xiaomi, etc. may have custom restrictions

### Expected Workarounds Needed
- Users may need to disable battery optimization for app
- Some devices require "Autostart" permission
- Notification settings must allow app to show persistent notifications

---

## Next Steps After Testing

### If All Tests Pass ✅
1. Mark Sprint 1 as COMPLETE
2. Commit all changes to git
3. Update dev session document with test results
4. Proceed to Sprint 2 (Medication Tracker)

### If Tests Fail ❌
1. Document specific failing tests
2. Investigate logs for root cause
3. Fix issues and re-test
4. Consider filing issues in planning docs for tracking

---

**Remember:** The goal is persistent, non-dismissible notifications that survive app backgrounding. This is critical for the ADHD use case ("Interrupt me BEFORE I fuck up"). If notifications don't persist, the entire feature fails its purpose.
