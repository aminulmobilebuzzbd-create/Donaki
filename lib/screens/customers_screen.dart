import 'package:flutter/material.dart';

import '../db/database.dart';
import '../format.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'customer_detail_screen.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  late Future<List<Customer>> _future = AppDb.instance.customers();
  String _query = '';

  void _reload() => setState(() => _future = AppDb.instance.customers());

  Future<void> _add() async {
    final result = await showCustomerDialog(context);
    if (result == null) return;
    final id = await AppDb.instance.addCustomer(result.name, result.phone);
    if (!mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerDetailScreen(customerId: id)));
    _reload();
  }

  Future<void> _open(Customer c) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerDetailScreen(customerId: c.id)));
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('দোকানি · বাকি খাতা')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('কাস্টমার যোগ'),
      ),
      body: FutureBuilder<List<Customer>>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('সমস্যা হয়েছে: ${snap.error}'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());

          final all = snap.data!;
          double receivable = 0, payable = 0;
          for (final c in all) {
            if (c.balance > 0) receivable += c.balance;
            if (c.balance < 0) payable += -c.balance;
          }
          final q = _query.toLowerCase();
          final list = q.isEmpty
              ? all
              : all.where((c) => c.name.toLowerCase().contains(q) || (c.phone ?? '').contains(q)).toList();

          return Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Row(children: [
                Expanded(child: SummaryCard(label: 'মোট পাবো', amount: receivable, color: AppColors.out, icon: Icons.call_received)),
                const SizedBox(width: 8),
                Expanded(child: SummaryCard(label: 'মোট দেবো', amount: payable, color: AppColors.inn, icon: Icons.call_made)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'নাম বা ফোন নম্বর দিয়ে খুঁজুন',
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _query = v.trim()),
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? EmptyState(
                      icon: Icons.people_outline,
                      message: all.isEmpty ? 'এখনো কোনো কাস্টমার নেই।\nনিচের বোতাম চেপে প্রথম কাস্টমার যোগ করুন।' : 'কাউকে পাওয়া যায়নি',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 96),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                      itemBuilder: (context, i) => _CustomerTile(customer: list[i], onTap: () => _open(list[i])),
                    ),
            ),
          ]);
        },
      ),
    );
  }
}

class _CustomerTile extends StatelessWidget {
  const _CustomerTile({required this.customer, required this.onTap});
  final Customer customer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final b = customer.balance;
    final color = b > 0 ? AppColors.out : (b < 0 ? AppColors.inn : Colors.black45);
    final label = b > 0 ? 'পাবো' : (b < 0 ? 'দেবো' : 'হিসাব মিল');
    return ListTile(
      onTap: onTap,
      tileColor: Colors.white,
      leading: CircleAvatar(
        backgroundColor: AppColors.brand.withValues(alpha: 0.12),
        child: Text(customer.name.characters.first, style: const TextStyle(color: AppColors.brand, fontWeight: FontWeight.bold)),
      ),
      title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: customer.hasPhone ? Text(bn(customer.phone!)) : null,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(taka(b.abs()), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}

class CustomerInput {
  const CustomerInput(this.name, this.phone);
  final String name;
  final String? phone;
}

Future<CustomerInput?> showCustomerDialog(BuildContext context, {Customer? existing}) {
  return showDialog<CustomerInput>(context: context, builder: (_) => _CustomerDialog(existing: existing));
}

class _CustomerDialog extends StatefulWidget {
  const _CustomerDialog({this.existing});
  final Customer? existing;

  @override
  State<_CustomerDialog> createState() => _CustomerDialogState();
}

class _CustomerDialogState extends State<_CustomerDialog> {
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _phone = TextEditingController(text: widget.existing?.phone);
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'নাম লিখুন');
      return;
    }
    final phone = _phone.text.trim();
    Navigator.pop(context, CustomerInput(name, phone.isEmpty ? null : phone));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'নতুন কাস্টমার' : 'কাস্টমার এডিট'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(
          controller: _name,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(labelText: 'নাম', errorText: _error),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'মোবাইল নম্বর (ঐচ্ছিক)', hintText: '01XXXXXXXXX'),
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('বাতিল')),
        FilledButton(onPressed: _save, child: const Text('সেভ')),
      ],
    );
  }
}
