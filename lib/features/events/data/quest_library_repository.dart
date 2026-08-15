import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/quest_template.dart';
import '../domain/quiz_question.dart';

class QuestLibraryRepository {
  QuestLibraryRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _templates => _firestore.collection('questLibrary');

  Stream<List<QuestTemplate>> watchAll() {
    return _templates.orderBy('title').snapshots().map(
          (snapshot) => snapshot.docs.map(QuestTemplate.fromDoc).toList(),
        );
  }

  Future<void> addEntry({
    required String title,
    required String blurb,
    required String type,
    required String artUrl,
    String? model3dUrl,
    int points = 10,
  }) {
    return _templates.add({
      'title': title,
      'blurb': blurb,
      'type': type,
      'artUrl': artUrl,
      'model3dUrl': model3dUrl,
      'points': points,
    });
  }

  /// Saves a quiz template: the parent doc plus one doc per question in its
  /// own `questions` subcollection, mirroring how a quiz journal itself is
  /// structured under `events/{eventId}/journals/{journalId}/questions`.
  Future<void> addQuizEntry({
    required String title,
    required String blurb,
    required String? difficulty,
    required int? timerSeconds,
    required List<QuizQuestion> questions,
  }) async {
    final templateRef = _templates.doc();
    final batch = _firestore.batch();
    batch.set(templateRef, {
      'title': title,
      'blurb': blurb,
      'type': 'quiz',
      'difficulty': difficulty,
      'timerSeconds': timerSeconds,
      'questionCount': questions.length,
      'points': questions.fold<int>(0, (total, q) => total + q.points),
    });
    for (final question in questions) {
      batch.set(templateRef.collection('questions').doc(), question.toMap());
    }
    await batch.commit();
  }

  Future<List<QuizQuestion>> copyQuestions(String templateId) async {
    final snapshot = await _templates.doc(templateId).collection('questions').orderBy('order').get();
    return snapshot.docs.map(QuizQuestion.fromDoc).toList();
  }

  Future<void> deleteEntry(String id) async {
    final questionsSnapshot = await _templates.doc(id).collection('questions').get();
    final batch = _firestore.batch();
    for (final doc in questionsSnapshot.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_templates.doc(id));
    await batch.commit();
  }
}
