#!/usr/bin/env bash
# Captures App Store screenshots (6.9" iPhone) in demo mode.
#
#   Scripts/screenshots.sh ["iPhone 17 Pro Max"]
#
# Boots the simulator, sets a clean status bar (9:41, full battery), runs
# ScreenshotTests, then exports the PNG attachments to AppStore/screenshots/.
# Run it twice with the simulator in light and dark appearance if you want both.
set -euo pipefail

DEVICE="${1:-iPhone 17 Pro Max}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RESULT="$ROOT/build/Screenshots.xcresult"
OUT="$ROOT/AppStore/screenshots"

cd "$ROOT"
command -v xcodegen >/dev/null && xcodegen generate

UDID="$(xcrun simctl list devices available | grep -m1 "    $DEVICE (" | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/')"
if [ -z "$UDID" ]; then
  echo "No simulator named '$DEVICE'. Available:"; xcrun simctl list devices available; exit 1
fi

xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b
xcrun simctl status_bar "$UDID" override \
  --time "9:41" --dataNetwork wifi --wifiMode active --wifiBars 3 \
  --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100

rm -rf "$RESULT"
xcodebuild test \
  -project Still.xcodeproj \
  -scheme Still \
  -destination "id=$UDID" \
  -only-testing:StillUITests/ScreenshotTests \
  -resultBundlePath "$RESULT"

mkdir -p "$OUT"
xcrun xcresulttool export attachments --path "$RESULT" --output-path "$OUT/raw"

# Name the files after the attachment names from the manifest.
python3 - "$OUT" <<'PY'
import json, os, shutil, sys
out = sys.argv[1]
raw = os.path.join(out, "raw")
manifest = json.load(open(os.path.join(raw, "manifest.json")))
for test in manifest:
    for attachment in test.get("attachments", []):
        name = attachment.get("suggestedHumanReadableName") or attachment["exportedFileName"]
        base = name.split("_")[0]
        shutil.copy(os.path.join(raw, attachment["exportedFileName"]), os.path.join(out, base + ".png"))
shutil.rmtree(raw)
print("Screenshots:", sorted(f for f in os.listdir(out) if f.endswith(".png")))
PY

xcrun simctl status_bar "$UDID" clear
