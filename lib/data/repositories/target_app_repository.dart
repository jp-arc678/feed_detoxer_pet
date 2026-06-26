import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../database.dart';
import '../models/target_app_config.dart';
import '../../services/usage/brain_channel.dart';

final targetAppRepositoryProvider =
    Provider<TargetAppRepository>((_) => TargetAppRepository());

class TargetAppRepository {
  Box<TargetAppConfig> get _box => Hive.box<TargetAppConfig>(kBoxTargetApps);

  List<TargetAppConfig> getAll() => _box.values.toList();

  TargetAppConfig? get(String packageName) => _box.get(packageName);

  Future<void> save(TargetAppConfig config) async {
    await _box.put(config.packageName, config);
    await _syncToBrain();
  }

  Future<void> delete(String packageName) async {
    await _box.delete(packageName);
    await _syncToBrain();
  }

  // Keeps SharedPreferences (Brain-readable) in sync with Hive.
  Future<void> _syncToBrain() async {
    final enabled = _box.values
        .where((c) => c.enabled)
        .map((c) => c.packageName)
        .toList();
    await BrainChannel.setTargetApps(enabled);
  }

  // Called once at startup to restore the Brain's target list from Hive.
  Future<void> syncToBrainOnStartup() => _syncToBrain();
}
