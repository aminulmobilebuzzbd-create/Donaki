"""flutter create এর পর AndroidManifest এ অ্যাপের নাম ও SMS/কল queries যোগ করে।"""
import re
from pathlib import Path

path = Path("android/app/src/main/AndroidManifest.xml")
s = path.read_text(encoding="utf-8")
s = re.sub(r'android:label="[^"]*"', 'android:label="দোকানি"', s, count=1)

intents = (
    '\n        <intent><action android:name="android.intent.action.SENDTO" /><data android:scheme="sms" /></intent>'
    '\n        <intent><action android:name="android.intent.action.DIAL" /><data android:scheme="tel" /></intent>'
)
if "android.intent.action.SENDTO" not in s:
    if "<queries>" in s:
        s = s.replace("<queries>", "<queries>" + intents, 1)
    else:
        s = s.replace("</manifest>", "    <queries>" + intents + "\n    </queries>\n</manifest>", 1)
path.write_text(s, encoding="utf-8")
print("AndroidManifest patched")

# কিছু প্লাগইনের (image_picker) সাথে Android lint নিজেই ক্র্যাশ করে, তাই রিলিজ বিল্ডে lintVital বন্ধ রাখা হলো।
LINT_OFF = """
subprojects {
    tasks.configureEach {
        if (name.startsWith("lintVital")) {
            enabled = false
        }
    }
}
"""
for name in ("android/build.gradle.kts", "android/build.gradle"):
    gradle = Path(name)
    if gradle.exists():
        text = gradle.read_text(encoding="utf-8")
        if "lintVital" not in text:
            gradle.write_text(text + LINT_OFF, encoding="utf-8")
            print(f"lintVital disabled in {name}")
        break
