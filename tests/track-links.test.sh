#!/usr/bin/env bash
set -euo pipefail

project_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
test_root=$(mktemp -d)
trap 'rm -rf "$test_root"' EXIT

ln -s "$project_dir/tests/fixtures/track-links-curl" "$test_root/curl"
links=$(PATH="$test_root:$PATH" "$project_dir/radio-track-links" \
  "The Human League" "Seconds")

jq -e '
  .spotify == "https://open.spotify.com/track/0ZkWMpB7PsswU8cAnkETRL?autoplay_ok=0"
  and .appleMusic == "https://music.apple.com/us/song/724303415"
' <<< "$links" >/dev/null

if "$project_dir/radio-track-links" "" "Track" >/dev/null 2>&1; then
  echo "Track-link lookup accepted an empty artist" >&2
  exit 1
fi
