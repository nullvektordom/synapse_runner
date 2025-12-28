# Troubleshooting: Notification Still Dismissible

## Latest Changes Applied

### Critical Notification Flags Added
**File:** `TaskForegroundService.kt:148`

```kotlin
return builder.build().apply {
    flags = flags or Notification.FLAG_ONGOING_EVENT or Notification.FLAG_NO_CLEAR
}
```

**What These Do:**
- `FLAG_ONGOING_EVENT` - Marks notification as ongoing (goes to "Ongoing" section)
- `FLAG_NO_CLEAR` - **CRITICAL** - Prevents the "Clear all" button from removing it
- Combined with `setOngoing(true)` in builder for double protection

### Other Changes
1. **Channel Importance:** Changed from DEFAULT → **HIGH**
2. **Notification Priority:** Changed from DEFAULT → **MAX**
3. **Service Type:** Explicitly set `FOREGROUND_SERVICE_TYPE_SPECIAL_USE` on Android 10+

## If Still Dismissible - Diagnostic Steps

### Step 1: Verify Service is Running

```bash
# Connect device
adb devices

# Check if service is actually running
adb shell dumpsys activity services | grep TaskForeground

# Expected output:
# ServiceRecord{...TaskForegroundService}
# app=ProcessRecord{...com.example.synapse_runner}
# isForeground=true
```

**If service NOT running:**
- Check logcat for errors during service start
- Verify permissions in AndroidManifest.xml
- Check if app has foreground service permission

### Step 2: Check Notification Flags

```bash
# Dump notification info
adb shell dumpsys notification | grep -A 20 "synapse_runner"

# Look for:
# flags=0x62  (or similar - should include FLAG_ONGOING_EVENT)
# ongoing=true
```

**If flags are wrong:**
- Notification might be created before service starts
- Check that `startForeground()` is called, not `notify()`

### Step 3: Check Android Version Behavior

Different Android versions have different behaviors:

| Android Version | Expected Behavior | Known Issues |
|-----------------|-------------------|--------------|
| Android 14+ | Non-dismissible in Ongoing section | None known |
| Android 12-13 | Non-dismissible in Ongoing section | Some OEMs allow swipe |
| Android 10-11 | Should be non-dismissible | Samsung may allow dismiss |
| Android 8-9 | Non-dismissible | Rare OEM issues |

**Check your Android version:**
```bash
adb shell getprop ro.build.version.release
```

### Step 4: Check Notification Channels

User can modify notification channels after first creation!

```bash
# Check channel settings
adb shell cmd notification get_channel com.example.synapse_runner task_foreground_service

# Look for:
# importance=3 (IMPORTANCE_HIGH)
# user_locked_fields=0 (user hasn't modified)
```

**If user modified channel:**
User may have downgraded importance in Settings → Apps → Synapse Runner → Notifications

**Fix:** Uninstall and reinstall app to reset channel
```bash
adb uninstall com.example.synapse_runner
flutter run
```

### Step 5: OEM-Specific Issues

Some device manufacturers modify Android notification behavior:

**Samsung:**
- Has "App power management" that can kill services
- Go to: Settings → Apps → Synapse Runner → Battery → Unrestricted

**Xiaomi/MIUI:**
- Has aggressive "Battery Saver"
- Settings → Apps → Manage apps → Synapse Runner → Autostart: ON
- Settings → Battery → App battery saver → Synapse Runner → No restrictions

**OnePlus/Oppo:**
- "Battery optimization" can kill foreground services
- Settings → Battery → Battery optimization → Synapse Runner → Don't optimize

**Huawei:**
- "Power Genie" kills background apps
- Settings → Battery → App launch → Synapse Runner → Manage manually → Enable all

### Step 6: Check App Permissions

```bash
# Check granted permissions
adb shell dumpsys package com.example.synapse_runner | grep permission

# Should include:
# android.permission.FOREGROUND_SERVICE: granted=true
# android.permission.POST_NOTIFICATIONS: granted=true
```

**If permissions not granted:**
```bash
# Grant manually via ADB
adb shell pm grant com.example.synapse_runner android.permission.POST_NOTIFICATIONS
```

### Step 7: Logcat Debugging

```bash
# Monitor logs while creating task
adb logcat -c  # Clear logs
adb logcat | grep -E "TaskForeground|Notification|synapse"

# Look for errors like:
# - "SecurityException" → Missing permissions
# - "IllegalArgumentException" → Invalid service type
# - "RemoteException" → System rejected notification
```

## Nuclear Option: Verify with System App

Test if ANY app can create non-dismissible notifications on your device:

```bash
# Start a fake foreground service (requires root)
adb shell am start-foreground-service -a android.intent.action.MAIN

# Or test with built-in apps
# Play a music file in background → notification should be non-dismissible
```

**If system apps CAN'T create non-dismissible notifications:**
- Your Android version/OEM has modified this behavior
- No app-level fix possible
- This is an Android OS limitation

## Alternative Approaches

### Option 1: Re-post Notification on Dismiss
Monitor notification dismissal and immediately re-post it:

```kotlin
// In MainActivity.kt method channel
override fun onNotificationRemoved(statusBarNotification: StatusBarNotification) {
    // Re-create notification immediately
    ForegroundService.startService(...)
}
```

**Pros:** Works on all devices
**Cons:** User sees brief flicker, annoying UX

### Option 2: Lower Expectations
Document that on some devices, notification may be dismissible due to OEM modifications:

> "Note: Some device manufacturers (Samsung, Xiaomi) allow dismissing foreground service notifications. If this happens, complete your task in the app to remove the notification properly."

### Option 3: Use Accessibility Service
Android Accessibility Services have special privileges:

```xml
<service android:name=".TaskAccessibilityService"
    android:permission="android.permission.BIND_ACCESSIBILITY_SERVICE">
    ...
</service>
```

**Pros:** Can detect notification dismissal and re-post
**Cons:** Requires separate permission, complex setup

## What Android Version Are You Testing On?

Please run:
```bash
adb shell getprop ro.build.version.release  # Android version
adb shell getprop ro.product.manufacturer   # Device manufacturer
adb shell getprop ro.product.model          # Device model
```

And check:
1. Is the service actually running? (Step 1)
2. What are the notification flags? (Step 2)
3. Has the user modified the notification channel? (Step 4)

## Expected Results After This Fix

With `FLAG_NO_CLEAR` and `FLAG_ONGOING_EVENT` explicitly set:

**Android 14:**
- ✅ Should be completely non-dismissible
- ✅ Shows in "Ongoing" section with lock icon
- ✅ Swipe does nothing

**Android 12-13:**
- ✅ Should be non-dismissible
- ⚠️ Some Samsung devices may still allow (OS bug)

**Android 10-11:**
- ✅ Should be non-dismissible
- ⚠️ Xiaomi/MIUI may need battery optimization disabled

**Android 8-9:**
- ✅ Should be non-dismissible
- ✅ No known issues

If still dismissible after this fix, it's likely an OEM modification to Android that we cannot override at the app level.
