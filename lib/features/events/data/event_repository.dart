import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/admin_event.dart';

const _joinCodeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no 0/O/1/I
const _joinCodeLength = 6;
const _maxJoinCodeAttempts = 8;

class EventRepository {
  EventRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final Random _random = Random.secure();

  CollectionReference<Map<String, dynamic>> get _events => _firestore.collection('events');
  CollectionReference<Map<String, dynamic>> get _joinCodes => _firestore.collection('joinCodes');

  Stream<List<AdminEvent>> watchAllEvents() {
    return _events.orderBy('createdAt', descending: true).snapshots().map(
          (snapshot) => snapshot.docs.map(AdminEvent.fromDoc).toList(),
        );
  }

  Stream<AdminEvent?> watchEvent(String eventId) {
    return _events.doc(eventId).snapshots().map((doc) => doc.exists ? AdminEvent.fromDoc(doc) : null);
  }

  String _generateJoinCode() {
    return List.generate(
      _joinCodeLength,
      (_) => _joinCodeChars[_random.nextInt(_joinCodeChars.length)],
    ).join();
  }

  /// Creates a new draft event with a globally-unique join code. Collisions
  /// are vanishingly unlikely (6 chars from a 32-char alphabet) but are
  /// retried internally via the same reservation-doc pattern as
  /// ParticipantRepository.joinEvent's display-name uniqueness, so the wizard
  /// never has to surface a "code taken" error to the admin.
  Future<String> createEvent({
    required String name,
    required String location,
    required DateTime startAt,
    required DateTime endAt,
    required String createdBy,
    int? maxParticipants,
  }) async {
    for (var attempt = 0; attempt < _maxJoinCodeAttempts; attempt++) {
      final joinCode = _generateJoinCode();
      final eventRef = _events.doc();
      final joinCodeRef = _joinCodes.doc(joinCode);

      final created = await _firestore.runTransaction<bool>((transaction) async {
        final joinCodeSnapshot = await transaction.get(joinCodeRef);
        if (joinCodeSnapshot.exists) return false;

        transaction.set(eventRef, {
          'name': name,
          'location': location,
          'joinCode': joinCode,
          'startAt': Timestamp.fromDate(startAt),
          'endAt': Timestamp.fromDate(endAt),
          'status': 'draft',
          'maxParticipants': maxParticipants,
          'journalCount': 0,
          'createdBy': createdBy,
          'createdAt': FieldValue.serverTimestamp(),
        });
        transaction.set(joinCodeRef, {'eventId': eventRef.id});
        return true;
      });

      if (created) return eventRef.id;
    }
    throw StateError('Could not generate a unique join code after several attempts.');
  }

  Future<void> updateDetails({
    required String eventId,
    required String name,
    required String location,
    required DateTime startAt,
    required DateTime endAt,
    int? maxParticipants,
  }) {
    return _events.doc(eventId).update({
      'name': name,
      'location': location,
      'startAt': Timestamp.fromDate(startAt),
      'endAt': Timestamp.fromDate(endAt),
      'maxParticipants': maxParticipants,
    });
  }

  Future<void> updateStatus(String eventId, String status) {
    return _events.doc(eventId).update({'status': status});
  }

  /// Deletes the event and its quests. Participant/scan/name-reservation
  /// subcollections are intentionally left in place — Firestore rules keep
  /// scans immutable (leaderboard integrity) even for admins, and orphaned
  /// docs under a deleted event are harmless dead data. Archive is the
  /// expected everyday action; Delete is for cleaning up test/mistaken events.
  Future<void> deleteEvent(String eventId) async {
    final journalsSnapshot = await _events.doc(eventId).collection('journals').get();
    final batch = _firestore.batch();
    for (final doc in journalsSnapshot.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_events.doc(eventId));
    await batch.commit();
  }
}
