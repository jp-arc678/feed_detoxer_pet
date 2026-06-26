import 'package:hive/hive.dart';
import '../../core/config.dart';

part 'target_app_config.g.dart';

@HiveType(typeId: 0)
class TargetAppConfig {
  @HiveField(0)
  final String packageName;

  @HiveField(1)
  final String displayName;

  @HiveField(2)
  final int thresholdMinutes;

  @HiveField(3)
  final bool enabled;

  const TargetAppConfig({
    required this.packageName,
    required this.displayName,
    this.thresholdMinutes = AppConfig.defaultThresholdMinutes,
    this.enabled = true,
  });

  TargetAppConfig copyWith({
    String? displayName,
    int? thresholdMinutes,
    bool? enabled,
  }) {
    return TargetAppConfig(
      packageName: packageName,
      displayName: displayName ?? this.displayName,
      thresholdMinutes: thresholdMinutes ?? this.thresholdMinutes,
      enabled: enabled ?? this.enabled,
    );
  }
}
