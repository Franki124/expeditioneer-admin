import 'dart:convert';
import 'dart:typed_data';

import '../../features/events/domain/admin_participant.dart';
import 'browser_download.dart';

void exportParticipantsCsv({required String eventName, required List<AdminParticipant> participants}) {
  final buffer = StringBuffer('Rank,Name,Points,Quests Collected,Last Scan,Joined\n');
  for (var i = 0; i < participants.length; i++) {
    final participant = participants[i];
    buffer.writeln([
      '${i + 1}',
      _escape(participant.displayName),
      '${participant.totalPoints}',
      '${participant.collectedCount}',
      participant.lastScanAt?.toIso8601String() ?? '',
      participant.joinedAt.toIso8601String(),
    ].join(','));
  }
  downloadBytes(
    bytes: Uint8List.fromList(utf8.encode(buffer.toString())),
    filename: '${_safeFilename(eventName)}-leaderboard.csv',
    mimeType: 'text/csv',
  );
}

String _escape(String value) {
  if (value.contains(',') || value.contains('"') || value.contains('\n')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}

String _safeFilename(String raw) => raw.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
