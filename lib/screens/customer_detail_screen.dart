import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../db/database.dart';
import '../format.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/amount_sheet.dart';
import '../widgets/common.dart';
import 'customers_screen.dart';

class CustomerDetailScreen extends StatefulWidget {
  const CustomerDetailScreen({super.key, required this.customerId});
  final int customerId;

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  late Future<(Customer?, List<LedgerEntry>)> _future = _load();

  Future<(Customer?, List<LedgerEntry>)> _load() async {
    final db = AppDb.instance;
    return (await db.customer(widget.customerId), await db.ledgerFor(widget.customerId));
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _addEntry(String type) async {
    final gave = type == 'gave';
    final r = await showAmountSheet(
      context,
      title: gave ? 'দিলাম (বাকি দিলাম)' : 'পেলাম (টাকা পেলাম)',
      color: gave ? AppColors.out : AppColors.inn,
      noteHint: gave ? 'কী কী নিল (ঐচ্ছিক)' : 'বিবরণ (ঐচ্ছিক)',
    );
    if (r == null) return;
    await AppDb.instance.addLedger(widget.customerId, type, r.amount, r.note, r.date);
    _reload();
  }

  Future<void> _deleteEntry(LedgerEntry e) async {
    if (!await confirm(context, '${taka(e.amount)} এর এই এন্ট্রিটি মুছে ফেলবেন?')) return;
    await AppDb.instance.deleteLedger(e.id);
    _reload();
  }

  Future<void> _sendReminder(Customer c) async {
    final msg = 'প্রিয় ${c.name}, আপনার কাছে আমাদের দোকানের ${taka(c.balance)} বাকি আছে। '
        'সুবিধামতো সময়ে পরিশোধ করার অনুরোধ রইল। ধন্যবাদ।';
    // ফোনের নিজের SMS অ্যাপ খুলে মেসেজ লিখে দেয়। কোনো SMS গেটওয়ে খরচ নেই।
    final uri = Uri.parse('sms:${c.phone}?body=${Uri.encodeComponent(msg)}');
    if (!await launchUrl(uri) && mounted) toast(context, 'SMS অ্যাপ খোলা যায়নি');
  }

  Future<void> _call(Customer c) async {
    await launchUrl(Uri(scheme: 'tel', path: c.phone));
  }

  Future<void> _edit(Customer c) async {
    final r = await showCustomerDialog(context, existing: c);
    if (r == null) return;
    await AppDb.instance.updateCustomer(c.id, r.name, r.phone);
    _reload();
  }

  Future<void> _delete(Customer c) async {
    if (!await confirm(context, '${c.name} এবং তার সব হিসাব মুছে ফেলবেন? এটা ফেরত আনা যাবে না।')) return;
    await AppDb.instance.deleteCustomer(c.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(Customer?, List<LedgerEntry>)>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) {
          return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
        }
        final (customer, entries) = snap.data!;
        if (customer == null) {
          return Scaffold(appBar: AppBar(), body: const EmptyState(icon: Icons.person_off, message: 'কাস্টমার পাওয়া যায়নি'));
        }
        final b = customer.balance;

        return Scaffold(
          appBar: AppBar(
            title: Text(customer.name),
            actions: [
              if (customer.hasPhone) IconButton(tooltip: 'কল', icon: const Icon(Icons.call), onPressed: () => _call(customer)),
              if (customer.hasPhone && b > 0)
                IconButton(tooltip: 'বাকির রিমাইন্ডার', icon: const Icon(Icons.sms), onPressed: () => _sendReminder(customer)),
              PopupMenuButton<String>(
                onSelected: (v) => v == 'edit' ? _edit(customer) : _delete(customer),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('এডিট')),
                  PopupMenuItem(value: 'delete', child: Text('মুছে ফেলুন')),
                ],
              ),
            ],
          ),
          body: Column(children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                Text(b > 0 ? 'আপনি পাবেন' : (b < 0 ? 'আপনি দেবেন' : 'হিসাব মিলে গেছে'),
                    style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 4),
                Text(
                  taka(b.abs()),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: b > 0 ? AppColors.out : (b < 0 ? AppColors.inn : Colors.black54),
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (customer.hasPhone) ...[
                  const SizedBox(height: 4),
                  Text(bn(customer.phone!), style: const TextStyle(color: Colors.black54)),
                ],
              ]),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(children: [
                Expanded(child: Text('তারিখ ও বিবরণ', style: TextStyle(color: Colors.black54))),
                SizedBox(width: 90, child: Text('দিলাম', textAlign: TextAlign.end, style: TextStyle(color: AppColors.out))),
                SizedBox(width: 90, child: Text('পেলাম', textAlign: TextAlign.end, style: TextStyle(color: AppColors.inn))),
              ]),
            ),
            Expanded(
              child: entries.isEmpty
                  ? const EmptyState(icon: Icons.receipt_long, message: 'এখনো কোনো লেনদেন নেই')
                  : ListView.separated(
                      itemCount: entries.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final e = entries[i];
                        return InkWell(
                          onLongPress: () => _deleteEntry(e),
                          child: Container(
                            color: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            child: Row(children: [
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(dateBn(e.date), style: const TextStyle(fontWeight: FontWeight.w600)),
                                  if (e.note.isNotEmpty)
                                    Text(e.note, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                                ]),
                              ),
                              SizedBox(
                                width: 90,
                                child: Text(e.isGave ? taka(e.amount) : '',
                                    textAlign: TextAlign.end, style: const TextStyle(color: AppColors.out, fontWeight: FontWeight.w600)),
                              ),
                              SizedBox(
                                width: 90,
                                child: Text(e.isGave ? '' : taka(e.amount),
                                    textAlign: TextAlign.end, style: const TextStyle(color: AppColors.inn, fontWeight: FontWeight.w600)),
                              ),
                            ]),
                          ),
                        );
                      },
                    ),
            ),
          ]),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: AppColors.out, padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: () => _addEntry('gave'),
                    icon: const Icon(Icons.arrow_upward),
                    label: const Text('দিলাম'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: AppColors.inn, padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: () => _addEntry('got'),
                    icon: const Icon(Icons.arrow_downward),
                    label: const Text('পেলাম'),
                  ),
                ),
              ]),
            ),
          ),
        );
      },
    );
  }
}
