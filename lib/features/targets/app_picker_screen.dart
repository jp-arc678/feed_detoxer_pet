import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config.dart';
import '../../core/providers.dart';
import '../../data/models/target_app_config.dart';

class AppPickerScreen extends ConsumerStatefulWidget {
  const AppPickerScreen({super.key});

  @override
  ConsumerState<AppPickerScreen> createState() => _AppPickerScreenState();
}

class _AppPickerScreenState extends ConsumerState<AppPickerScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final installedAsync = ref.watch(installedAppsProvider);
    final alreadyAdded =
        ref.watch(targetAppsProvider).map((a) => a.packageName).toSet();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Target App'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search apps…',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
            ),
          ),
        ),
      ),
      body: installedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load apps: $e')),
        data: (apps) {
          final filtered = apps
              .where((a) =>
                  !alreadyAdded.contains(a.packageName) &&
                  (_query.isEmpty ||
                      a.name.toLowerCase().contains(_query) ||
                      a.packageName.toLowerCase().contains(_query)))
              .toList();

          if (filtered.isEmpty) {
            return const Center(child: Text('No apps found.'));
          }

          return ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (context, i) {
              final app = filtered[i];
              final icon = app.icon;
              return ListTile(
                leading: _AppIcon(icon: icon),
                title: Text(app.name),
                subtitle: Text(
                  app.packageName,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                onTap: () => _addApp(app.packageName, app.name),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _addApp(String packageName, String displayName) async {
    await ref.read(targetAppsProvider.notifier).add(
          TargetAppConfig(
            packageName: packageName,
            displayName: displayName,
            thresholdMinutes: AppConfig.defaultThresholdMinutes,
          ),
        );
    if (mounted) Navigator.of(context).pop();
  }
}

class _AppIcon extends StatelessWidget {
  const _AppIcon({required this.icon});
  final Uint8List? icon;

  @override
  Widget build(BuildContext context) {
    if (icon != null) {
      return Image.memory(icon!, width: 40, height: 40, gaplessPlayback: true);
    }
    return const Icon(Icons.android, size: 40);
  }
}
