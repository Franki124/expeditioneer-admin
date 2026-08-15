import 'package:cloud_firestore/cloud_firestore.dart';

/// `AdminJournal.type` values. Mirrors `QuestType` in the player app's
/// `Journal` model — kept as a separate const class here since the two apps
/// don't share a package, same pattern as the rest of the domain layer.
class QuestType {
  QuestType._();

  static const journal = 'journal';
  static const gestral = 'gestral';
  static const quiz = 'quiz';
}

class AdminJournal {
  const AdminJournal({
    required this.id,
    required this.title,
    required this.blurb,
    required this.order,
    required this.artUrl,
    required this.type,
    this.model3dUrl,
    this.manualCode,
    this.scanCount = 0,
    this.points = 10,
    this.difficulty,
    this.timerSeconds,
    this.questionCount = 0,
  });

  final String id;
  final String title;
  final String blurb;
  final int order;
  final String artUrl;
  final String type;
  final String? model3dUrl;
  final String? manualCode;
  final int scanCount;
  final int points;
  final String? difficulty;
  final int? timerSeconds;
  final int questionCount;

  /// A quest's QR can't be generated until it has real content attached —
  /// matches the design's explicit "only quests with a generated QR count
  /// as collectible tasks" rule. For quizzes that's "at least one question"
  /// rather than an image/model.
  bool get hasAsset => switch (type) {
        QuestType.gestral => model3dUrl?.isNotEmpty ?? false,
        QuestType.quiz => questionCount > 0,
        _ => artUrl.isNotEmpty,
      };

  factory AdminJournal.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return AdminJournal(
      id: doc.id,
      title: data['title'] as String? ?? '',
      blurb: data['blurb'] as String? ?? '',
      order: (data['order'] as num?)?.toInt() ?? 0,
      artUrl: data['artUrl'] as String? ?? '',
      type: data['type'] as String? ?? QuestType.journal,
      model3dUrl: data['model3dUrl'] as String?,
      manualCode: data['manualCode'] as String?,
      scanCount: (data['scanCount'] as num?)?.toInt() ?? 0,
      points: (data['points'] as num?)?.toInt() ?? 10,
      difficulty: data['difficulty'] as String?,
      timerSeconds: (data['timerSeconds'] as num?)?.toInt(),
      questionCount: (data['questionCount'] as num?)?.toInt() ?? 0,
    );
  }
}
