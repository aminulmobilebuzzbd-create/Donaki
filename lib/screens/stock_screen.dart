import 'dart:io';

import 'package:flutter/material.dart';

import '../db/database.dart';
import '../format.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'product_form_screen.dart';

/// পণ্যের তালিকা: ছবি, ক্রয়/বিক্রয়মূল্য, লাভ আর কতটা স্টকে আছে।
class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  late Future<List<Product>> _future = AppDb.instance.products();
  String _query = '';

  void _reload() => setState(() => _future = AppDb.instance.products());

  Future<void> _open([Product? existing]) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ProductFormScreen(existing: existing)),
    );
    if (changed == true) _reload();
  }

  Future<void> _adjust(Product p, double delta) async {
    await AppDb.instance.adjustStock(p.id!, delta);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('স্টক')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _open(),
        icon: const Icon(Icons.add),
        label: const Text('পণ্য যোগ'),
      ),
      body: FutureBuilder<List<Product>>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('সমস্যা হয়েছে: ${snap.error}'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final all = snap.data!;
          if (all.isEmpty) {
            return const EmptyState(icon: Icons.inventory_2_outlined, message: 'এখনো কোনো পণ্য যোগ করা হয়নি');
          }
          final q = _query.toLowerCase();
          final items = q.isEmpty
              ? all
              : all
                  .where((p) =>
                      p.name.toLowerCase().contains(q) || p.category.toLowerCase().contains(q) || p.barcode.contains(q))
                  .toList();
          final lowCount = all.where((p) => p.isLow).length;
          final costValue = all.fold<double>(0, (s, p) => s + p.costPrice * p.stock);
          final saleValue = all.fold<double>(0, (s, p) => s + p.price * p.stock);

          return ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: Row(children: [
                  Expanded(child: SummaryCard(label: 'স্টক (ক্রয়মূল্যে)', amount: costValue, color: AppColors.brand)),
                  const SizedBox(width: 6),
                  Expanded(child: SummaryCard(label: 'স্টক (বিক্রয়মূল্যে)', amount: saleValue, color: AppColors.inn)),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                child: Row(children: [
                  Expanded(
                    child: SummaryCard(
                        label: 'সম্ভাব্য লাভ', amount: saleValue - costValue, color: AppColors.accent, icon: Icons.trending_up),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Row(children: [
                            Icon(Icons.warning_amber, size: 18, color: AppColors.out),
                            SizedBox(width: 6),
                            Text('কম স্টক'),
                          ]),
                          const SizedBox(height: 6),
                          Text('${bn(lowCount)} টি পণ্য',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: lowCount > 0 ? AppColors.out : Colors.black54, fontWeight: FontWeight.w700)),
                        ]),
                      ),
                    ),
                  ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'নাম, ক্যাটাগরি বা বারকোড দিয়ে খুঁজুন',
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _query = v.trim()),
                ),
              ),
              for (final p in items) ...[
                _ProductTile(product: p, onTap: () => _open(p), onAdjust: (d) => _adjust(p, d)),
                const Divider(height: 1),
              ],
            ],
          );
        },
      ),
    );
  }
}

String _qty(double v) => bn(v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2));

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product, required this.onTap, required this.onAdjust});
  final Product product;
  final VoidCallback onTap;
  final ValueChanged<double> onAdjust;

  @override
  Widget build(BuildContext context) {
    final p = product;
    final img = p.coverImage;
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 56,
                height: 56,
                child: img == null
                    ? Container(
                        color: AppColors.brand.withValues(alpha: 0.1),
                        child: const Icon(Icons.inventory_2, color: AppColors.brand),
                      )
                    : Image.file(
                        File(img),
                        fit: BoxFit.cover,
                        cacheWidth: 150,
                        errorBuilder: (_, __, ___) => Container(color: Colors.black12, child: const Icon(Icons.broken_image)),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 2),
                Text(
                  'বিক্রয় ${taka(p.price)}${p.costPrice > 0 ? '  ·  ক্রয় ${taka(p.costPrice)}' : ''}',
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
                if (p.costPrice > 0)
                  Text(
                    p.unitProfit >= 0 ? 'লাভ ${taka(p.unitProfit)} / ${p.unit}' : 'লোকসান ${taka(-p.unitProfit)} / ${p.unit}',
                    style: TextStyle(fontSize: 12, color: p.unitProfit >= 0 ? AppColors.inn : AppColors.out),
                  ),
                if (p.category.isNotEmpty)
                  Text(p.category, style: const TextStyle(fontSize: 12, color: Colors.black45)),
              ]),
            ),
            Column(mainAxisSize: MainAxisSize.min, children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: p.stock > 0 ? () => onAdjust(-1) : null,
                ),
                Text(
                  _qty(p.stock),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: p.isLow ? AppColors.out : Colors.black87),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => onAdjust(1),
                ),
              ]),
              Text(p.unit, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ]),
          ]),
        ),
      ),
    );
  }
}
