import 'package:flutter/material.dart';

import '../format.dart';

class AmountResult {
  const AmountResult(this.amount, this.note, this.date);
  final double amount;
  final String note;
  final DateTime date;
}

/// টাকা, নোট আর তারিখ নেওয়ার বটম শিট। দিলাম/পেলাম/বিক্রি/খরচ সব জায়গায় একই ফর্ম।
Future<AmountResult?> showAmountSheet(
  BuildContext context, {
  required String title,
  required Color color,
  String noteHint = 'বিবরণ (ঐচ্ছিক)',
}) {
  return showModalBottomSheet<AmountResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _AmountSheet(title: title, color: color, noteHint: noteHint),
  );
}

class _AmountSheet extends StatefulWidget {
  const _AmountSheet({required this.title, required this.color, required this.noteHint});
  final String title;
  final Color color;
  final String noteHint;

  @override
  State<_AmountSheet> createState() => _AmountSheetState();
}

class _AmountSheetState extends State<_AmountSheet> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  DateTime _date = DateTime.now();
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _save() {
    final value = parseAmount(_amount.text);
    if (value == null || value <= 0) {
      setState(() => _error = 'সঠিক টাকার পরিমাণ লিখুন');
      return;
    }
    Navigator.pop(context, AmountResult(value, _note.text.trim(), _date));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2015),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => _date = DateTime(picked.year, picked.month, picked.day, _date.hour, _date.minute));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: widget.color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _amount,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: Theme.of(context).textTheme.headlineSmall,
            decoration: InputDecoration(prefixText: '৳ ', labelText: 'টাকার পরিমাণ', errorText: _error),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 12),
          TextField(controller: _note, decoration: InputDecoration(labelText: widget.noteHint)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(dateBn(_date)),
          ),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: widget.color,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _save,
            child: const Text('সেভ করুন', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
