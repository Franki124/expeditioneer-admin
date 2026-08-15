import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/web/browser_download.dart';
import '../../events/domain/admin_journal.dart';

/// Phase-1 "cut-sheet": a printable grid of QR codes for every quest that
/// has an asset attached, via the browser's own print dialog.
class QuestQrPrintSheet extends StatelessWidget {
  const QuestQrPrintSheet({super.key, required this.journals, required this.eventName});

  final List<AdminJournal> journals;
  final String eventName;

  @override
  Widget build(BuildContext context) {
    final printable = journals.where((j) => j.hasAsset && j.manualCode != null).toList();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Text('Print QR codes — $eventName'),
        actions: [
          IconButton(icon: const Icon(Icons.print), tooltip: 'Print', onPressed: printCurrentPage),
        ],
      ),
      body: printable.isEmpty
          ? const Center(child: Text('No quests with an attached asset yet.', style: TextStyle(color: Colors.black54)))
          : Padding(
              padding: const EdgeInsets.all(24),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 24,
                  crossAxisSpacing: 24,
                  childAspectRatio: 0.8,
                ),
                itemCount: printable.length,
                itemBuilder: (context, index) {
                  final journal = printable[index];
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      QrImageView(data: journal.manualCode!, size: 140),
                      const SizedBox(height: 8),
                      Text(
                        journal.title,
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        journal.manualCode!,
                        style: const TextStyle(color: Colors.black87, fontFamily: 'monospace'),
                      ),
                    ],
                  );
                },
              ),
            ),
    );
  }
}
