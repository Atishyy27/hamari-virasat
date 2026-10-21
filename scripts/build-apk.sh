#!/usr/bin/env bash
# Builds the Hamari Virasat demo APK (debug build, local on-device data unless Supabase keys are given).
# Usage: bash scripts/build-apk.sh
#   real backend: SUPABASE_URL=... SUPABASE_ANON_KEY=... bash scripts/build-apk.sh
# No set -e (runlog.sh rule). First run is the test.
RL_NAME=virasat-build-apk
source "$HOME/Desktop/codes_masti/masti/cnc/runlog.sh"

ROOT="$HOME/Desktop/codes_masti/masti/projects/hamari-virasat"
APP="$ROOT/app"
OUT="$HOME/Desktop/hamari-virasat-demo.apk"

rl_step "toolchain"
rl_check "flutter on PATH" command -v flutter
rl_run flutter --version
rl_check "app sources present" test -f "$APP/lib/main.dart"
rl_check "pubspec present" test -f "$APP/pubspec.yaml"
rl_run find "$APP/lib" -type f -name '*.dart'

rl_step "android scaffold (only when missing)"
if [ -d "$APP/android" ]; then
  rl_say "android/ already there, skipping flutter create"
else
  TMP="$(mktemp -d)"
  rl_run flutter create --platforms=android --project-name hamari_virasat --org in.hamarivirasat "$TMP/hamari_virasat"
  rl_run cp -R "$TMP/hamari_virasat/android" "$APP/android"
  rl_run cp "$TMP/hamari_virasat/.metadata" "$APP/.metadata"
  rl_run cp "$TMP/hamari_virasat/analysis_options.yaml" "$APP/analysis_options.yaml"
  rl_run cp "$TMP/hamari_virasat/.gitignore" "$APP/.gitignore"
  rl_run rm -rf "$TMP"
fi
rl_check "android/ present" test -d "$APP/android"

cd "$APP" || rl_log ERROR "cannot cd to $APP"

rl_step "dependencies (pub resolves the versions, none are hand-written)"
for pkg in supabase_flutter shared_preferences file_picker; do
  if grep -q "^  $pkg:" pubspec.yaml; then
    rl_say "$pkg already in pubspec"
  else
    rl_run flutter pub add "$pkg"
  fi
done
rl_run flutter pub get
rl_run grep -E "^  (supabase_flutter|shared_preferences|file_picker):" pubspec.yaml

rl_step "static analysis"
rl_run flutter analyze

# MODE=release builds a small arm64 apk to send out; default is the big debug apk.
MODE="${MODE:-debug}"
rl_step "build $MODE apk"
if [ "$MODE" = "release" ]; then
  BUILD_ARGS="--release --target-platform android-arm64"
  APK="$APP/build/app/outputs/flutter-apk/app-release.apk"
  OUT="$HOME/Desktop/hamari-virasat.apk"
else
  BUILD_ARGS="--debug"
  APK="$APP/build/app/outputs/flutter-apk/app-debug.apk"
fi
if [ -n "${SUPABASE_URL:-}" ] && [ -n "${SUPABASE_ANON_KEY:-}" ]; then
  rl_say "building against Supabase"
  rl_run flutter build apk $BUILD_ARGS "--dart-define=SUPABASE_URL=$SUPABASE_URL" "--dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY"
else
  rl_say "no Supabase keys given: building with on-device demo data"
  rl_run flutter build apk $BUILD_ARGS
fi

rl_step "hand over the apk"
rl_check "apk was built" test -f "$APK"
rl_run cp "$APK" "$OUT"
rl_run ls -l "$OUT"

rl_finish
