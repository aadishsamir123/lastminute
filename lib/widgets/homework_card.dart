import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/homework.dart';
import '../screens/homework_detail_screen.dart';
import '../services/firestore_service.dart';

class HomeworkCard extends StatelessWidget {
  const HomeworkCard({super.key, required this.homework});

  final Homework homework;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isOverdue = homework.isOverdue;
    final isDueToday = homework.isDueToday;

    Color priorityColor = switch (homework.priority) {
      Priority.low => Colors.blue,
      Priority.medium => Colors.orange,
      Priority.high => Colors.deepOrange,
      Priority.urgent => Colors.red,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HomeworkDetailScreen(homework: homework),
            ),
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox
              Checkbox(
                value: homework.isCompleted,
                onChanged: (value) {
                  FirestoreService().toggleCompletion(
                    homework.id,
                    value ?? false,
                  );
                },
                shape: const CircleBorder(),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      homework.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        decoration: homework.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    if (homework.subject != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.book_outlined,
                            size: 14,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              homework.subject!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (homework.description != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        homework.description!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    // Due date and priority
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        // Due date chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isOverdue
                                ? colorScheme.errorContainer
                                : isDueToday
                                ? colorScheme.tertiaryContainer
                                : colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isOverdue
                                    ? Icons.error_outline_rounded
                                    : Icons.event_rounded,
                                size: 14,
                                color: isOverdue
                                    ? colorScheme.error
                                    : isDueToday
                                    ? colorScheme.onTertiaryContainer
                                    : colorScheme.onSecondaryContainer,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDueDate(homework.dueDate),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isOverdue
                                      ? colorScheme.error
                                      : isDueToday
                                      ? colorScheme.onTertiaryContainer
                                      : colorScheme.onSecondaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Priority chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: priorityColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.flag_rounded,
                                size: 14,
                                color: priorityColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                homework.priority.name.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: priorityColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly.isBefore(today)) {
      final diff = today.difference(dateOnly).inDays;
      return 'Overdue by $diff day${diff > 1 ? 's' : ''}';
    } else if (dateOnly == today) {
      return 'Due Today • ${DateFormat.jm().format(date)}';
    } else if (dateOnly == tomorrow) {
      return 'Due Tomorrow • ${DateFormat.jm().format(date)}';
    } else {
      return 'Due ${DateFormat.MMMd().format(date)} • ${DateFormat.jm().format(date)}';
    }
  }
}
