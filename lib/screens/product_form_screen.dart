import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../db/database.dart';
import '../format.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'barcode_scanner_screen.dart';

const kMaxImages = 5;

const kUnits = ['পিস', 'কেজি', 'গ্রাম', 'লিটার', 'মিলি', 'হালি', 'ডজন', 'প্যাকেট', 'বক্স', 'বস্তা', 'মিটার', 'ফুট', 'গজ', 'জোড়া', 'সেট'];

const kCategories = [
  'মুদি', 'চাল-ডাল', 'তেল-মসলা', 'পানীয়', 'বিস্কুট ও স্ন্যাক্স', 'প্রসাধনী', 'ঔষধ',
  'মোবাইল ও এক্সেসরিজ', 'চার্জার ও এডাপ্টার', 'ইলেকট্রনিক্স', 'কাপড়', 'জুতা', 'স্টেশনারি', 'হার্ডওয়্যার', 'অন্যান্য',
];

/// পণ্য যোগ / এডিট করার পূর্ণ স্ক্রিন। সেভ হলে true ফেরত দেয়।
class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, this.existing});
  final Product? existing;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  Product? get _e => widget.existing;

  late final _name = TextEditingController(text: _e?.name);
  late final _price = TextEditingController(text: _num(_e?.price));
  late final _cost = TextEditingController(text: _num(_e?.costPrice));
  late final _stock = TextEditingController(text: _num(_e?.stock));
  late final _category = TextEditingController(text: _e?.category);
  late final _subCategory = TextEditingController(text: _e?.subCategory);
  late final _description = TextEditingController(text: _e?.description);
  late final _wholesalePrice = TextEditingController(text: _num(_e?.wholesalePrice));
  late final _wholesaleMinQty = TextEditingController(text: _num(_e?.wholesaleMinQty));
  late final _lowAlertQty = TextEditingController(text: _num(_e?.lowAlertQty ?? 5));
  late final _vatPercent = TextEditingController(text: _num(_e?.vatPercent));
  late final _warrantyMonths = TextEditingController(text: _num(_e?.warrantyMonths));
  late final _discountAmount = TextEditingController(text: _num(_e?.discountAmount));
  late final _barcode = TextEditingController(text: _e?.barcode);

  late String _unit = _e?.unit ?? kUnits.first;
  late bool _wholesale = _e?.wholesale ?? false;
  late bool _lowAlert = _e?.lowAlert ?? true;
  late bool _vat = _e?.vat ?? false;
  late bool _warranty = _e?.warranty ?? false;
  late bool _discount = _e?.discount ?? false;
  late bool _discountIsPercent = _e?.discountIsPercent ?? false;
  late final List<String> _images = [...?_e?.images];

  List<String> _savedCategories = const [];
  String? _nameError;
  String? _priceError;
  bool _saving = false;

  static String _num(num? v) {
    if (v == null || v == 0) return '';
    return v == v.roundToDouble() ? v.toInt().toString() : v.toString();
  }

  @override
  void initState() {
    super.initState();
    for (final c in [_price, _cost]) {
      c.addListener(() => setState(() {}));
    }
    AppDb.instance.productCategories().then((v) {
      if (mounted) setState(() => _savedCategories = v);
    });
  }

  @override
  void dispose() {
    for (final c in [
      _name, _price, _cost, _stock, _category, _subCategory, _description, _wholesalePrice,
      _wholesaleMinQty, _lowAlertQty, _vatPercent, _warrantyMonths, _discountAmount, _barcode,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ---------------- ছবি ----------------

  Future<void> _addImage() async {
    if (_images.length >= kMaxImages) {
      toast(context, 'সর্বোচ্চ ${bn(kMaxImages)}টা ছবি দেওয়া যায়');
      return;
    }
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_camera),
            title: const Text('ক্যামেরা দিয়ে ছবি তুলুন'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('গ্যালারি থেকে বাছুন'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ]),
      ),
    );
    if (source == null) return;
    try {
      final picker = ImagePicker();
      final remaining = kMaxImages - _images.length;
      final List<XFile> picked;
      if (source == ImageSource.gallery && remaining > 1) {
        picked = await picker.pickMultiImage(maxWidth: 1280, imageQuality: 80, limit: remaining);
      } else {
        final x = await picker.pickImage(source: source, maxWidth: 1280, imageQuality: 80);
        picked = x == null ? const [] : [x];
      }
      if (picked.isEmpty) return;

      // ছবিগুলো অ্যাপের নিজের ফোল্ডারে কপি রাখা হয়, যাতে গ্যালারি থেকে মুছলেও থাকে।
      final dir = Directory(p.join((await getApplicationDocumentsDirectory()).path, 'product_images'));
      await dir.create(recursive: true);
      final copied = <String>[];
      for (final x in picked.take(kMaxImages - _images.length)) {
        final name = '${DateTime.now().microsecondsSinceEpoch}_${copied.length}${p.extension(x.path)}';
        copied.add((await File(x.path).copy(p.join(dir.path, name))).path);
      }
      setState(() => _images.addAll(copied));
    } catch (e) {
      if (mounted) toast(context, 'ছবি নেওয়া যায়নি: $e');
    }
  }

  void _removeImage(int i) => setState(() => _images.removeAt(i));

  void _viewImage(String path) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        clipBehavior: Clip.antiAlias,
        child: InteractiveViewer(child: Image.file(File(path), fit: BoxFit.contain)),
      ),
    );
  }

  // ---------------- বারকোড ----------------

  void _generateBarcode() {
    // ২০ দিয়ে শুরু হওয়া ১৩ অঙ্কের কোড (দোকানের নিজস্ব ব্যবহারের জন্য সংরক্ষিত পরিসর)
    final r = Random();
    final digits = '20${List.generate(10, (_) => r.nextInt(10)).join()}';
    var sum = 0;
    for (var i = 0; i < 12; i++) {
      sum += int.parse(digits[i]) * (i.isEven ? 1 : 3);
    }
    setState(() => _barcode.text = '$digits${(10 - sum % 10) % 10}');
  }

  Future<void> _scanBarcode() async {
    final code = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()));
    if (code != null && code.isNotEmpty) setState(() => _barcode.text = code);
  }

  // ---------------- সেভ / মুছুন ----------------

  double _n(TextEditingController c) => parseAmount(c.text) ?? 0;

  Future<void> _save() async {
    final name = _name.text.trim();
    final price = parseAmount(_price.text);
    setState(() {
      _nameError = name.isEmpty ? 'পণ্যের নাম লিখুন' : null;
      _priceError = (price == null || price < 0) ? 'বিক্রয়মূল্য লিখুন' : null;
    });
    if (_nameError != null || _priceError != null) {
      toast(context, 'লাল চিহ্নিত ঘরগুলো পূরণ করুন');
      return;
    }

    final barcode = _barcode.text.trim();
    if (barcode.isNotEmpty && await AppDb.instance.barcodeExists(barcode, exceptId: _e?.id)) {
      if (mounted) toast(context, 'এই বারকোড অন্য একটা পণ্যে আছে');
      return;
    }

    setState(() => _saving = true);
    final product = Product(
      id: _e?.id,
      name: name,
      price: price!,
      costPrice: _n(_cost),
      stock: _n(_stock),
      unit: _unit,
      category: _category.text.trim(),
      subCategory: _subCategory.text.trim(),
      description: _description.text.trim(),
      wholesale: _wholesale,
      wholesalePrice: _n(_wholesalePrice),
      wholesaleMinQty: _n(_wholesaleMinQty),
      lowAlert: _lowAlert,
      lowAlertQty: _n(_lowAlertQty),
      vat: _vat,
      vatPercent: _n(_vatPercent),
      warranty: _warranty,
      warrantyMonths: _n(_warrantyMonths).round(),
      discount: _discount,
      discountAmount: _n(_discountAmount),
      discountIsPercent: _discountIsPercent,
      barcode: barcode,
      images: List.of(_images),
    );
    await AppDb.instance.saveProduct(product);
    await _deleteFiles((_e?.images ?? const []).where((x) => !_images.contains(x)));
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    final e = _e;
    if (e?.id == null) return;
    if (!await confirm(context, '${e!.name} মুছে ফেলবেন?')) return;
    await AppDb.instance.deleteProduct(e.id!);
    await _deleteFiles(e.images);
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _deleteFiles(Iterable<String> paths) async {
    for (final path in paths.toList()) {
      try {
        await File(path).delete();
      } catch (_) {
        // ফাইল আগেই মুছে গেলে কিছু করার নেই
      }
    }
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final cost = parseAmount(_cost.text) ?? 0;
    final price = parseAmount(_price.text) ?? 0;
    final profit = price - cost;
    final categories = {...kCategories, ..._savedCategories}.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_e == null ? 'পণ্য যোগ করুন' : 'পণ্য এডিট'),
        actions: [
          if (_e != null) IconButton(tooltip: 'মুছুন', icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          _Section(children: [
            _Label('পণ্যের নাম', isRequired: true),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(hintText: 'যেমন: মিনিকেট চাল ৫ কেজি', errorText: _nameError),
            ),
            const SizedBox(height: 14),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: _NumField(label: 'বিক্রয়মূল্য (৳)', controller: _price, isRequired: true, hint: '৫০০', error: _priceError)),
              const SizedBox(width: 12),
              Expanded(child: _NumField(label: 'ক্রয়মূল্য (৳)', controller: _cost, hint: '৪০০')),
            ]),
            if (price > 0 && cost > 0)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  profit >= 0
                      ? 'প্রতি $_unit এ লাভ ${taka(profit)} (${bn((profit / cost * 100).toStringAsFixed(1))}%)'
                      : 'সাবধান: প্রতি $_unit এ লোকসান ${taka(-profit)}',
                  style: TextStyle(color: profit >= 0 ? AppColors.inn : AppColors.out, fontWeight: FontWeight.w600),
                ),
              ),
            const SizedBox(height: 14),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: _NumField(label: 'স্টক সংখ্যা', controller: _stock, hint: '০')),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const _Label('পণ্যের একক'),
                  DropdownButtonFormField<String>(
                    value: kUnits.contains(_unit) ? _unit : kUnits.first,
                    isExpanded: true,
                    items: [for (final u in kUnits) DropdownMenuItem(value: u, child: Text(u))],
                    onChanged: (v) => setState(() => _unit = v ?? _unit),
                  ),
                ]),
              ),
            ]),
            const SizedBox(height: 14),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const _Label('ক্যাটাগরি'),
                  TextField(
                    controller: _category,
                    decoration: InputDecoration(
                      hintText: 'বাছুন বা লিখুন',
                      suffixIcon: PopupMenuButton<String>(
                        icon: const Icon(Icons.arrow_drop_down),
                        onSelected: (v) => setState(() => _category.text = v),
                        itemBuilder: (_) => [for (final c in categories) PopupMenuItem(value: c, child: Text(c))],
                      ),
                    ),
                  ),
                ]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const _Label('সাব ক্যাটাগরি'),
                  TextField(controller: _subCategory, decoration: const InputDecoration(hintText: 'যেমন: ফাস্ট চার্জার')),
                ]),
              ),
            ]),
            const SizedBox(height: 14),
            const _Label('পণ্যের বিস্তারিত'),
            TextField(
              controller: _description,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(hintText: 'পণ্যের বিস্তারিত (না দিলেও হবে)'),
            ),
          ]),
          const SizedBox(height: 12),
          _Section(children: [
            _ToggleCard(
              title: 'পাইকারি বিক্রি করতে চান?',
              value: _wholesale,
              onChanged: (v) => setState(() => _wholesale = v),
              child: Row(children: [
                Expanded(child: _NumField(label: 'পাইকারি দাম (৳)', controller: _wholesalePrice, compact: true)),
                const SizedBox(width: 10),
                Expanded(child: _NumField(label: 'কমপক্ষে কত $_unit', controller: _wholesaleMinQty, compact: true)),
              ]),
            ),
            _ToggleCard(
              title: 'স্টক কমের এলার্ট?',
              value: _lowAlert,
              onChanged: (v) => setState(() => _lowAlert = v),
              child: _InlineNum(prefix: 'কমে আসলে সতর্ক করবেন:', controller: _lowAlertQty, suffix: _unit),
            ),
            _ToggleCard(
              title: 'ভ্যাট প্রযোজ্য?',
              value: _vat,
              onChanged: (v) => setState(() => _vat = v),
              child: _InlineNum(prefix: 'ভ্যাটের হার:', controller: _vatPercent, suffix: '%'),
            ),
            _ToggleCard(
              title: 'ওয়ারেন্টি',
              value: _warranty,
              onChanged: (v) => setState(() => _warranty = v),
              child: _InlineNum(prefix: 'ওয়ারেন্টির মেয়াদ:', controller: _warrantyMonths, suffix: 'মাস'),
            ),
            _ToggleCard(
              title: 'ডিসকাউন্ট',
              value: _discount,
              onChanged: (v) => setState(() => _discount = v),
              child: Row(children: [
                Expanded(child: _NumField(label: 'ডিসকাউন্ট', controller: _discountAmount, compact: true)),
                const SizedBox(width: 10),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('৳')),
                    ButtonSegment(value: true, label: Text('%')),
                  ],
                  selected: {_discountIsPercent},
                  onSelectionChanged: (s) => setState(() => _discountIsPercent = s.first),
                ),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          _Section(children: [
            Row(children: [
              Expanded(child: Text('পণ্যের ছবি (সর্বোচ্চ ${bn(kMaxImages)}টি)', style: _sectionTitle)),
              Text('${bn(_images.length)}/${bn(kMaxImages)}', style: const TextStyle(color: Colors.black54)),
            ]),
            const SizedBox(height: 12),
            Wrap(spacing: 10, runSpacing: 10, children: [
              for (var i = 0; i < _images.length; i++)
                _Thumb(path: _images[i], cover: i == 0, onTap: () => _viewImage(_images[i]), onRemove: () => _removeImage(i)),
              if (_images.length < kMaxImages)
                InkWell(
                  onTap: _addImage,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(color: AppColors.brand, borderRadius: BorderRadius.circular(14)),
                    child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.add_a_photo, color: Colors.white),
                      SizedBox(height: 4),
                      Text('ছবি দিন', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ]),
                  ),
                ),
            ]),
          ]),
          const SizedBox(height: 12),
          _Section(children: [
            Row(children: [
              Expanded(child: Text('বারকোড / কোড', style: _sectionTitle)),
              TextButton(onPressed: _generateBarcode, child: const Text('স্বয়ংক্রিয় তৈরি করুন')),
            ]),
            TextField(controller: _barcode, decoration: const InputDecoration(hintText: 'বারকোড বা SKU নম্বর')),
            const SizedBox(height: 10),
            FilledButton.icon(
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: _scanBarcode,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('বারকোড স্ক্যান'),
            ),
          ]),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Row(children: [
            Expanded(
              flex: 2,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: () => Navigator.pop(context),
                child: const Text('বাতিল', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.check),
                label: const Text('সেভ করুন', style: TextStyle(fontSize: 16)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

const _sectionTitle = TextStyle(fontSize: 16, fontWeight: FontWeight.w700);

class _Section extends StatelessWidget {
  const _Section({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text, {this.isRequired = false});
  final String text;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(TextSpan(
        text: text,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        children: [if (isRequired) const TextSpan(text: ' *', style: TextStyle(color: Colors.red))],
      )),
    );
  }
}

class _NumField extends StatelessWidget {
  const _NumField({
    required this.label,
    required this.controller,
    this.isRequired = false,
    this.hint,
    this.error,
    this.compact = false,
  });

  final String label;
  final TextEditingController controller;
  final bool isRequired;
  final String? hint;
  final String? error;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        hintText: hint,
        errorText: error,
        labelText: compact ? label : null,
        isDense: compact,
      ),
    );
    if (compact) return field;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_Label(label, isRequired: isRequired), field]);
  }
}

