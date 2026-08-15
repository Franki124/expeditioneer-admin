import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/admin_journal.dart';
import '../domain/quiz_question.dart';

class JournalRepository {
  JournalRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _journals(String eventId) =>
      _firestore.collection('events').doc(eventId).collection('journals');

  DocumentReference<Map<String, dynamic>> _eventDoc(String eventId) =>
      _firestore.collection('events').doc(eventId);

  Stream<List<AdminJournal>> watchJournals(String eventId) {
    return _journals(eventId).orderBy('order').snapshots().map(
          (snapshot) => snapshot.docs.map(AdminJournal.fromDoc).toList(),
        );
  }

  Stream<List<QuizQuestion>> watchQuestions(String eventId, String journalId) {
    return _journals(eventId).doc(journalId).collection('questions').orderBy('order').snapshots().map(
          (snapshot) => snapshot.docs.map(QuizQuestion.fromDoc).toList(),
        );
  }

  /// Creates a quest and increments the parent event's denormalized
  /// journalCount in the same transaction — nothing else maintains that
  /// field once quests are added outside the seed script.
  Future<void> createJournal({
    required String eventId,
    required String title,
    required String blurb,
    required int order,
    required String artUrl,
    required String type,
    String? model3dUrl,
    required String manualCode,
    int points = 10,
  }) async {
    final journalRef = _journals(eventId).doc();
    final eventRef = _eventDoc(eventId);

    await _firestore.runTransaction((transaction) async {
      transaction.set(journalRef, {
        'title': title,
        'blurb': blurb,
        'order': order,
        'artUrl': artUrl,
        'type': type,
        'model3dUrl': model3dUrl,
        'manualCode': manualCode,
        'qrToken': journalRef.id,
        'scanCount': 0,
        'points': points,
      });
      transaction.update(eventRef, {'journalCount': FieldValue.increment(1)});
    });
  }

  Future<void> updateJournal({
    required String eventId,
    required String journalId,
    required String title,
    required String blurb,
    required int order,
    required String artUrl,
    required String type,
    String? model3dUrl,
    String? manualCode,
    int points = 10,
  }) {
    return _journals(eventId).doc(journalId).update({
      'title': title,
      'blurb': blurb,
      'order': order,
      'artUrl': artUrl,
      'type': type,
      'model3dUrl': model3dUrl,
      'manualCode': manualCode,
      'points': points,
    });
  }

  /// Creates a quiz: the journal doc (`type: 'quiz'`, `questionCount`/
  /// `points` computed from [questions]) plus one doc per question in its
  /// `questions` subcollection, all in one batch, and increments the parent
  /// event's `journalCount` same as `createJournal`.
  Future<void> createQuiz({
    required String eventId,
    required String title,
    required String blurb,
    required int order,
    required String difficulty,
    int? timerSeconds,
    required String manualCode,
    required List<QuizQuestion> questions,
  }) async {
    final journalRef = _journals(eventId).doc();
    final eventRef = _eventDoc(eventId);
    final batch = _firestore.batch();

    batch.set(journalRef, {
      'title': title,
      'blurb': blurb,
      'order': order,
      'artUrl': '',
      'type': 'quiz',
      'model3dUrl': null,
      'manualCode': manualCode,
      'qrToken': journalRef.id,
      'scanCount': 0,
      'points': questions.fold<int>(0, (total, q) => total + q.points),
      'difficulty': difficulty,
      'timerSeconds': timerSeconds,
      'questionCount': questions.length,
    });
    for (final question in questions) {
      batch.set(journalRef.collection('questions').doc(), question.toMap());
    }
    batch.update(eventRef, {'journalCount': FieldValue.increment(1)});
    await batch.commit();
  }

  /// Replaces a quiz's questions wholesale: deletes every existing question
  /// doc and writes [questions] fresh. Simpler and safer than trying to diff
  /// edits/reorders/deletes against the previous set, and the builder always
  /// has the full current list in memory anyway.
  Future<void> updateQuiz({
    required String eventId,
    required String journalId,
    required String title,
    required String blurb,
    required int order,
    required String difficulty,
    int? timerSeconds,
    String? manualCode,
    required List<QuizQuestion> questions,
  }) async {
    final journalRef = _journals(eventId).doc(journalId);
    final existing = await journalRef.collection('questions').get();
    final batch = _firestore.batch();

    for (final doc in existing.docs) {
      batch.delete(doc.reference);
    }
    for (final question in questions) {
      batch.set(journalRef.collection('questions').doc(), question.toMap());
    }
    batch.update(journalRef, {
      'title': title,
      'blurb': blurb,
      'order': order,
      'manualCode': manualCode,
      'points': questions.fold<int>(0, (total, q) => total + q.points),
      'difficulty': difficulty,
      'timerSeconds': timerSeconds,
      'questionCount': questions.length,
    });
    await batch.commit();
  }

  /// Persists a new drag-and-drop order for an event's quests: batch-writes
  /// each quest's `order` to its index in [orderedJournalIds].
  Future<void> reorderJournals({required String eventId, required List<String> orderedJournalIds}) async {
    final batch = _firestore.batch();
    for (var i = 0; i < orderedJournalIds.length; i++) {
      batch.update(_journals(eventId).doc(orderedJournalIds[i]), {'order': i});
    }
    await batch.commit();
  }

  Future<void> deleteJournal({required String eventId, required String journalId}) async {
    final journalRef = _journals(eventId).doc(journalId);
    final eventRef = _eventDoc(eventId);
    // A quiz's questions subcollection isn't cleaned up by deleting its
    // parent doc — Firestore doesn't cascade. Harmless no-op for non-quiz
    // quests (empty subcollection).
    final questionsSnapshot = await journalRef.collection('questions').get();

    await _firestore.runTransaction((transaction) async {
      for (final doc in questionsSnapshot.docs) {
        transaction.delete(doc.reference);
      }
      transaction.delete(journalRef);
      transaction.update(eventRef, {'journalCount': FieldValue.increment(-1)});
    });
  }
}
