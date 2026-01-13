import 'package:cloud_firestore/cloud_firestore.dart';

enum Priority { low, medium, high, urgent }

class Homework {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final String? subject;
  final DateTime dueDate;
  final Priority priority;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;
  final List<DateTime> reminderTimes;

  const Homework({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.subject,
    required this.dueDate,
    required this.priority,
    required this.isCompleted,
    required this.createdAt,
    this.completedAt,
    this.reminderTimes = const [],
  });

  factory Homework.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Homework(
      id: doc.id,
      userId: data['userId'] as String,
      title: data['title'] as String,
      description: data['description'] as String?,
      subject: data['subject'] as String?,
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      priority: Priority.values[data['priority'] as int? ?? 1],
      isCompleted: data['isCompleted'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      reminderTimes:
          (data['reminderTimes'] as List<dynamic>?)
              ?.map((e) => (e as Timestamp).toDate())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'subject': subject,
      'dueDate': Timestamp.fromDate(dueDate),
      'priority': priority.index,
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'reminderTimes': reminderTimes.map((e) => Timestamp.fromDate(e)).toList(),
    };
  }

  Homework copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? subject,
    DateTime? dueDate,
    Priority? priority,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
    List<DateTime>? reminderTimes,
  }) {
    return Homework(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      subject: subject ?? this.subject,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      reminderTimes: reminderTimes ?? this.reminderTimes,
    );
  }

  bool get isOverdue => !isCompleted && dueDate.isBefore(DateTime.now());

  bool get isDueToday {
    final now = DateTime.now();
    return dueDate.year == now.year &&
        dueDate.month == now.month &&
        dueDate.day == now.day;
  }
}
