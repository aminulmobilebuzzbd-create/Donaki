const _bnDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];

const _bnMonths = [
  'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
  'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর',
];

/// ইংরেজি সংখ্যাকে বাংলা সংখ্যায় রূপান্তর: 120 -> ১২০
String bn(Object value) => value
    .toString()
    .replaceAllMapped(RegExp(r'[0-9]'), (m) => _bnDigits[int.parse(m[0]!)]);

/// বাংলা বা ইংরেজি যেকোনো সংখ্যা লেখা থেকে টাকার পরিমাণ পড়া।
double? parseAmount(String input) {
  var s = input.trim().replaceAll(',', '');
  for (var i = 0; i < 10; i++) {
    s = s.replaceAll(_bnDigits[i], '$i');
  }
  return double.tryParse(s);
}

/// ১২৩৪৫৬৭ -> ৳১২,৩৪,৫৬৭ (দেশি কমা)
String taka(num value) {
  final negative = value < 0;
  final cents = (value.abs() * 100).round();
  final whole = cents ~/ 100;
  final frac = cents % 100;

  var s = whole.toString();
  if (s.length > 3) {
    final last3 = s.substring(s.length - 3);
    var rest = s.substring(0, s.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    s = '${parts.join(',')},$last3';
  }
  if (frac > 0) s = '$s.${frac.toString().padLeft(2, '0')}';
  return '${negative ? '-' : ''}৳${bn(s)}';
}

/// ২০ নভেম্বর ২০২৬
String dateBn(DateTime d) => '${bn(d.day)} ${_bnMonths[d.month - 1]} ${bn(d.year)}';

/// সকাল/বিকাল সহ সময়: ৪:২৫ বিকাল
String timeBn(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final part = d.hour < 12
      ? 'সকাল'
      : d.hour < 17
          ? 'বিকাল'
          : 'রাত';
  return '${bn(h)}:${bn(d.minute.toString().padLeft(2, '0'))} $part';
}

DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
