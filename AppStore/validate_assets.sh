#!/bin/zsh
set -euo pipefail

root_dir="${0:A:h:h}"

check_png() {
  local file="$1"
  local expected_width="$2"
  local expected_height="$3"
  local width
  local height
  local alpha

  width="$(sips -g pixelWidth "$file" | awk '/pixelWidth/ {print $2}')"
  height="$(sips -g pixelHeight "$file" | awk '/pixelHeight/ {print $2}')"
  alpha="$(sips -g hasAlpha "$file" | awk '/hasAlpha/ {print $2}')"

  if [[ "$width" != "$expected_width" || "$height" != "$expected_height" || "$alpha" != "no" ]]; then
    print -u2 "Invalid PNG: $file (${width}x${height}, alpha=${alpha})"
    return 1
  fi
}

check_png "$root_dir/AppStore/Brand/AppIcon-approved-v3-1024.png" 1024 1024
check_png "$root_dir/SecondClock/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png" 1024 1024

for file in "$root_dir"/AppStore/Brand/IconCandidates-v2/*-1024.png; do
  check_png "$file" 1024 1024
done

for file in "$root_dir"/AppStore/Brand/IconCandidates-v3/*-1024.png; do
  check_png "$file" 1024 1024
done

for file in "$root_dir"/AppStore/Screenshots/Final-ja/*.png; do
  check_png "$file" 2868 1320
done

for file in "$root_dir"/AppStore/Screenshots/Final-en/*.png; do
  check_png "$file" 2868 1320
done

check_png "$root_dir/AppStore/Review/iap-review.png" 2868 1320

keyword_bytes="$(ruby -e 'print "時計,秒表示,全画面,横向き,ウィジェット,ロック画面,置き時計,デジタル".bytesize')"
if (( keyword_bytes > 100 )); then
  print -u2 "Keywords exceed 100 bytes: $keyword_bytes"
  exit 1
fi

print "Asset validation passed: icon, screenshots, IAP review image, and keywords"
