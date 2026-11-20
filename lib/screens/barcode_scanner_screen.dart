import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// ক্যামেরা দিয়ে বারকোড/QR পড়ে কোডটা ফেরত দেয়।
class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final _controller = MobileScannerController();
  bool _done = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    for (final b in capture.barcodes) {
      final value = b.rawValue;
      if (value != null && value.isNotEmpty) {
        _done = true;
        Navigator.pop(context, value);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('বারকোড স্ক্যান'),
        actions: [
          IconButton(tooltip: 'ফ্ল্যাশ', icon: const Icon(Icons.flash_on), onPressed: () => _controller.toggleTorch()),
        ],
      ),
      body: Stack(children: [
        MobileScanner(controller: _controller, onDetect: _onDetect),
        Center(
          child: Container(
            width: 260,
            height: 160,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 3),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const Positioned(
          left: 0,
          right: 0,
          bottom: 48,
          child: Text(
            'বারকোডটা বাক্সের ভেতরে ধরুন',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 16, shadows: [Shadow(blurRadius: 4)]),
          ),
        ),
      ]),
    );
  }
}
