import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models/daily_aggregate.dart';
import '../../data/models/target_app_config.dart';
import '../../pet/pet_controller.dart';
import '../../pet/pet_view.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _greeted = false;

  @override
  void initState() {
    super.initState();
    // Fire greet + sync initial mood after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncPet());
  }

  void _syncPet() {
    if (!mounted) return;
    final bond = ref.read(bondProvider);
    final controller = ref.read(petControllerProvider);
    controller.setMood(bond.moodBaseline);
    if (!_greeted) {
      _greeted = true;
      controller.fire(PetController.greet);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Re-sync mood whenever bond state changes (e.g. after foreground resume).
    ref.listen(bondProvider, (_, bond) {
      ref.read(petControllerProvider).setMood(bond.moodBaseline);
    });

    final apps = ref.watch(targetAppsProvider);
    final aggregates = ref.watch(todayAggregatesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Feed Detoxer')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PetArea(),
            const SizedBox(height: 24),
            Text(
              "Today's screen time",
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (apps.isEmpty)
              _noTargetsCard(context)
            else
              ...apps.map((app) {
                final agg = aggregates.firstWhere(
                  (a) => a.packageName == app.packageName,
                  orElse: () => DailyAggregate(
                    date: DateTime.now(),
                    packageName: app.packageName,
                    totalSec: 0,
                    openCount: 0,
                  ),
                );
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _UsageCard(app: app, agg: agg),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _noTargetsCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.apps, size: 36, color: cs.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No apps monitored yet',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text('Go to the Targets tab to add apps.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Pet area ─────────────────────────────────────────────────────────────────

class _PetArea extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bond = ref.watch(bondProvider);

    return Center(
      child: Column(
        children: [
          // Tap the pet to poke it.
          GestureDetector(
            onTap: () =>
                ref.read(petControllerProvider).fire(PetController.poke),
            child: const PetView(size: 160),
          ),
          const SizedBox(height: 8),
          Text(
            'Peto',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Bond: ${bond.bondScore.toStringAsFixed(0)} / 100',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

// ─── Usage card per app ────────────────────────────────────────────────────────

class _UsageCard extends ConsumerWidget {
  const _UsageCard({required this.app, required this.agg});
  final TargetAppConfig app;
  final DailyAggregate agg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final infoAsync = ref.watch(appInfoProvider(app.packageName));
    final icon = infoAsync.valueOrNull?.icon;

    final usedMin = agg.totalSec / 60;
    final progress = (usedMin / app.thresholdMinutes).clamp(0.0, 1.0);
    final cs = Theme.of(context).colorScheme;
    final overThreshold = progress >= 1.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _AppIcon(icon: icon),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    app.displayName,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  _fmtSec(agg.totalSec),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: overThreshold ? cs.error : cs.primary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              color: overThreshold ? cs.error : cs.primary,
              backgroundColor: cs.surfaceContainerHighest,
              minHeight: 6,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  overThreshold
                      ? 'Over limit!'
                      : '${(progress * 100).round()}% of ${app.thresholdMinutes} min limit',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: overThreshold ? cs.error : cs.onSurfaceVariant,
                      ),
                ),
                Text(
                  '${agg.openCount} opens',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AppIcon extends StatelessWidget {
  const _AppIcon({required this.icon});
  final Uint8List? icon;

  @override
  Widget build(BuildContext context) {
    if (icon != null) {
      return Image.memory(icon!, width: 36, height: 36, gaplessPlayback: true);
    }
    return const Icon(Icons.android, size: 36);
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
