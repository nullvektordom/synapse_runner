# Setup ADB and Diagnose Notification Issue

## Step 1: Install ADB (Android Debug Bridge)

ADB is required to diagnose why the notification is still dismissible.

### On Fedora (your system):

```bash
sudo dnf install android-tools
```

**Alternative:** Download Android Platform Tools directly:
```bash
cd ~/Downloads
wget https://dl.google.com/android/repository/platform-tools-latest-linux.zip
unzip platform-tools-latest-linux.zip
sudo mv platform-tools/adb /usr/local/bin/
sudo chmod +x /usr/local/bin/adb
```

### Verify ADB is installed:

```bash
adb --version
```

Should show something like: `Android Debug Bridge version 1.0.41`

---

## Step 2: Connect Your Device

1. **Enable Developer Options** on your Pixel 8 Pro:
   - Settings → About phone → Tap "Build number" 7 times
   - You'll see "You are now a developer!"

2. **Enable USB Debugging:**
   - Settings → System → Developer options
   - Toggle "USB debugging" ON

3. **Connect via USB cable**

4. **Authorize the computer:**
   - Your phone will show a popup: "Allow USB debugging?"
   - Check "Always allow from this computer"
   - Tap "Allow"

5. **Verify connection:**
   ```bash
   adb devices
   ```

   Should show:
   ```
   List of devices attached
   ABC123XYZ    device
   ```

---

## Step 3: Run the Diagnostic Script

With your device connected and the app running with an active task:

```bash
cd ~/repos/synapse_runner
./diagnose_notification.sh
```

This will check:
- ✅ Is the foreground service actually running?
- ✅ What are the notification flags?
- ✅ Are permissions granted?
- ✅ What Android version and device you're using?

**Save the output** - it will tell us exactly why the notification is dismissible.

---

## Step 4: Quick Test Procedure

Once ADB is set up:

1. **Uninstall old version** (to reset notification channel):
   ```bash
   adb uninstall com.example.synapse_runner
   ```

2. **Fresh install:**
   ```bash
   cd ~/repos/synapse_runner
   flutter run
   ```

3. **Create a task** in the app

4. **Try to swipe notification away**

5. **Run diagnostic:**
   ```bash
   ./diagnose_notification.sh
   ```

6. **Share the output** with me

---

## What the Diagnostic Will Tell Us

### If Service is Running ✅

```
✅ TaskForegroundService IS RUNNING
✅ FLAG_ONGOING_EVENT is set (non-dismissible)
✅ FLAG_NO_CLEAR is set (can't clear all)
```

**But you can still swipe away?**
→ This is an Android OS or OEM limitation we can't override

### If Service is NOT Running ❌

```
❌ TaskForegroundService NOT RUNNING
```

**This means:**
- Method channel isn't working
- Service is crashing on start
- Permissions issue

We can fix this!

### If Flags are Wrong ❌

```
❌ FLAG_ONGOING_EVENT is NOT set (can be dismissed!)
```

**This means:**
- Notification channel was modified by user
- Service update method broke flags

We can fix this!

---

## Common Issues and Fixes

### Issue: "adb: command not found"
**Fix:** Complete Step 1 above

### Issue: "adb devices" shows empty list
**Fix:**
- Check USB cable is connected
- Enable USB debugging (Step 2)
- Authorize computer on phone
- Try: `adb kill-server && adb start-server`

### Issue: "unauthorized" in device list
**Fix:**
- Disconnect and reconnect USB
- Check phone for authorization popup
- Try different USB cable/port

### Issue: Multiple devices listed
**Fix:**
```bash
# Specify device explicitly
adb -s <DEVICE_ID> shell dumpsys activity services
```

---

## Expected Results After Fix

Once we identify the issue and apply the fix:

**Pixel 8 Pro (Android 14):**
- ✅ Notification in "Ongoing" section
- ✅ Cannot be swiped away
- ✅ Small lock icon indicating it's protected
- ✅ "Clear all" button doesn't affect it

**How it should look:**

```
┌─────────────────────────────────────┐
│ Ongoing                             │
├─────────────────────────────────────┤
│ 🎯 Current Task: Buy groceries  🔒  │
│ Milk, eggs, bread                   │
│ ⏱️ Running for 5 min                │
└─────────────────────────────────────┘
```

The 🔒 icon indicates it's a foreground service notification that can't be dismissed.

---

## Next Steps

After you run the diagnostic, we'll know exactly what's happening:

1. **Service running + flags set** → Android OS/OEM limitation (we can document workarounds)
2. **Service not running** → Fix method channel or service startup
3. **Flags not set** → Fix notification build process or channel reset needed

Please run through Steps 1-3 and share the diagnostic output!
