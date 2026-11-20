double _d(Object? v) => (v as num? ?? 0).toDouble();

DateTime _t(Object? v) => DateTime.fromMillisecondsSinceEpoch(v as int);

class Customer {
  final int id;
  final String name;
  final String? phone;

  /// ধনাত্মক = কাস্টমারের কাছে পাবো, ঋণাত্মক = কাস্টমারকে দেবো
  final double balance;

  const Customer({
    required this.id,
    required this.name,
    this.phone,
    this.balance = 0,
  });

  factory Customer.fromMap(Map<String, Object?> m) => Customer(
        id: m['id'] as int,
        name: m['name'] as String,
        phone: m['phone'] as String?,
        balance: _d(m['balance']),
      );

  bool get hasPhone => phone != null && phone!.trim().isNotEmpty;
}

/// type: 'gave' (দিলাম, বাকি বাড়ে) বা 'got' (পেলাম, বাকি কমে)
class LedgerEntry {
  final int id;
  final int customerId;
  final String type;
  final double amount;
  final String note;
  final DateTime date;

  const LedgerEntry({
    required this.id,
    required this.customerId,
    required this.type,
    required this.amount,
    required this.note,
    required this.date,
  });

  bool get isGave => type == 'gave';

  factory LedgerEntry.fromMap(Map<String, Object?> m) => LedgerEntry(
        id: m['id'] as int,
        customerId: m['customer_id'] as int,
        type: m['type'] as String,
        amount: _d(m['amount']),
        note: (m['note'] as String?) ?? '',
        date: _t(m['date']),
      );
}

/// type: 'sale' (বিক্রি) বা 'expense' (খরচ)
class CashEntry {
  final int id;
  final String type;
  final double amount;
  final String note;
  final DateTime date;

  const CashEntry({
    required this.id,
    required this.type,
    required this.amount,
    required this.note,
    required this.date,
  });

  bool get isSale => type == 'sale';

  factory CashEntry.fromMap(Map<String, Object?> m) => CashEntry(
        id: m['id'] as int,
        type: m['type'] as String,
        amount: _d(m['amount']),
        note: (m['note'] as String?) ?? '',
        date: _t(m['date']),
      );
}

class Product {
  final int? id;
  final String name;
  final double price;
  final double stock;

  const Product({this.id, required this.name, this.price = 0, this.stock = 0});

  bool get isLow => stock <= 5;

  factory Product.fromMap(Map<String, Object?> m) => Product(
        id: m['id'] as int,
        name: m['name'] as String,
        price: _d(m['price']),
        stock: _d(m['stock']),
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'price': price,
        'stock': stock,
      };
}

class Report {
  final double sales;
  final double expense;
  final double bakiGiven;
  final double bakiCollected;
  final double totalReceivable;
  final double totalPayable;

  const Report({
    required this.sales,
    required this.expense,
    required this.bakiGiven,
    required this.bakiCollected,
    required this.totalReceivable,
    required this.totalPayable,
  });

  double get profit => sales - expense;
}
