import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed Detoxer'),
        backgroundColor: colorScheme.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pet placeholder area
            Center(
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(90),
                ),
                child: const Center(
                  child: Text('🐾', style: TextStyle(fontSize: 72)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Peto',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                '"Hey buddy~ looking good today!"',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ),
            const SizedBox(height: 24),

            // Today's usage section
            Text(
              "Today's usage",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Card(
              child: SizedBox(
                height: 160,
                child: Center(
                  child: Text(
                    'Usage chart — Phase 5',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Target apps quick summary
            Text(
              'Target apps',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: Icon(Icons.add_circle_outline,
                    color: colorScheme.primary),
                title: const Text('Add target apps'),
                subtitle: const Text('Go to Targets tab to set up'),
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
