import 'package:flutter/material.dart';

class LicensesScreen extends StatelessWidget {
  const LicensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LicensePage(
      applicationName: 'LastMinute',
      applicationLegalese: '© 2024 LastMinute. All rights reserved.',
      applicationIcon: SizedBox(
        width: 100,
        height: 100,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Icon(
            Icons.schedule,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
