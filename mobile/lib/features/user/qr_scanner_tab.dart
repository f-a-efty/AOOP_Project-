import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class QrScannerTab extends StatefulWidget {
  const QrScannerTab({super.key});

  @override
  State<QrScannerTab> createState() => _QrScannerTabState();
}

class _QrScannerTabState extends State<QrScannerTab> {
  final _sessionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const Icon(Icons.qr_code_scanner_rounded, size: 80, color: AppTheme.primary),
          const SizedBox(height: 16),
          const Text('Scan Booth Dynamic QR Code', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'Point your camera at the Smart Booth screen to link your deposit session.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.muted),
          ),
          const SizedBox(height: 32),

          // Simulated Scanner Frame
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.subtle,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.accent, width: 2),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.center_focus_weak_rounded, size: 64, color: AppTheme.primary),
                  SizedBox(height: 12),
                  Text('Align QR Code inside box', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primary)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          const Text('Or Enter Hardware Session ID (Dev Testing):', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _sessionController,
            decoration: const InputDecoration(hintText: 'e.g. DS-88102A'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Linked deposit session! Insert plastic in booth scale.')),
              );
            },
            child: const Text('Connect Deposit Session'),
          ),
        ],
      ),
    );
  }
}
