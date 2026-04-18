import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:protectme/services/language_service.dart';

class ActivityMonitor extends StatelessWidget {
  const ActivityMonitor({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              Provider.of<LanguageService>(context).t('activity_monitor'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 10),
            Text(
              Provider.of<LanguageService>(context).t('monitoring_activity'),
            ),
          ],
        ),
      ),
    );
  }
}
