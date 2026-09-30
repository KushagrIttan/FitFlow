#!/usr/bin/env bash
# hermes-verify-dailyfit.sh — ad-hoc verification (persisted as tool/verify.sh).
set -u
# Portable: repo root = parent of this script's dir (works on any machine).
PROJ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJ" || { echo "FAIL: cannot cd"; exit 1; }
PASS=0; FAIL=0
ok()  { echo "  ✅ $1"; PASS=$((PASS+1)); }
bad() { echo "  ❌ $1"; FAIL=$((FAIL+1)); }

echo "== 1/9 flutter analyze =="
A=$(flutter analyze 2>&1 | tail -2); echo "$A"
echo "$A" | grep -q "No issues found" && ok "analyze clean" || bad "analyze issues"

echo "== 2/9 flutter test =="
T=$(flutter test 2>&1 | tail -2); echo "$T"
echo "$T" | grep -q "All tests passed" && ok "all tests pass" || bad "test failures"

echo "== 3/9 fresh release build =="
B=$(flutter build apk --release 2>&1 | tail -3); echo "$B"
echo "$B" | grep -q "app-release.apk" && ok "release APK rebuilt" || bad "release build failed"

APK="build/app/outputs/flutter-apk/app-release.apk"
AAPT=$(find "$LOCALAPPDATA/Android/Sdk/build-tools" -name aapt2.exe 2>/dev/null | sort -V | tail -1)

echo "== 4/9 no Gemini secret in release APK (.env holds only the public RC key) =="
GEM_IN_APK=$(unzip -p "$APK" assets/.env 2>/dev/null | grep -c "AIza" || true)
[ "$GEM_IN_APK" -eq 0 ] && ok "no Gemini key in APK" || bad "Gemini key found in APK"

echo "== 5/9 INTERNET in release APK =="
P=$("$AAPT" dump badging "$APK" 2>/dev/null | grep -i "uses-permission")
echo "$P" | grep -q "android.permission.INTERNET" && ok "INTERNET present" || bad "INTERNET missing"

echo "== 6/9 POST_NOTIFICATIONS in release APK =="
echo "$P" | grep -q "android.permission.POST_NOTIFICATIONS" && ok "POST_NOTIFICATIONS present" || bad "POST_NOTIFICATIONS missing"

echo "== 7/9 app label =="
L=$("$AAPT" dump badging "$APK" 2>/dev/null | grep "application-label:"); echo "$L"
echo "$L" | grep -qi "Daily Fit" && ok "label correct" || bad "label wrong"

echo "== 8/9 launcher icon =="
ICON="android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png"
V=$(python -c "
from PIL import Image
img = Image.open('$ICON').convert('RGB')
colors = img.resize((64,64)).getcolors(64*64)
y = any(abs(c[0]-255)<20 and abs(c[1]-214)<20 and abs(c[2]-10)<30 for _, c in colors)
d = any(c[0]<40 and c[1]<40 and c[2]<40 for _, c in colors)
print('custom' if (y and d) else 'default')
")
[ "$V" = "custom" ] && ok "custom hanger icon" || bad "icon is default"

echo "== 9/9 .env untracked + no real key value in git =="
[ "$(git ls-files | grep -c '^.env$')" -eq 0 ] && ok ".env not tracked" || bad ".env tracked"
[ -f .env.example ] && ok ".env.example template present" || bad ".env.example missing"
# .env files must never contain a Gemini (AIza) value — only the public RC key.
ENV_GEMINI=$(grep -rh "AIza" .env .env.example 2>/dev/null | grep -c . || true)
[ "$ENV_GEMINI" -eq 0 ] && ok "no Gemini value in .env files" || bad "Gemini value in .env files"
# Generic scan: any blob containing a real-looking GEMINI_API_KEY assignment,
# excluding the documented 'your_*' placeholders. (Embeds no secret.)
HITS=$(git rev-list --all --objects | while read h p; do
  if git cat-file blob "$h" 2>/dev/null | grep -E 'GEMINI_API_KEY=[A-Za-z0-9_.-]{10,}' | grep -v 'your_' | grep -q .; then echo "$h"; fi
done)
[ -z "$HITS" ] && ok "no key value in git objects" || bad "key found: $HITS"

echo ""
echo "RESULT: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