class _InlineNum extends StatelessWidget {
  const _InlineNum({required this.prefix, required this.controller, required this.suffix});
  final String prefix;
  final TextEditingController controller;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Flexible(child: Text(prefix, style: const TextStyle(color: Colors.black54))),
      const SizedBox(width: 8),
      SizedBox(
        width: 90,
        child: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(isDense: true),
        ),
      ),
      const SizedBox(width: 8),
      Text(suffix, style: const TextStyle(color: Colors.black54)),
    ]);
  }
}

class _ToggleCard extends StatelessWidget {
  const _ToggleCard({required this.title, required this.value, required this.onChanged, required this.child});
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(color: const Color(0xFFF5F7F6), borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        SwitchListTile(
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          value: value,
          onChanged: onChanged,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        if (value)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: child,
          ),
      ]),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.path, required this.cover, required this.onTap, required this.onRemove});
  final String path;
  final bool cover;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      height: 84,
      child: Stack(children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: onTap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(
                File(path),
                fit: BoxFit.cover,
                cacheWidth: 200,
                errorBuilder: (_, __, ___) => Container(color: Colors.black12, child: const Icon(Icons.broken_image)),
              ),
            ),
          ),
        ),
        if (cover)
          Positioned(
            left: 4,
            bottom: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
              child: const Text('প্রধান', style: TextStyle(color: Colors.white, fontSize: 10)),
            ),
          ),
        Positioned(
          right: 2,
          top: 2,
          child: InkWell(
            onTap: onRemove,
            child: const CircleAvatar(radius: 12, backgroundColor: Colors.black54, child: Icon(Icons.close, size: 14, color: Colors.white)),
          ),
        ),
      ]),
    );
  }
}
