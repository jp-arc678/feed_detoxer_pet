import 'package:hive/hive.dart';

part 'session_record.g.dart';

// Append-only. Written exclusively by SessionListener from Brain events.
@HiveType(typeId: 1)
class SessionRecord {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String packageName;

  @HiveField(2)
  final DateTime startTime;

  @HiveField(3)
  final DateTime? endTime;

  @HiveField(4)
  final int durationSec;

  @HiveField(5)
  final String outcome; // 'completed' | 'overrun' | 'skipped'

  const SessionRecord({
    required this.id,
    required this.packageName,
    required this.startTime,
    this.endTime,
    this.durationSec = 0,
    this.outcome = 'completed',
  });
}
