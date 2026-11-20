import 'package:dokani/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('বাংলা সংখ্যা', () {
    expect(bn(2026), '২০২৬');
  });

  test('দেশি কমা সহ টাকা', () {
    expect(taka(0), '৳০');
    expect(taka(950), '৳৯৫০');
    expect(taka(1234567), '৳১২,৩৪,৫৬৭');
    expect(taka(1500.5), '৳১,৫০০.৫০');
    expect(taka(-200), '-৳২০০');
  });

  test('বাংলা বা ইংরেজি সংখ্যা থেকে টাকা পড়া', () {
    expect(parseAmount('৫০০'), 500);
    expect(parseAmount('1,250.75'), 1250.75);
    expect(parseAmount('abc'), isNull);
  });
}
