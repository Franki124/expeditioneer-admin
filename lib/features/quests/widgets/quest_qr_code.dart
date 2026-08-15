import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/web/browser_download.dart';
import '../../../theme/colors.dart';
import '../../../theme/radii.dart';
import '../../../theme/typography.dart';

class QuestQrCode extends StatelessWidget {
  const QuestQrCode({super.key, required this.data, required this.title, this.size = 96});

  final String data;
  final String title;
  final double size;

  Future<void> _download() async {
    final painter = QrPainter(data: data, version: QrVersions.auto, gapless: true);
    final imageData = await painter.toImageData(1024, format: ui.ImageByteFormat.png);
    if (imageData == null) return;
    downloadBytes(
      bytes: imageData.buffer.asUint8List(),
      filename: '${_safeFilename(title)}-qr.png',
      mimeType: 'image/png',
    );
  }

  String _safeFilename(String raw) => raw.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadii.buttonSmall),
          ),
          // Only the white margin gets rounded, not the QR pattern itself —
          // clipping the code's own corners risks biting into its finder
          // patterns and hurting scannability.
          child: QrImageView(data: data, size: size, gapless: true),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: size + 16,
          child: OutlinedButton.icon(
            onPressed: _download,
            icon: const Icon(Icons.download, size: 16),
            label: const Text('Download'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.cream,
              side: BorderSide(color: AppColors.cream.withValues(alpha: 0.4)),
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: AppRadii.button),
              textStyle: AppTypography.body(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}
