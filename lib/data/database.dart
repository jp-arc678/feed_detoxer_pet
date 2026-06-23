import 'package:hive_flutter/hive_flutter.dart';

// Box name constants — referenced by repositories in Phase 4.
const String kBoxTargetApps = 'targetApps';
const String kBoxSessions = 'sessions';
const String kBoxPersona = 'persona';
const String kBoxBondState = 'bondState';

Future<void> initDatabase() async {
  await Hive.initFlutter();
  // Hive type adapters will be registered here in Phase 4.
  await Future.wait([
    Hive.openBox<Map>(kBoxTargetApps),
    Hive.openBox<Map>(kBoxSessions),
    Hive.openBox(kBoxPersona),
    Hive.openBox(kBoxBondState),
  ]);
}
