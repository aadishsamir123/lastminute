import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/study_mode_service.dart';

class StudyModeScreen extends StatefulWidget {
  const StudyModeScreen({super.key});

  @override
  State<StudyModeScreen> createState() => _StudyModeScreenState();
}

class _StudyModeScreenState extends State<StudyModeScreen> {
  final StudyModeService _studyModeService = StudyModeService();
  Timer? _timer;
  Duration _remainingTime = Duration.zero;
  int _selectedMinutes = 25; // Pomodoro default

  @override
  void initState() {
    super.initState();
    if (_studyModeService.isStudyModeActive) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingTime = _studyModeService.getRemainingTime();
        if (_remainingTime == Duration.zero) {
          timer.cancel();
        }
      });
    });
  }

  void _startStudySession() {
    _studyModeService.startStudyMode(
      Duration(minutes: _selectedMinutes),
      onComplete: () {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('🎉 Session Complete!'),
              content: Text(
                'You studied for $_selectedMinutes minutes. Great job!',
              ),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Awesome!'),
                ),
              ],
            ),
          );
          setState(() {});
        }
      },
    );
    _startTimer();
    setState(() {});
  }

  void _stopStudySession() {
    _studyModeService.stopStudyMode();
    _timer?.cancel();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = _studyModeService.isStudyModeActive;

    return Scaffold(
      appBar: AppBar(title: const Text('Study Mode')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Hero section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.psychology_rounded,
                    size: 80,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Focus Time',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isActive
                        ? 'Stay focused! You\'re doing great.'
                        : 'Set a timer and block distractions',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // Timer display
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: isActive
                          ? colorScheme.primaryContainer
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: isActive
                            ? colorScheme.primary
                            : Colors.transparent,
                        width: 4,
                      ),
                    ),
                    child: Text(
                      isActive
                          ? _formatDuration(_remainingTime)
                          : _formatDuration(
                              Duration(minutes: _selectedMinutes),
                            ),
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isActive
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurface,
                        fontFeatures: [const FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  if (!isActive) ...[
                    const SizedBox(height: 24),
                    // Time presets
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [15, 25, 45, 60, 90].map((minutes) {
                        return FilterChip(
                          selected: _selectedMinutes == minutes,
                          label: Text('$minutes min'),
                          onSelected: (selected) {
                            setState(() => _selectedMinutes = minutes);
                          },
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 24),
                  // Start/Stop button
                  FilledButton.icon(
                    onPressed: isActive
                        ? _stopStudySession
                        : _startStudySession,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      backgroundColor: isActive
                          ? colorScheme.error
                          : colorScheme.primary,
                    ),
                    icon: Icon(
                      isActive ? Icons.stop_rounded : Icons.play_arrow_rounded,
                    ),
                    label: Text(isActive ? 'Stop Session' : 'Start Session'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Features card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Study Mode Features',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _FeatureItem(
                    icon: Icons.timer_rounded,
                    title: 'Focused Timer',
                    description:
                        'Set custom study sessions with built-in breaks',
                  ),
                  if (!kIsWeb)
                    _FeatureItem(
                      icon: Icons.do_not_disturb_on_rounded,
                      title: 'Distraction Blocking',
                      description:
                          'Block distracting apps during study time (Android)',
                      available: !kIsWeb,
                    ),
                  _FeatureItem(
                    icon: Icons.analytics_rounded,
                    title: 'Track Progress',
                    description: 'Monitor your study habits and improve focus',
                  ),
                  _FeatureItem(
                    icon: Icons.emoji_events_rounded,
                    title: 'Stay Motivated',
                    description:
                        'Complete sessions and build healthy study habits',
                  ),
                ],
              ),
            ),
          ),
          if (!kIsWeb) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.apps_rounded, color: colorScheme.secondary),
                        const SizedBox(width: 8),
                        Text(
                          'App Usage (Android Only)',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<Duration>(
                      future: _studyModeService.getTodayStudyTime(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator.adaptive(),
                            ),
                          );
                        }

                        final studyTime = snapshot.data ?? Duration.zero;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: colorScheme.secondaryContainer,
                            child: Icon(
                              Icons.today_rounded,
                              color: colorScheme.onSecondaryContainer,
                            ),
                          ),
                          title: const Text('Today\'s Study Time'),
                          subtitle: Text(_formatDuration(studyTime)),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
    this.available = true,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool available;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: available
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: available
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
