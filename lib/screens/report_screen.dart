import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../db/database.dart';
import '../format.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/brand.dart';
import '../widgets/common.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  /// 0 = আজ, 1 = গত ৭ দিন, 2 = এই মাস
  int _period = 0;
  late Future<Report> _future = _load();

  (DateTime, DateTime) get _range {
    final today = startOfDay(DateTime.now());
    final tomorrow = today.add(const Duration(days: 1));
    switch (_period) {
      case 1:
        return (today.subtract(const Duration(days: 6)), tomorrow);
      case 2:
        return (DateTime(today.year, today.month, 1), tomorrow);
      default:
        return (today, tomorrow);
    }
  }

  Future<Report> _load() {
    final (from, to) = _range;
    return AppDb.instance.report(from, to);
  }

  Future<void> _backup() async {
    // ডেটাবেস ফাইলটা শেয়ার করা হয়: Google Drive, WhatsApp বা Email এ রেখে দিলেই ব্যাকআপ, কোনো খরচ নেই।
    final path = await AppDb.instance.filePath();
    await Share.shareXFiles([XFile(path, name: 'dokani-backup-${DateTime.now().millisecondsSinceEpoch}.db')],
        text: 'দোকানি ব্যাকআপ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: brandAppBar('রিপোর্ট', actions: [
        IconButton(tooltip: 'ব্যাকআপ', icon: const Icon(Icons.backup_outlined), onPressed: _backup),
      ]),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('আজ')),
              ButtonSegment(value: 1, label: Text('৭ দিন')),
              ButtonSegment(value: 2, label: Text('এই মাস')),
            ],
            selected: {_period},
            onSelectionChanged: (s) => setState(() {
              _period = s.first;
              _future = _load();
            }),
          ),
          const SizedBox(height: 12),
          FutureBuilder<Report>(
            future: _future,
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()));
              }
              final r = snap.data!;
              final profit = r.profit;
              return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: AppColors.darkGradient,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.yellow.withValues(alpha: 0.5)),
                  ),
                  child: Row(children: [
                    const BrandLogo(size: 84),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(profit >= 0 ? 'লাভ (বিক্রি - খরচ)' : 'লোকসান (বিক্রি - খরচ)',
                            style: const TextStyle(color: Colors.white70)),
                        const SizedBox(height: 6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            taka(profit.abs()),
                            style: TextStyle(
                              color: profit >= 0 ? AppColors.yellow : AppColors.outOnDark,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ]),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: SummaryCard(label: 'মোট বিক্রি', amount: r.sales, color: AppColors.inn, icon: Icons.shopping_bag)),
                  const SizedBox(width: 8),
                  Expanded(child: SummaryCard(label: 'মোট খরচ', amount: r.expense, color: AppColors.out, icon: Icons.receipt)),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: SummaryCard(label: 'বাকি দিলাম', amount: r.bakiGiven, color: AppColors.out, icon: Icons.arrow_upward)),
                  const SizedBox(width: 8),
                  Expanded(child: SummaryCard(label: 'বাকি আদায়', amount: r.bakiCollected, color: AppColors.inn, icon: Icons.arrow_downward)),
                ]),
                const SizedBox(height: 16),
                Text('এখন পর্যন্ত মোট', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: SummaryCard(label: 'কাস্টমারদের কাছে পাবো', amount: r.totalReceivable, color: AppColors.out)),
                  const SizedBox(width: 8),
                  Expanded(child: SummaryCard(label: 'কাস্টমারদের দেবো', amount: r.totalPayable, color: AppColors.inn)),
                ]),
                const SizedBox(height: 16),
                const Text(
                  'টিপস: উপরের ব্যাকআপ বোতাম চেপে মাঝে মাঝে হিসাবের ফাইল Google Drive বা WhatsApp এ রেখে দিন, যাতে ফোন হারালেও হিসাব থাকে।',
                  style: TextStyle(color: Colors.black54),
                ),
              ]);
            },
          ),
        ],
      ),
    );
  }
}
