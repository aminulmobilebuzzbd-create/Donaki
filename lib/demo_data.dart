import 'db/database.dart';
import 'models.dart';

/// `--dart-define=DEMO_DATA=true` দিয়ে বিল্ড করলে খালি অ্যাপে নমুনা হিসাব ঢুকিয়ে দেয়।
/// শুধু ডেমো/স্ক্রিনশটের জন্য; সাধারণ APK তে এটা চলে না।
const bool kDemoData = bool.fromEnvironment('DEMO_DATA');

Future<void> seedDemoDataIfEmpty() async {
  final db = AppDb.instance;
  if ((await db.customers()).isNotEmpty) return;

  final now = DateTime.now();
  DateTime ago(int days, [int hour = 11]) => DateTime(now.year, now.month, now.day - days, hour, 15);

  final rahim = await db.addCustomer('রহিম মিয়া', '01711234567');
  await db.addLedger(rahim, 'gave', 1250, 'চাল ৫ কেজি, ডাল ২ কেজি', ago(6));
  await db.addLedger(rahim, 'gave', 480, 'সয়াবিন তেল ২ লিটার', ago(3));
  await db.addLedger(rahim, 'got', 500, 'নগদ', ago(1));

  final karim = await db.addCustomer('করিম স্টোর', '01819876543');
  await db.addLedger(karim, 'gave', 3200, 'চিনি ১০ কেজি', ago(10));
  await db.addLedger(karim, 'got', 1000, 'বিকাশে পেলাম', ago(2));

  final salma = await db.addCustomer('সালমা বেগম', '01556677889');
  await db.addLedger(salma, 'gave', 650, 'সাবান, ডিটারজেন্ট', ago(4));

  final jamal = await db.addCustomer('জামাল হোসেন', '01912345678');
  await db.addLedger(jamal, 'gave', 900, 'আটা ৫ কেজি', ago(8));
  await db.addLedger(jamal, 'got', 900, 'পুরো শোধ', ago(1));

  final nasir = await db.addCustomer('নাসির ভাই', null);
  await db.addLedger(nasir, 'got', 300, 'অগ্রিম দিলেন', ago(0, 9));

  await db.addCash('sale', 2350, 'সকালের বিক্রি', ago(0, 9));
  await db.addCash('sale', 1780, 'দুপুরের বিক্রি', ago(0, 13));
  await db.addCash('expense', 450, 'বিদ্যুৎ বিল', ago(0, 14));
  await db.addCash('sale', 3120, 'সন্ধ্যার বিক্রি', ago(0, 19));
  await db.addCash('expense', 200, 'ভ্যান ভাড়া', ago(0, 19));
  for (var d = 1; d <= 6; d++) {
    await db.addCash('sale', 5200.0 + d * 310, 'দিনের বিক্রি', ago(d, 20));
    await db.addCash('expense', 600.0 + d * 45, 'দোকানের খরচ', ago(d, 20));
  }

  const products = [
    Product(name: 'মিনিকেট চাল', price: 72, costPrice: 64, stock: 48, unit: 'কেজি', category: 'চাল-ডাল'),
    Product(name: 'মসুর ডাল', price: 110, costPrice: 98, stock: 22, unit: 'কেজি', category: 'চাল-ডাল'),
    Product(name: 'সয়াবিন তেল', price: 175, costPrice: 162, stock: 4, unit: 'লিটার', category: 'তেল-মসলা'),
    Product(name: 'চিনি', price: 130, costPrice: 118, stock: 15, unit: 'কেজি', category: 'মুদি'),
    Product(name: 'গায়ে মাখা সাবান', price: 65, costPrice: 56, stock: 3, unit: 'পিস', category: 'প্রসাধনী'),
    Product(name: 'ডিম', price: 52, costPrice: 46, stock: 30, unit: 'হালি', category: 'মুদি'),
  ];
  for (final p in products) {
    await db.saveProduct(p);
  }
}
