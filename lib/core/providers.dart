import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';

import '../data/models/daily_aggregate.dart';
import '../data/models/pet_bond_state.dart';
import '../data/models/session_record.dart';
import '../data/models/target_app_config.dart';
import '../data/repositories/bond_repository.dart';
import '../data/repositories/persona_repository.dart';
import '../data/repositories/session_repository.dart';
import '../data/repositories/target_app_repository.dart';
import '../pet/pet_controller.dart';
import '../pet/placeholder_pet_controller.dart';
import '../services/dialogue/dialogue_service.dart';
import '../services/dialogue/pet_dialogue_provider.dart';

// ---------------------------------------------------------------------------
// Target apps — mutable list backed by Hive + synced to Brain on every change
// ---------------------------------------------------------------------------

class TargetAppsNotifier extends Notifier<List<TargetAppConfig>> {
  TargetAppRepository get _repo => TargetAppRepository();

  @override
  List<TargetAppConfig> build() => _repo.getAll();

  Future<void> add(TargetAppConfig config) async {
    await _repo.save(config);
    state = _repo.getAll();
  }

  Future<void> update(TargetAppConfig config) async {
    await _repo.save(config);
    state = _repo.getAll();
  }

  Future<void> remove(String packageName) async {
    await _repo.delete(packageName);
    state = _repo.getAll();
  }
}

final targetAppsProvider =
    NotifierProvider<TargetAppsNotifier, List<TargetAppConfig>>(
        TargetAppsNotifier.new);

// ---------------------------------------------------------------------------
// Today's daily aggregates for all target apps (derived, not stored)
// ---------------------------------------------------------------------------

final todayAggregatesProvider = Provider<List<DailyAggregate>>((ref) {
  final apps = ref.watch(targetAppsProvider);
  return SessionRepository().allDailyAggregates(
    apps.map((a) => a.packageName).toList(),
    DateTime.now(),
  );
});

// ---------------------------------------------------------------------------
// Session history per app
// ---------------------------------------------------------------------------

final sessionHistoryProvider =
    Provider.family<List<SessionRecord>, String>((ref, packageName) {
  return SessionRepository().forApp(packageName);
});

// ---------------------------------------------------------------------------
// Installed apps (loaded once, cached by Riverpod)
// ---------------------------------------------------------------------------

final installedAppsProvider = FutureProvider<List<AppInfo>>((ref) async {
  final apps = await InstalledApps.getInstalledApps();
  apps.sort((a, b) => a.name.compareTo(b.name));
  return apps;
});

// ---------------------------------------------------------------------------
// Single app info by package name (for icons in list tiles)
// ---------------------------------------------------------------------------

final appInfoProvider =
    FutureProvider.family<AppInfo?, String>((ref, packageName) async {
  final all = await ref.watch(installedAppsProvider.future);
  try {
    return all.firstWhere((a) => a.packageName == packageName);
  } catch (_) {
    return null;
  }
});

// ---------------------------------------------------------------------------
// Bond / mood state (read from Hive; invalidated on foreground resume)
// ---------------------------------------------------------------------------

final bondProvider = Provider<PetBondState>((ref) => BondRepository().get());

// ---------------------------------------------------------------------------
// Home screen dialogue line (greeting or record comment, generated async)
// autoDispose so a fresh line is generated each time the provider is rebuilt.
// ---------------------------------------------------------------------------

final homeDialogueLineProvider = FutureProvider.autoDispose<String>((ref) {
  final bond = ref.watch(bondProvider);
  final persona = PersonaRepository().get();
  final aggregates = ref.watch(todayAggregatesProvider);
  final totalSec = aggregates.fold(0, (s, a) => s + a.totalSec);
  final openCount = aggregates.fold(0, (s, a) => s + a.openCount);

  // Show a greeting when the pet is happy; comment on record when struggling.
  final trigger = bond.moodBaseline <= 0.35
      ? DialogueTrigger.greeting
      : DialogueTrigger.recordComment;

  return DialogueService.instance.getLine(DialogueRequest(
    trigger: trigger,
    persona: persona,
    moodIntensity: bond.moodBaseline,
    usage: UsageSummary(totalSecToday: totalSec, openCountToday: openCount),
  ));
});

// ---------------------------------------------------------------------------
// Pet controller singleton — swap to RivePetController in Phase 10
// ---------------------------------------------------------------------------

final petControllerProvider = ChangeNotifierProvider<PetController>(
  (ref) => PlaceholderPetController(),
);
