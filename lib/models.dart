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

  /// বিক্রয়মূল্য
  final double price;

  /// ক্রয়মূল্য
  final double costPrice;
  final double stock;
  final String unit;
  final String category;
  final String subCategory;
  final String description;

  final bool wholesale;
  final double wholesalePrice;
  final double wholesaleMinQty;

  final bool lowAlert;
  final double lowAlertQty;

  final bool vat;
  final double vatPercent;

  final bool warranty;
  final int warrantyMonths;

  final bool discount;
  final double discountAmount;

  /// true হলে ডিসকাউন্ট শতাংশে (%), না হলে টাকায়
  final bool discountIsPercent;

  final String barcode;

  /// ফোনে রাখা ছবির ফাইলের পথ, সর্বোচ্চ ৫টা
  final List<String> images;

  const Product({
    this.id,
    required this.name,
    this.price = 0,
    this.costPrice = 0,
    this.stock = 0,
    this.unit = 'পিস',
    this.category = '',
    this.subCategory = '',
    this.description = '',
    this.wholesale = false,
    this.wholesalePrice = 0,
    this.wholesaleMinQty = 0,
    this.lowAlert = true,
    this.lowAlertQty = 5,
    this.vat = false,
    this.vatPercent = 0,
    this.warranty = false,
    this.warrantyMonths = 0,
    this.discount = false,
    this.discountAmount = 0,
    this.discountIsPercent = false,
    this.barcode = '',
    this.images = const [],
  });

  bool get isLow => lowAlert && stock <= lowAlertQty;

  /// প্রতি এককে লাভ (ক্রয়মূল্য দেওয়া থাকলে)
  double get unitProfit => price - costPrice;

  String? get coverImage => images.isEmpty ? null : images.first;

  static List<String> _decodeImages(Object? v) {
    final s = (v as String?) ?? '';
    return s.isEmpty ? const [] : s.split('\n').where((e) => e.isNotEmpty).toList();
  }

  factory Product.fromMap(Map<String, Object?> m) => Product(
        id: m['id'] as int,
        name: m['name'] as String,
        price: _d(m['price']),
        costPrice: _d(m['cost_price']),
        stock: _d(m['stock']),
        unit: (m['unit'] as String?) ?? 'পিস',
        category: (m['category'] as String?) ?? '',
        subCategory: (m['sub_category'] as String?) ?? '',
        description: (m['description'] as String?) ?? '',
        wholesale: m['wholesale'] == 1,
        wholesalePrice: _d(m['wholesale_price']),
        wholesaleMinQty: _d(m['wholesale_min_qty']),
        lowAlert: (m['low_alert'] ?? 1) == 1,
        lowAlertQty: m['low_alert_qty'] == null ? 5 : _d(m['low_alert_qty']),
        vat: m['vat'] == 1,
        vatPercent: _d(m['vat_percent']),
        warranty: m['warranty'] == 1,
        warrantyMonths: (m['warranty_months'] as int?) ?? 0,
        discount: m['discount'] == 1,
        discountAmount: _d(m['discount_amount']),
        discountIsPercent: m['discount_is_percent'] == 1,
        barcode: (m['barcode'] as String?) ?? '',
        images: _decodeImages(m['images']),
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'price': price,
        'cost_price': costPrice,
        'stock': stock,
        'unit': unit,
        'category': category,
        'sub_category': subCategory,
        'description': description,
        'wholesale': wholesale ? 1 : 0,
        'wholesale_price': wholesalePrice,
        'wholesale_min_qty': wholesaleMinQty,
        'low_alert': lowAlert ? 1 : 0,
        'low_alert_qty': lowAlertQty,
        'vat': vat ? 1 : 0,
        'vat_percent': vatPercent,
        'warranty': warranty ? 1 : 0,
        'warranty_months': warrantyMonths,
        'discount': discount ? 1 : 0,
        'discount_amount': discountAmount,
        'discount_is_percent': discountIsPercent ? 1 : 0,
        'barcode': barcode,
        'images': images.join('\n'),
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
