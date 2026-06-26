// Derived at query time from SessionRecord — never stored in Hive.
class DailyAggregate {
  final DateTime date;
  final String packageName;
  final int totalSec;
  final int openCount;

  const DailyAggregate({
    required this.date,
    required this.packageName,
    required this.totalSec,
    required this.openCount,
  });

  Duration get totalDuration => Duration(seconds: totalSec);
}
