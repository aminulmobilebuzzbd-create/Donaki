#!/usr/bin/env bash
# ইমুলেটরে ডেমো অ্যাপ চালিয়ে প্রতিটা স্ক্রিনের ছবি তোলে।
set -euo pipefail
PKG=com.dokani.dokani
mkdir -p shots

shot() { sleep 2; adb exec-out screencap -p > "shots/$1.png"; echo "saved $1"; }
tap() {
  for i in 1 2 3; do
    adb shell uiautomator dump /sdcard/ui.xml >/dev/null 2>&1 || true
    adb pull /sdcard/ui.xml ui.xml >/dev/null 2>&1 || true
    if xy=$(python3 tool/ui_tap.py ui.xml "$1" "${2:-first}"); then adb shell input tap $xy; return 0; fi
    sleep 2
  done
  echo "could not tap $1"; cp ui.xml "shots/ui-$(date +%s).xml"; return 1
}
back() { adb shell input keyevent 4; sleep 1; }

adb install -r dokani-demo.apk
adb shell settings put system screen_off_timeout 600000
adb shell monkey -p $PKG -c android.intent.category.LAUNCHER 1 >/dev/null
sleep 12

shot 01-baki-khata
tap 'রহিম মিয়া' && shot 02-customer-ledger
tap 'দিলাম' last && sleep 1 && shot 03-add-entry
back; back
adb shell input keyevent 4 || true   # keyboard/sheet বন্ধ নিশ্চিত করা
sleep 1
adb shell monkey -p $PKG -c android.intent.category.LAUNCHER 1 >/dev/null; sleep 3
tap 'ক্যাশবক্স' && shot 04-cashbook
tap 'স্টক' && shot 05-stock
tap 'পণ্য যোগ' && sleep 2 && shot 05a-product-form-top
adb shell input swipe 540 1700 540 500 400; shot 05b-product-form-middle
adb shell input swipe 540 1700 540 400 400; shot 05c-product-form-bottom
back
tap 'রিপোর্ট' && shot 06-report-today
tap 'এই মাস' && shot 07-report-month
ls -la shots
