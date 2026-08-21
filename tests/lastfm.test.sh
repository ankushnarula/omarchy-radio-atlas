#!/usr/bin/env bash
set -euo pipefail

project_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
test_root=$(mktemp -d)
trap 'rm -rf "$test_root"' EXIT
export XDG_CONFIG_HOME="$test_root/config"

# Missing credentials deliberately disable the optional integration.
"$project_dir/radio-lastfm" resolve "Artist" "Track"

mkdir -p "$XDG_CONFIG_HOME/radio-atlas"
config_file="$XDG_CONFIG_HOME/radio-atlas/lastfm.conf"
printf '%s\n' \
  'LASTFM_API_KEY=0123456789abcdef' \
  'LASTFM_API_SECRET=abcdef0123456789' \
  'LASTFM_SESSION_KEY=0123456789abcdef' > "$config_file"
chmod 644 "$config_file"
if "$project_dir/radio-lastfm" resolve "Artist" "Track" >/dev/null 2>&1; then
  echo 'Last.fm accepted a world-readable config' >&2
  exit 1
fi

chmod 600 "$config_file"
mkdir "$test_root/bin"
ln -s "$project_dir/tests/fixtures/lastfm-curl" "$test_root/bin/curl"
ln -s "$project_dir/tests/fixtures/lastfm-logger" "$test_root/bin/logger"
export LASTFM_CURL_LOG="$test_root/curl.log"
export LASTFM_LOGGER_LOG="$test_root/logger.log"

resolved=$(PATH="$test_root/bin:$PATH" "$project_dir/radio-lastfm" \
  resolve "Stream Artist" "Stream Track")
jq -e '
  .artist == "Canonical Artist"
  and .track == "Canonical Track"
  and .mbid == "01234567-89ab-cdef-0123-456789abcdef"
  and .durationMs == 202000
' <<< "$resolved" >/dev/null

PATH="$test_root/bin:$PATH" "$project_dir/radio-lastfm" \
  now-playing "Canonical Artist" "Canonical Track" \
  "01234567-89ab-cdef-0123-456789abcdef" 202 >/dev/null
PATH="$test_root/bin:$PATH" "$project_dir/radio-lastfm" \
  scrobble "Canonical Artist" "Canonical Track" \
  "01234567-89ab-cdef-0123-456789abcdef" 202 1700000000 >/dev/null

rg -Fq 'artist=Canonical Artist' "$LASTFM_CURL_LOG"
rg -Fq 'track=Canonical Track' "$LASTFM_CURL_LOG"
rg -Fq 'duration=202' "$LASTFM_CURL_LOG"
rg -Fq 'mbid=01234567-89ab-cdef-0123-456789abcdef' "$LASTFM_CURL_LOG"
! rg -Fq 'album=' "$LASTFM_CURL_LOG"

if LASTFM_TEST_IGNORE=1 PATH="$test_root/bin:$PATH" \
  "$project_dir/radio-lastfm" scrobble "Canonical Artist" "Canonical Track" \
  "01234567-89ab-cdef-0123-456789abcdef" 202 1700000000 >/dev/null 2>&1; then
  echo 'Last.fm reported an ignored scrobble as accepted' >&2
  exit 1
fi

rg -Fq 'scrobble accepted: Canonical Artist — Canonical Track' "$LASTFM_LOGGER_LOG"
rg -Fq 'scrobble ignored (2): Canonical Artist — Canonical Track' "$LASTFM_LOGGER_LOG"
