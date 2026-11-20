import 'package:flutter/material.dart';

import '../db/database.dart';
import '../format.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/amount_sheet.dart';
import '../widgets/brand.dart';
import '../widgets/common.dart';

/// দিনভিত্তিক বিক্রি ও খরচের খাতা।
class CashbookScreen extends StatefulWidget {
  const CashbookScreen({super.key});

  @override
  State<CashbookScreen> createState() => _CashbookScreenState();
}

class _CashbookScreenState extends State<CashbookScreen> {
  DateTime _day = startOfDay(DateTime.now());
  late Future<List<CashEntry>> _future = _load();

  Future<List<CashEntry>> _load() =>
      AppDb.instance.cashBetween(_day, _day.add(const Duration(days: 1)));

  bool get _isToday => _day == startOfDay(DateTime.now());

  void _setDay(DateTime d) => setState(() {
        _day = startOfDay(d);
        _future = _load();
      });

  Future<void> _pickDay() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
    );
    if (d != null) _setDay(d);
  }

  Future<void> _add(String type) async {
    final sale = type == 'sale';
    final r = await showAmountSheet(
      context,
      title: sale ? 'বিক্রি' : 'খরচ',
      color: sale ? AppColors.inn : AppColors.out,
      noteHint: sale ? 'কী বিক্রি হলো (ঐচ্ছিক)' : 'কিসের খরচ, যেমন: ভাড়া, বিদ্যুৎ (ঐচ্ছিক)',
    );
    if (r == null) return;
    await AppDb.instance.addCash(type, r.amount, r.note, r.date);
    _setDay(r.date);
  }

  Future<void> _delete(CashEntry e) async {
    if (!await confirm(context, '${taka(e.amount)} এর এই এন্ট্রিটি মুছে ফেলবেন?')) return;
    await AppDb.instance.deleteCash(e.id);
    _setDay(_day);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: brandAppBar('ক্যাশবক্স'),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => _setDay(_day.subtract(const Duration(days: 1))),
            ),
            Expanded(
              child: TextButton.icon(
                onPressed: _pickDay,
                icon: const Icon(Icons.calendar_today, size: 18),
                label: Text(_isToday ? 'আজ, ${dateBn(_day)}' : dateBn(_day), style: const TextStyle(fontSize: 16)),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _isToday ? null : () => _setDay(_day.add(const Duration(days: 1))),
            ),
          ]),
        ),
        Expanded(
          child: FutureBuilder<List<CashEntry>>(
            future: _future,
            builder: (context, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              final entries = snap.data!;
              double sales = 0, expense = 0;
              for (final e in entries) {
                if (e.isSale) {
                  sales += e.amount;
                } else {
                  expense += e.amount;
                }
              }
              final net = sales - expense;
              return Column(children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(children: [
                    Expanded(child: SummaryCard(label: 'বিক্রি', amount: sales, color: AppColors.inn)),
                    const SizedBox(width: 6),
                    Expanded(child: SummaryCard(label: 'খরচ', amount: expense, color: AppColors.out)),
                    const SizedBox(width: 6),
                    Expanded(child: SummaryCard(label: 'হাতে রইল', amount: net, color: net >= 0 ? AppColors.dark : AppColors.out)),
                  ]),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: entries.isEmpty
                      ? const EmptyState(icon: Icons.point_of_sale, message: 'এই দিনে কোনো বিক্রি বা খরচ লেখা হয়নি')
                      : ListView.separated(
                          itemCount: entries.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final e = entries[i];
                            final color = e.isSale ? AppColors.inn : AppColors.out;
                            return ListTile(
                              tileColor: Colors.white,
                              onLongPress: () => _delete(e),
                              leading: CircleAvatar(
                                backgroundColor: color.withValues(alpha: 0.12),
                                child: Icon(e.isSale ? Icons.shopping_bag : Icons.receipt, color: color),
                              ),
                              title: Text(e.note.isNotEmpty ? e.note : (e.isSale ? 'বিক্রি' : 'খরচ')),
                              subtitle: Text(timeBn(e.date)),
                              trailing: Text(
                                '${e.isSale ? '+' : '-'} ${taka(e.amount)}',
                                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            );
                          },
                        ),
                ),
              ]);
            },
          ),
        ),
      ]),
      bottomNavigationBar: SafeArea(
        child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(children: [
          Expanded(
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.inn, padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: () => _add('sale'),
              icon: const Icon(Icons.add),
              label: const Text('বিক্রি'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.out, padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: () => _add('expense'),
              icon: const Icon(Icons.remove),
              label: const Text('খরচ'),
            ),
          ),
        ]),
        ),
      ),
    );
  }
}
