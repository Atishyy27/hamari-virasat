#!/usr/bin/env bash
# Read-only: measures how fast the Gradle 9.3.1 download is going and what is already cached,
# so the ETA is a number and not a guess. Kills nothing. No set -e (runlog.sh rule).
RL_NAME=virasat-gradle-speed
source "$HOME/Desktop/codes_masti/masti/cnc/runlog.sh"

DIST="$HOME/.gradle/wrapper/dists/gradle-9.3.1-all"
URL="https://services.gradle.org/distributions/gradle-9.3.1-all.zip"

rl_step "full size of the zip (HEAD request, IPv4)"
rl_run sh -c 'curl -4 -sIL --max-time 20 "$1" | grep -i -E "^HTTP|content-length"' _ "$URL"

rl_step "download speed over 20 seconds"
PART="$(find "$DIST" -name '*.zip.part' 2>/dev/null | head -1)"
if [ -z "$PART" ]; then
  rl_say "no .part file: the download has finished or never started"
  rl_run sh -c 'find "$1" -maxdepth 3 2>&1 | head -20' _ "$DIST"
else
  S1="$(stat -f %z "$PART")"
  rl_say "bytes now: $S1"
  sleep 20
  S2="$(stat -f %z "$PART" 2>/dev/null || echo "$S1")"
  rl_say "bytes after 20s: $S2"
  rl_say "speed: $(( (S2 - S1) / 20 / 1024 )) KB/s, downloaded so far: $(( S2 / 1024 / 1024 )) MB"
fi

rl_step "plain network speed for comparison (5 MB test file, IPv4)"
rl_run sh -c 'curl -4 -s -o /dev/null --max-time 20 -w "http=%{http_code} speed=%{speed_download} bytes/s time=%{time_total}s\n" https://speed.cloudflare.com/__down?bytes=5000000'

rl_step "what is already in the gradle cache (decides whether an offline-ish build is possible)"
rl_run sh -c 'ls "$HOME/.gradle/caches/modules-2/files-2.1/com.android.tools.build/gradle" 2>&1'
rl_run sh -c 'ls "$HOME/.gradle/caches/modules-2/files-2.1/org.jetbrains.kotlin/kotlin-gradle-plugin" 2>&1'

rl_finish
