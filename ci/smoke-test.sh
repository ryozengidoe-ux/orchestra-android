#!/usr/bin/env bash
# Smoke-test for the CI emulator run. Runs on the GitHub runner (not in the
# emulator) with adb on PATH. Called as one line from ci.yml because the
# emulator-runner action executes every script line with a separate
# `/usr/bin/sh -c`, which breaks multi-line for/if constructs.
set -u

adb install app/build/outputs/apk/debug/app-debug.apk
adb shell am start -n ai.neurosignal.orchestra/.MainActivity

FOCUS=""
for i in 1 2 3 4 5 6; do
  sleep 5
  FOCUS=$(adb shell dumpsys window windows | grep -i mCurrentFocus || true)
  echo "focus: $FOCUS"
  echo "$FOCUS" | grep -q "ai.neurosignal.orchestra" && break
done
echo "$FOCUS" | grep -q "ai.neurosignal.orchestra" || { echo "APP NOT IN FOREGROUND"; exit 1; }

if adb logcat -d | grep -q "FATAL EXCEPTION"; then
  echo "CRASH FOUND:"
  adb logcat -d | grep -i "FATAL EXCEPTION"
  exit 1
fi

adb exec-out screencap -p > screenshot.png
ls -la screenshot.png
