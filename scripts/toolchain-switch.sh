#!/usr/bin/env bash
# Stops the stuck build and points the Android project at the toolchain already on this Mac
# (Gradle 8.14.3, Android Gradle Plugin 8.13.1, Kotlin 2.3.20) so nothing big has to download.
# Originals are kept next to each file as *.agp9.bak. No set -e (runlog.sh rule).
RL_NAME=virasat-toolchain-switch
source "$HOME/Desktop/codes_masti/masti/cnc/runlog.sh"

AND="$HOME/Desktop/codes_masti/masti/projects/hamari-virasat/app/android"
WRAP="$AND/gradle/wrapper/gradle-wrapper.properties"
SET="$AND/settings.gradle.kts"
APPG="$AND/app/build.gradle.kts"

rl_step "the cached toolchain is really there"
rl_run sh -c 'find "$HOME/.gradle/wrapper/dists/gradle-8.14.3-all" -maxdepth 2 2>&1 | head -10'
rl_check "gradle 8.14.3 unpacked (.ok marker)" sh -c 'find "$HOME/.gradle/wrapper/dists/gradle-8.14.3-all" -maxdepth 2 -name "*.ok" | grep -q .'
rl_check "android plugin 8.13.1 cached" test -d "$HOME/.gradle/caches/modules-2/files-2.1/com.android.tools.build/gradle/8.13.1"
rl_check "kotlin plugin 2.3.20 cached" test -d "$HOME/.gradle/caches/modules-2/files-2.1/org.jetbrains.kotlin/kotlin-gradle-plugin/2.3.20"

rl_step "stop the build that is stuck downloading gradle 9.3.1"
rl_run sh -c 'ps -axo pid,etime,command | grep "hamari-virasat/app/android" | grep -v grep | cut -c1-160; true'
rl_run sh -c 'pkill -f "hamari-virasat/app/android"; true'
sleep 4
rl_run sh -c 'ps -axo pid,etime,command | grep "hamari-virasat/app/android" | grep -v grep | cut -c1-160; true'

rl_step "back up the three files (first run only)"
for f in "$WRAP" "$SET" "$APPG"; do
  if [ -f "$f.agp9.bak" ]; then rl_say "backup exists: $f.agp9.bak"; else rl_run cp "$f" "$f.agp9.bak"; fi
done

rl_step "switch versions"
rl_run sed -i '' 's/gradle-9\.3\.1-all\.zip/gradle-8.14.3-all.zip/' "$WRAP"
rl_run sed -i '' -e 's/id("com.android.application") version "9\.1\.0"/id("com.android.application") version "8.13.1"/' -e 's/id("org.jetbrains.kotlin.android") version "2\.4\.0"/id("org.jetbrains.kotlin.android") version "2.3.20"/' "$SET"
if grep -q 'id("kotlin-android")' "$APPG"; then
  rl_say "kotlin-android already applied"
else
  rl_run perl -0pi -e 's/id\("com\.android\.application"\)\n/id("com.android.application")\n    id("kotlin-android")\n/' "$APPG"
fi

rl_step "result"
rl_run cat "$WRAP"
rl_run grep -n "version" "$SET"
rl_run sed -n '1,7p' "$APPG"
rl_check "wrapper on 8.14.3" grep -q "gradle-8.14.3-all.zip" "$WRAP"
rl_check "android plugin on 8.13.1" grep -q '"8.13.1"' "$SET"
rl_check "kotlin on 2.3.20" grep -q '"2.3.20"' "$SET"
rl_check "kotlin-android applied" grep -q 'id("kotlin-android")' "$APPG"

rl_finish
