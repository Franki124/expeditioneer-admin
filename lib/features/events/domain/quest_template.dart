import 'package:cloud_firestore/cloud_firestore.dart';

import 'admin_journal.dart' show QuestType;

/// A reusable quest definition, kept independent of any specific event.
/// Picking one in the Quests tab *copies* its fields into a fresh
/// `journals/{id}` doc (with a freshly generated manualCode) — the event's
/// quest never links back to this template, so editing/deleting a template
/// later can't retroactively change quests already created from it. For
/// `type == QuestType.quiz`, the template's questions live in this doc's own
/// `questions` subcollection (see `QuestLibraryRepository.copyQuestions`),
/// copied the same way at attach time.
class QuestTemplate {
  const QuestTemplate({
    required this.id,
    required this.title,
    required this.blurb,
    required this.type,
    this.artUrl = '',
    this.model3dUrl,
    this.points = 10,
    this.difficulty,
    this.timerSeconds,
    this.questionCount = 0,
  });

  final String id;
  final String title;
  final String blurb;
  final String type;
  final String artUrl;
  final String? model3dUrl;
  final int points;
  final String? difficulty;
  final int? timerSeconds;
  final int questionCount;

  factory QuestTemplate.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return QuestTemplate(
      id: doc.id,
      title: data['title'] as String? ?? '',
      blurb: data['blurb'] as String? ?? '',
      type: data['type'] as String? ?? QuestType.journal,
      artUrl: data['artUrl'] as String? ?? '',
      model3dUrl: data['model3dUrl'] as String?,
      points: (data['points'] as num?)?.toInt() ?? 10,
      difficulty: data['difficulty'] as String?,
      timerSeconds: (data['timerSeconds'] as num?)?.toInt(),
      questionCount: (data['questionCount'] as num?)?.toInt() ?? 0,
    );
  }
}
