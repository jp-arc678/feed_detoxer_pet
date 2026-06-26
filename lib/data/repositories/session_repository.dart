import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../database.dart';
import '../models/session_record.dart';
import '../models/daily_aggregate.dart';

final sessionRepositoryProvider = Provider<SessionRepository>((_) => SessionRepository());

class SessionRepository {
  Box<SessionRecord> get _box => Hive.box<SessionRecord>(kBoxSessions);

  // Append a completed session (called by SessionListener).
  Future<void> append(SessionRecord record) => _box.add(record);

  // All sessions for a specific app, newest first.
  List<SessionRecord> forApp(String packageName) => _box.values
      .where((s) => s.packageName == packageName)
      .toList()
    ..sort((a, b) => b.startTime.compareTo(a.startTime));

  // All sessions on a given calendar date for a specific app.
  List<SessionRecord> forAppOnDate(String packageName, DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end   = start.add(const Duration(days: 1));
    return _box.values
        .where((s) =>
            s.packageName == packageName &&
            s.startTime.isAfter(start) &&
            s.startTime.isBefore(end))
        .toList();
  }

  // Derive daily aggregate for one app on one date.
  DailyAggregate dailyAggregate(String packageName, DateTime date) {
    final sessions = forAppOnDate(packageName, date);
    final totalSec = sessions.fold(0, (sum, s) => sum + s.durationSec);
    return DailyAggregate(
      date: date,
      packageName: packageName,
      totalSec: totalSec,
      openCount: sessions.length,
    );
  }

  // Aggregates for all target apps on a given date.
  List<DailyAggregate> allDailyAggregates(
      List<String> packages, DateTime date) =>
      packages.map((pkg) => dailyAggregate(pkg, date)).toList();
}
