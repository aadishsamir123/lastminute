import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/homework.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser!.uid;

  CollectionReference get _homeworkCollection =>
      _firestore.collection('homework');

  // Create
  Future<String> createHomework(Homework homework) async {
    try {
      final doc = await _homeworkCollection.add(homework.toFirestore());
      return doc.id;
    } catch (e, stackTrace) {
      print('❌ ERROR creating homework: $e');
      print('📋 Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Read - stream all homework for current user 
  Stream<List<Homework>> getHomeworkStream() {
    return _homeworkCollection
        .where('userId', isEqualTo: _userId)
        .orderBy('dueDate')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Homework.fromFirestore(doc)).toList(),
        );
  }

  // Read - get homework by date range
  Stream<List<Homework>> getHomeworkByDateRange(DateTime start, DateTime end) {
    return _homeworkCollection
        .where('userId', isEqualTo: _userId)
        .where('dueDate', isGreaterThanOrEqualTo: start)
        .where('dueDate', isLessThanOrEqualTo: end)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Homework.fromFirestore(doc)).toList(),
        );
  }

  // Read - get incomplete homework
  Stream<List<Homework>> getIncompleteHomework() {
    return _homeworkCollection
        .where('userId', isEqualTo: _userId)
        .where('isCompleted', isEqualTo: false)
        .orderBy('dueDate')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Homework.fromFirestore(doc)).toList(),
        );
  }

  // Update
  Future<void> updateHomework(Homework homework) async {
    try {
      await _homeworkCollection.doc(homework.id).update(homework.toFirestore());
    } catch (e, stackTrace) {
      print('❌ ERROR updating homework: $e');
      print('📋 Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Delete
  Future<void> deleteHomework(String homeworkId) async {
    try {
      await _homeworkCollection.doc(homeworkId).delete();
    } catch (e, stackTrace) {
      print('❌ ERROR deleting homework: $e');
      print('📋 Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Toggle completion
  Future<void> toggleCompletion(String homeworkId, bool isCompleted) async {
    try {
      await _homeworkCollection.doc(homeworkId).update({
        'isCompleted': isCompleted,
        'completedAt': isCompleted ? Timestamp.now() : null,
      });
    } catch (e, stackTrace) {
      print('❌ ERROR toggling homework completion: $e');
      print('📋 Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Get stats
  Future<Map<String, int>> getStats() async {
    final snapshot = await _homeworkCollection
        .where('userId', isEqualTo: _userId)
        .get();

    int total = snapshot.docs.length;
    int completed = 0;
    int overdue = 0;
    final now = DateTime.now();

    for (var doc in snapshot.docs) {
      final homework = Homework.fromFirestore(doc);
      if (homework.isCompleted) {
        completed++;
      } else if (homework.dueDate.isBefore(now)) {
        overdue++;
      }
    }

    return {
      'total': total,
      'completed': completed,
      'overdue': overdue,
      'pending': total - completed - overdue,
    };
  }
}
