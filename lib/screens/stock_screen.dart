import 'package:flutter/material.dart';

import '../db/database.dart';
import '../format.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// পণ্যের তালিকা, দাম আর কতটা স্টকে আছে।
class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  late Future<List<Product>> _future = AppDb.instance.products();

  void _reload() => setState(() => _future = AppDb.instance.products());

  Future<void> _edit([Product? existing]) async {
    final result = await showDialog<_ProductAction>(
      context: context,
      builder: (_) => _ProductDialog(existing: existing),
    );
    if (result == null) return;
    if (result.delete && existing?.id != null) {
      if (!mounted || !await confirm(context, '${existing!.name} মুছে ফেলবেন?')) return;
      await AppDb.instance.deleteProduct(existing!.id!);
    } else if (result.product != null) {
      await AppDb.instance.saveProduct(result.product!);
    }
    _reload();
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
        onPressed: () => _edit(),
        icon: const Icon(Icons.add),
        label: const Text('পণ্য যোগ'),
      ),
      body: FutureBuilder<List<Product>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final items = snap.data!;
          if (items.isEmpty) {
            return const EmptyState(icon: Icons.inventory_2_outlined, message: 'এখনো কোনো পণ্য যোগ করা হয়নি');
          }
          final lowCount = items.where((p) => p.isLow).length;
          final value = items.fold<double>(0, (s, p) => s + p.price * p.stock);
          return ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  Expanded(child: SummaryCard(label: 'স্টকের মোট মূল্য', amount: value, color: AppColors.brand, icon: Icons.inventory)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('কম স্টক'),
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
              for (final p in items) ...[
                ListTile(
                  tileColor: Colors.white,
                  onTap: () => _edit(p),
                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('দাম ${taka(p.price)}'),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: p.stock > 0 ? () => _adjust(p, -1) : null),
                    SizedBox(
                      width: 48,
                      child: Text(
                        bn(_qty(p.stock)),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: p.isLow ? AppColors.out : Colors.black87,
                        ),
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => _adjust(p, 1)),
                  ]),
                ),
                const Divider(height: 1),
              ],
            ],
          );
        },
      ),
    );
  }
}

String _qty(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

class _ProductAction {
  const _ProductAction({this.product, this.delete = false});
  final Product? product;
  final bool delete;
}

class _ProductDialog extends StatefulWidget {
  const _ProductDialog({this.existing});
  final Product? existing;

  @override
  State<_ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<_ProductDialog> {
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _price = TextEditingController(text: widget.existing == null ? '' : _qty(widget.existing!.price));
  late final _stock = TextEditingController(text: widget.existing == null ? '' : _qty(widget.existing!.stock));
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _stock.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'পণ্যের নাম লিখুন');
      return;
    }
    Navigator.pop(
      context,
      _ProductAction(
        product: Product(
          id: widget.existing?.id,
          name: name,
          price: parseAmount(_price.text) ?? 0,
          stock: parseAmount(_stock.text) ?? 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const numKeyboard = TextInputType.numberWithOptions(decimal: true);
    return AlertDialog(
      title: Text(widget.existing == null ? 'নতুন পণ্য' : 'পণ্য এডিট'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: _name, autofocus: true, decoration: InputDecoration(labelText: 'পণ্যের নাম', errorText: _error)),
        const SizedBox(height: 12),
        TextField(controller: _price, keyboardType: numKeyboard, decoration: const InputDecoration(labelText: 'বিক্রয় মূল্য', prefixText: '৳ ')),
        const SizedBox(height: 12),
        TextField(controller: _stock, keyboardType: numKeyboard, decoration: const InputDecoration(labelText: 'স্টকে আছে (পরিমাণ)')),
      ]),
      actions: [
        if (widget.existing != null)
          TextButton(
            onPressed: () => Navigator.pop(context, const _ProductAction(delete: true)),
            child: Text('মুছুন', style: TextStyle(color: Colors.red.shade700)),
          ),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('বাতিল')),
        FilledButton(onPressed: _save, child: const Text('সেভ')),
      ],
    );
  }
}
