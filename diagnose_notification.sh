#!/bin/bash
# Diagnostic script for notification dismissal issue
# Run this while the app is running with a task created

echo "=========================================="
echo "Synapse Runner Notification Diagnostics"
echo "=========================================="
echo ""

# Check if ADB is available
if ! command -v adb &> /dev/null; then
    echo "❌ ADB not found!"
    echo ""
    echo "To install ADB on Fedora, run:"
    echo "  sudo dnf install android-tools"
    echo ""
    echo "Or download from: https://developer.android.com/tools/releases/platform-tools"
    echo ""
    exit 1
fi

echo "✅ ADB found at: $(which adb)"
echo ""

# Check device connection
echo "Checking device connection..."
DEVICE_COUNT=$(adb devices | grep -v "List" | grep "device$" | wc -l)

if [ "$DEVICE_COUNT" -eq 0 ]; then
    echo "❌ No device connected!"
    echo ""
    echo "Please:"
    echo "1. Connect your Pixel 8 Pro via USB"
    echo "2. Enable USB debugging in Developer Options"
    echo "3. Authorize the computer when prompted on phone"
    echo ""
    adb devices
    exit 1
fi

echo "✅ Device connected:"
adb devices | grep "device$"
echo ""

# Get device info
echo "Device Information:"
echo "-------------------"
ANDROID_VERSION=$(adb shell getprop ro.build.version.release)
MANUFACTURER=$(adb shell getprop ro.product.manufacturer)
MODEL=$(adb shell getprop ro.product.model)
SDK_VERSION=$(adb shell getprop ro.build.version.sdk)

echo "  Android Version: $ANDROID_VERSION (SDK $SDK_VERSION)"
echo "  Manufacturer: $MANUFACTURER"
echo "  Model: $MODEL"
echo ""

# Check if app is installed
echo "Checking if Synapse Runner is installed..."
if adb shell pm list packages | grep -q "com.example.synapse_runner"; then
    echo "✅ App installed"
else
    echo "❌ App not installed!"
    echo "  Run: flutter run"
    exit 1
fi
echo ""

# Check foreground service status
echo "Checking Foreground Service Status:"
echo "------------------------------------"
SERVICE_INFO=$(adb shell dumpsys activity services com.example.synapse_runner 2>/dev/null | grep -A 10 "TaskForegroundService")

if [ -z "$SERVICE_INFO" ]; then
    echo "❌ TaskForegroundService NOT RUNNING"
    echo ""
    echo "This means:"
    echo "  - No task is currently active, OR"
    echo "  - Service failed to start, OR"
    echo "  - Service was killed by system"
    echo ""
    echo "Try creating a task in the app and run this script again."
else
    echo "✅ TaskForegroundService IS RUNNING"
    echo ""
    echo "$SERVICE_INFO" | grep -E "isForeground|foregroundId|foregroundNotification" || echo "  (Service details not fully available)"
fi
echo ""

# Check notification status
echo "Checking Notification Status:"
echo "------------------------------"
NOTIF_INFO=$(adb shell dumpsys notification | grep -A 30 "com.example.synapse_runner")

if [ -z "$NOTIF_INFO" ]; then
    echo "❌ No active notifications found"
else
    echo "✅ Active notification found"
    echo ""

    # Extract key notification properties
    echo "Notification Properties:"
    echo "$NOTIF_INFO" | grep -E "flags=|ongoing=|priority=" | head -5

    # Check for FLAG_ONGOING_EVENT (0x20) and FLAG_NO_CLEAR (0x20)
    FLAGS=$(echo "$NOTIF_INFO" | grep "flags=" | head -1 | sed 's/.*flags=\([^ ]*\).*/\1/')
    if [ ! -z "$FLAGS" ]; then
        echo ""
        echo "  Raw flags value: $FLAGS"

        # Convert hex to decimal if needed and check flags
        if [[ $FLAGS == 0x* ]]; then
            FLAGS_DEC=$((FLAGS))
        else
            FLAGS_DEC=$FLAGS
        fi

        # Check for FLAG_ONGOING_EVENT (0x20 = 32)
        if [ $((FLAGS_DEC & 32)) -ne 0 ]; then
            echo "  ✅ FLAG_ONGOING_EVENT is set (non-dismissible)"
        else
            echo "  ❌ FLAG_ONGOING_EVENT is NOT set (can be dismissed!)"
        fi

        # Check for FLAG_NO_CLEAR (0x20 = 32)
        if [ $((FLAGS_DEC & 32)) -ne 0 ]; then
            echo "  ✅ FLAG_NO_CLEAR is set (can't clear all)"
        else
            echo "  ❌ FLAG_NO_CLEAR is NOT set (can be cleared!)"
        fi
    fi
fi
echo ""

# Check permissions
echo "Checking App Permissions:"
echo "-------------------------"
PERMS=$(adb shell dumpsys package com.example.synapse_runner | grep -A 20 "declared permissions:")

if echo "$PERMS" | grep -q "POST_NOTIFICATIONS.*granted=true"; then
    echo "✅ POST_NOTIFICATIONS: granted"
else
    echo "❌ POST_NOTIFICATIONS: not granted"
fi

if echo "$PERMS" | grep -q "FOREGROUND_SERVICE.*granted=true"; then
    echo "✅ FOREGROUND_SERVICE: granted"
else
    echo "❌ FOREGROUND_SERVICE: not granted (this is normal - install time permission)"
fi
echo ""

# Check notification channel
echo "Checking Notification Channel:"
echo "-------------------------------"
CHANNEL_INFO=$(adb shell cmd notification get_channel com.example.synapse_runner task_foreground_service 2>/dev/null)

if [ -z "$CHANNEL_INFO" ]; then
    echo "⚠️  Channel not found or unable to query"
    echo "  (This is normal on some Android versions)"
else
    echo "$CHANNEL_INFO" | grep -E "importance|user_locked" || echo "  (Channel details not available)"
fi
echo ""

# Summary and recommendations
echo "=========================================="
echo "Summary & Recommendations"
echo "=========================================="
echo ""

if [ ! -z "$SERVICE_INFO" ]; then
    echo "✅ Service is running - notification should be non-dismissible"
    echo ""
    echo "If you can still swipe away the notification:"
    echo ""
    echo "1. Try uninstalling and reinstalling:"
    echo "   adb uninstall com.example.synapse_runner"
    echo "   flutter run"
    echo ""
    echo "2. Check notification settings on device:"
    echo "   Settings → Apps → Synapse Runner → Notifications"
    echo "   Ensure 'Current Task - ADHD Reminder' is enabled"
    echo ""
    echo "3. Disable battery optimization:"
    echo "   Settings → Apps → Synapse Runner → Battery → Unrestricted"
    echo ""
    echo "4. Android $ANDROID_VERSION on $MANUFACTURER $MODEL may have"
    echo "   custom notification behavior that overrides app settings."
    echo ""
else
    echo "⚠️  Service is NOT running"
    echo ""
    echo "Please:"
    echo "1. Open the app"
    echo "2. Navigate to 'Manage Tasks'"
    echo "3. Create a task"
    echo "4. Run this script again to verify service starts"
fi

echo "=========================================="
echo ""
echo "Save this output and share with developer if issue persists."
