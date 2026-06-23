// Append-only. Written exclusively by the Brain (Phase 3+).
// @HiveType annotations added in Phase 4.
class SessionRecord {
  final String id;
  final String packageName;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationSec;
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
