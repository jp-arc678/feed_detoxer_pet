import '../../core/config.dart';

// @HiveType annotations will be added in Phase 4 when code generation is wired.
class TargetAppConfig {
  final String packageName;
  final String displayName;
  final int thresholdMinutes;
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
