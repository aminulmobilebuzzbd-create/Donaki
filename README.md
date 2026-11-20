# দোকানি (Dokani)

ছোট দোকানের জন্য বাকি খাতা, বেচাকেনা, খরচ আর স্টকের হিসাব রাখার অ্যাপ।
Android ও iOS দুটোতেই চলে (Flutter দিয়ে বানানো)।

**কোনো মাসিক খরচ নেই:** সব হিসাব ফোনের ভেতরেই থাকে, কোনো সার্ভার বা ক্লাউড লাগে না।
বাকির রিমাইন্ডার যায় ফোনের নিজের SMS অ্যাপ দিয়ে, তাই SMS গেটওয়ের খরচও নেই।

## ফিচার (ভার্সন ০.১)

| ট্যাব | কী করা যায় |
|---|---|
| বাকি খাতা | কাস্টমার যোগ, "দিলাম / পেলাম" এন্ট্রি, কার কাছে কত পাবো, খোঁজা, কল, SMS রিমাইন্ডার |
| ক্যাশবক্স | দিনভিত্তিক বিক্রি ও খরচ, আগের দিনের হিসাব দেখা |
| স্টক | পণ্যের ছবি (৫টা পর্যন্ত), ক্রয় ও বিক্রয়মূল্য, লাভ, একক, ক্যাটাগরি, পাইকারি দাম, কম স্টক এলার্ট, ভ্যাট, ওয়ারেন্টি, ডিসকাউন্ট, বারকোড স্ক্যান |
| রিপোর্ট | আজ / ৭ দিন / এই মাসের লাভ, বিক্রি, খরচ, বাকি দেওয়া ও আদায়; ব্যাকআপ বোতাম |

যেকোনো এন্ট্রি মুছতে চাইলে সেটার উপর লম্বা চাপ দিন।

## নিজের কম্পিউটারে চালানোর নিয়ম

1. Flutter ইনস্টল করুন: https://docs.flutter.dev/get-started/install
   (Android এর জন্য Android Studio, iOS এর জন্য Mac এ Xcode লাগবে)
2. এই `dokani` ফোল্ডারে টার্মিনাল খুলে চালান:
   ```
   flutter create --org com.dokani --platforms android,ios .
   flutter pub get
   flutter test
   flutter run
   ```
   প্রথম লাইনটা শুধু android/ios ফোল্ডার বানায়, আমাদের `lib` এর কোড বদলায় না।
3. Android 11 বা নতুন ফোনে SMS ও কল বোতাম ঠিকমতো কাজ করার জন্য
   `android/app/src/main/AndroidManifest.xml` এ `<manifest>` ট্যাগের ভেতরে এটা যোগ করুন:
   ```xml
   <queries>
     <intent><action android:name="android.intent.action.SENDTO" /><data android:scheme="sms" /></intent>
     <intent><action android:name="android.intent.action.DIAL" /><data android:scheme="tel" /></intent>
   </queries>
   ```
4. অ্যাপের নাম ফোনে "দোকানি" দেখাতে `AndroidManifest.xml` এ `android:label="দোকানি"` এবং
   `ios/Runner/Info.plist` এ `CFBundleDisplayName` = `দোকানি` দিন।

APK বানাতে: `flutter build apk --release`

iOS এ চালালে `ios/Runner/Info.plist` এ ক্যামেরা ও ছবির অনুমতির লেখা দিতে হবে:
`NSCameraUsageDescription` = "পণ্যের ছবি তোলা ও বারকোড স্ক্যানের জন্য" এবং
`NSPhotoLibraryUsageDescription` = "পণ্যের ছবি বাছাইয়ের জন্য"।

GitHub এ কোড গেলে Actions নিজে APK বানিয়ে Releases পেজে রেখে দেয় (ফ্রি)।

## কোডের গঠন

```
lib/
  main.dart                 অ্যাপ শুরু
  theme.dart                রং ও ডিজাইন
  format.dart               বাংলা সংখ্যা, ৳ ফরম্যাট, তারিখ
  models.dart               ডেটার ধরন
  db/database.dart          SQLite ডেটাবেস ও সব হিসাবের কুয়েরি
  widgets/                  বারবার ব্যবহৃত অংশ (টাকা লেখার ফর্ম, কার্ড)
  screens/                  প্রতিটা স্ক্রিন
```

## পরের ধাপে যা যোগ করা যায়

- ব্যাকআপ ফাইল থেকে হিসাব ফেরত আনা (রিস্টোর)
- দোকানের নাম ও পিন লক
- সাপ্লায়ার খাতা
- বিক্রির সময় স্টক থেকে নিজে থেকে কমে যাওয়া
- রসিদ/ইনভয়েস PDF
