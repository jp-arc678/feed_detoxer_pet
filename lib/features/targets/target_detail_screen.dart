import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models/daily_aggregate.dart';
import '../../data/models/session_record.dart';
import '../../data/models/target_app_config.dart';

class TargetDetailScreen extends ConsumerStatefulWidget {
  final String packageName;
  final String displayName;

  const TargetDetailScreen({
    super.key,
    required this.packageName,
    required this.displayName,
  });

  @override
  ConsumerState<TargetDetailScreen> createState() => _TargetDetailScreenState();
}

class _TargetDetailScreenState extends ConsumerState<TargetDetailScreen> {
  // Local slider value — committed to Hive only on release.
  double? _localThreshold;

  @override
  Widget build(BuildContext context) {
    final apps = ref.watch(targetAppsProvider);
    final config = apps.firstWhere(
      (a) => a.packageName == widget.packageName,
      orElse: () => TargetAppConfig(
        packageName: widget.packageName,
        displayName: widget.displayName,
      ),
    );

    final threshold = _localThreshold ?? config.thresholdMinutes.toDouble();

    final agg = ref.watch(todayAggregatesProvider).firstWhere(
          (a) => a.packageName == widget.packageName,
          orElse: () => DailyAggregate(
            date: DateTime.now(),
            packageName: widget.packageName,
            totalSec: 0,
            openCount: 0,
          ),
        );

    final sessions = ref.watch(sessionHistoryProvider(widget.packageName));
    final infoAsync = ref.watch(appInfoProvider(widget.packageName));
    final icon = infoAsync.valueOrNull?.icon;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Row(
          children: [
            _AppIcon(icon: icon),
            const SizedBox(width: 10),
            Text(config.displayName),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Today at a glance ──────────────────────────────────────────────
          _SectionCard(
            title: "Today",
            child: _TodayStats(agg: agg, threshold: config.thresholdMinutes),
          ),
          const SizedBox(height: 12),

          // ── Threshold slider ───────────────────────────────────────────────
          _SectionCard(
            title: 'Alert threshold',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${threshold.round()} minutes',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                Slider(
                  value: threshold,
                  min: 1,
                  max: 120,
                  divisions: 119,
                  label: '${threshold.round()} min',
                  onChanged: (v) => setState(() => _localThreshold = v),
                  onChangeEnd: (v) => _saveThreshold(config, v.round()),
                ),
                Text(
                  'Pet will alert you after ${threshold.round()} minutes in this app.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Enable toggle ──────────────────────────────────────────────────
          _SectionCard(
            title: 'Options',
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Monitoring enabled'),
              subtitle: Text(
                config.enabled
                    ? 'Brain is watching this app'
                    : 'Monitoring paused',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              value: config.enabled,
              onChanged: (v) => _saveEnabled(config, v),
            ),
          ),
          const SizedBox(height: 12),

          // ── Session history ────────────────────────────────────────────────
          _SectionCard(
            title: 'Recent sessions',
            child: sessions.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        'No sessions recorded yet.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ),
                  )
                : Column(
                    children: sessions
                        .take(10)
                        .map((s) => _SessionTile(session: s))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveThreshold(TargetAppConfig config, int minutes) async {
    await ref.read(targetAppsProvider.notifier).update(
          TargetAppConfig(
            packageName: config.packageName,
            displayName: config.displayName,
            thresholdMinutes: minutes,
            enabled: config.enabled,
          ),
        );
    setState(() => _localThreshold = null);
  }

  Future<void> _saveEnabled(TargetAppConfig config, bool enabled) async {
    await ref.read(targetAppsProvider.notifier).update(
          TargetAppConfig(
            packageName: config.packageName,
            displayName: config.displayName,
            thresholdMinutes: config.thresholdMinutes,
            enabled: enabled,
          ),
        );
  }

}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _TodayStats extends StatelessWidget {
  const _TodayStats({required this.agg, required this.threshold});
  final DailyAggregate agg;
  final int threshold;

  @override
  Widget build(BuildContext context) {
    final int totalSec = agg.totalSec;
    final int opens = agg.openCount;

    final usedMin = totalSec / 60;
    final progress = (usedMin / threshold).clamp(0.0, 1.0);
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _Stat(label: 'Time used', value: _fmtSec(totalSec)),
            _Stat(label: 'Sessions', value: '$opens'),
            _Stat(label: 'Threshold', value: '$threshold min'),
          ],
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: progress,
          color: progress >= 1.0 ? cs.error : cs.primary,
          backgroundColor: cs.surfaceContainerHighest,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 4),
        Text(
          progress >= 1.0 ? 'Over threshold today!' : '${(progress * 100).round()}% of threshold used',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: progress >= 1.0 ? cs.error : cs.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        Text(label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )),
      ],
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session});
  final SessionRecord session;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final timeStr = _timeStr(session.startTime);
    final dateStr = _dateStr(session.startTime);
    final dur = _fmtSec(session.durationSec);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(timeStr,
                  style: Theme.of(context).textTheme.bodyMedium),
              Text(dateStr,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant)),
            ],
          ),
          const Spacer(),
          Text(dur,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Icon(
            session.outcome == 'overrun'
                ? Icons.warning_amber_rounded
                : Icons.check_circle_outline,
            size: 18,
            color: session.outcome == 'overrun' ? cs.error : cs.primary,
          ),
        ],
      ),
    );
  }

  String _timeStr(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _dateStr(DateTime dt) {
    final today = DateTime.now();
    if (dt.year == today.year &&
        dt.month == today.month &&
        dt.day == today.day) {
      return 'Today';
    }
    final yesterday = today.subtract(const Duration(days: 1));
    if (dt.year == yesterday.year &&
        dt.month == yesterday.month &&
        dt.day == yesterday.day) {
      return 'Yesterday';
    }
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _AppIcon extends StatelessWidget {
  const _AppIcon({required this.icon});
  final Uint8List? icon;

  @override
  Widget build(BuildContext context) {
    if (icon != null) {
      return Image.memory(icon!, width: 32, height: 32, gaplessPlayback: true);
    }
    return const Icon(Icons.android, size: 32);
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
