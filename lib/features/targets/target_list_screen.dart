import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models/daily_aggregate.dart';
import '../../data/models/target_app_config.dart';
import 'app_picker_screen.dart';
import 'target_detail_screen.dart';

class TargetListScreen extends ConsumerWidget {
  const TargetListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apps = ref.watch(targetAppsProvider);
    final aggregates = ref.watch(todayAggregatesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Target Apps')),
      body: apps.isEmpty ? _emptyState(context) : _list(context, ref, apps, aggregates),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AppPickerScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.apps, size: 72, color: cs.outlineVariant),
          const SizedBox(height: 16),
          Text('No target apps yet',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text('Tap + to pick apps to monitor',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.outline)),
        ],
      ),
    );
  }

  Widget _list(
    BuildContext context,
    WidgetRef ref,
    List<TargetAppConfig> apps,
    List<DailyAggregate> aggregates,
  ) {
    return ListView.builder(
      itemCount: apps.length,
      itemBuilder: (context, i) {
        final app = apps[i];
        final agg = aggregates.firstWhere(
          (a) => a.packageName == app.packageName,
          orElse: () => DailyAggregate(
            date: DateTime.now(),
            packageName: app.packageName,
            totalSec: 0,
            openCount: 0,
          ),
        );
        return _AppTile(app: app, agg: agg);
      },
    );
  }
}

class _AppTile extends ConsumerWidget {
  const _AppTile({required this.app, required this.agg});
  final TargetAppConfig app;
  final DailyAggregate agg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final infoAsync = ref.watch(appInfoProvider(app.packageName));
    final icon = infoAsync.valueOrNull?.icon;

    final usedMin = agg.totalSec / 60;
    final progress = (usedMin / app.thresholdMinutes).clamp(0.0, 1.0);
    final overThreshold = usedMin >= app.thresholdMinutes;

    return Dismissible(
      key: ValueKey(app.packageName),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: Theme.of(context).colorScheme.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) => _confirmDelete(context, app.displayName),
      onDismissed: (_) =>
          ref.read(targetAppsProvider.notifier).remove(app.packageName),
      child: ListTile(
        leading: _AppIcon(icon: icon, enabled: app.enabled),
        title: Text(app.displayName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: progress,
              color: overThreshold
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.primary,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              minHeight: 4,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 2),
            Text(
              '${_fmtSec(agg.totalSec)} / ${app.thresholdMinutes} min  •  ${agg.openCount} opens today',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        isThreeLine: true,
        trailing: app.enabled
            ? null
            : Icon(Icons.pause_circle_outline,
                color: Theme.of(context).colorScheme.outline),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TargetDetailScreen(
              packageName: app.packageName,
              displayName: app.displayName,
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, String name) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove target?'),
        content: Text('Stop monitoring "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _AppIcon extends StatelessWidget {
  const _AppIcon({required this.icon, required this.enabled});
  final Uint8List? icon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    Widget img = icon != null
        ? Image.memory(icon!, width: 40, height: 40, gaplessPlayback: true)
        : const Icon(Icons.android, size: 40);

    if (!enabled) {
      img = ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0,      0,      0,      1, 0,
        ]),
        child: img,
      );
    }

    return img;
  }
}

String _fmtSec(int totalSec) {
  if (totalSec < 60) return '${totalSec}s';
  final m = totalSec ~/ 60;
  final s = totalSec % 60;
  if (m < 60) return s == 0 ? '${m}m' : '${m}m ${s}s';
  final h = m ~/ 60;
  final rem = m % 60;
  return rem == 0 ? '${h}h' : '${h}h ${rem}m';
}
