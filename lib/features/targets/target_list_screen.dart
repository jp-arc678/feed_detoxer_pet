import 'package:flutter/material.dart';
import 'target_detail_screen.dart';

class TargetListScreen extends StatelessWidget {
  const TargetListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Target Apps'),
        backgroundColor: colorScheme.surface,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.apps, size: 72, color: colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text(
              'No target apps yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to pick apps to monitor',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 32),
            // Placeholder item to demonstrate Target Detail navigation
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TargetDetailScreen(
                    packageName: 'com.example.demo',
                    displayName: 'Demo App',
                  ),
                ),
              ),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Preview Target Detail'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // App picker implemented in Phase 5
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('App picker — Phase 5')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
