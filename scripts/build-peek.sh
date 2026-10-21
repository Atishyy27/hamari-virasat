#!/usr/bin/env bash
# Read-only look at a running APK build: what Gradle is doing, how much it has downloaded,
# how much disk is left. Kills nothing, changes nothing. No set -e (runlog.sh rule).
RL_NAME=virasat-build-peek
source "$HOME/Desktop/codes_masti/masti/cnc/runlog.sh"

APP="$HOME/Desktop/codes_masti/masti/projects/hamari-virasat/app"

rl_step "build processes (gradle, java, flutter)"
rl_run sh -c 'ps -axo pid,etime,pcpu,rss,command | grep -E "gradle|GradleDaemon|flutter_tools|kotlin" | grep -v grep | cut -c1-220'

rl_step "disk and load"
rl_run df -h /
rl_run uptime

rl_step "gradle downloads so far"
rl_run sh -c 'du -sh "$HOME/.gradle" "$HOME/.gradle/wrapper/dists" "$HOME/.gradle/caches" 2>&1'
rl_run sh -c 'ls -lt "$HOME/.gradle/wrapper/dists" 2>&1 | head -5'
rl_run sh -c 'find "$HOME/.gradle" -type f -mmin -2 2>/dev/null | head -15'
rl_run sh -c 'find "$HOME/.gradle" -type f \( -name "*.part" -o -name "*.lck" \) -mmin -30 2>/dev/null | head -10'

rl_step "android sdk pieces present"
rl_run sh -c 'ls "$HOME/Library/Android/sdk" "$HOME/Library/Android/sdk/platforms" "$HOME/Library/Android/sdk/build-tools" "$HOME/Library/Android/sdk/ndk" 2>&1'

rl_step "build output so far"
rl_run sh -c 'du -sh "$1/build" "$1/android/.gradle" 2>&1' _ "$APP"
rl_run sh -c 'find "$1/build" -type f -mmin -2 2>/dev/null | head -10' _ "$APP"
rl_run sh -c 'find "$1/build" -name "*.apk" 2>/dev/null' _ "$APP"

rl_finish
