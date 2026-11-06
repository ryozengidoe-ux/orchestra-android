#!/usr/bin/env bash
# Smoke-test for the CI emulator run. Runs on the GitHub runner (not in the
# emulator) with adb on PATH. Called as one line from ci.yml because the
# emulator-runner action executes every script line with a separate
# `/usr/bin/sh -c`, which breaks multi-line for/if constructs.
set -u

adb install app/build/outputs/apk/debug/app-debug.apk
adb shell am start -n ai.neurosignal.orchestra/.MainActivity

# NOTE: mCurrentFocus lives in plain `dumpsys window` output, NOT in
# `dumpsys window windows` (that lists WindowState entries only) — the
# latter returns empty on API 35 and the check fails 6 times in a row
# (run #11). Keep the plain form.
FOCUS=""
for i in 1 2 3 4 5 6; do
  sleep 5
  FOCUS=$(adb shell dumpsys window | grep -iE "mCurrentFocus|mFocusedApp" || true)
  echo "focus: $FOCUS"
  echo "$FOCUS" | grep -q "ai.neurosignal.orchestra" && break
done

# If the activity never came to the foreground, show what the device is
# actually doing (crash? wrong window?) before failing, and grab a
# screenshot anyway so the artifact shows the screen.
if ! echo "$FOCUS" | grep -q "ai.neurosignal.orchestra"; then
  echo "--- dumpsys window (first 40 lines) ---"
  adb shell dumpsys window | head -40 || true
  echo "--- resumed activity ---"
  adb shell dumpsys activity activities | grep -iE "mResumedActivity|mFocusedApp" || true
  echo "--- logcat (app + crashes) ---"
  adb logcat -d | grep -iE "FATAL EXCEPTION|ai.neurosignal.orchestra|AndroidRuntime" | tail -40 || true
  adb exec-out screencap -p > screenshot.png || true
  echo "APP NOT IN FOREGROUND"
  exit 1
fi

if adb logcat -d | grep -q "FATAL EXCEPTION"; then
  echo "CRASH FOUND:"
  adb logcat -d | grep -i "FATAL EXCEPTION"
  exit 1
fi

adb exec-out screencap -p > screenshot.png
ls -la screenshot.png
