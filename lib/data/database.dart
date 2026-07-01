import 'package:hive_flutter/hive_flutter.dart';

import 'models/target_app_config.dart';
import 'models/session_record.dart';
import 'models/pet_persona.dart';
import 'models/pet_bond_state.dart';

// Box name constants — used by repositories.
const String kBoxTargetApps = 'targetApps';
const String kBoxSessions   = 'sessions';
const String kBoxPersona    = 'persona';
const String kBoxBondState  = 'bondState';
const String kBoxSettings   = 'settings'; // generic key-value store (Box<dynamic>)

Future<void> initDatabase() async {
  await Hive.initFlutter();

  // Register adapters before opening any box.
  Hive.registerAdapter(TargetAppConfigAdapter());
  Hive.registerAdapter(SessionRecordAdapter());
  Hive.registerAdapter(PetPersonaAdapter());
  Hive.registerAdapter(PetBondStateAdapter());

  await Future.wait([
    Hive.openBox<TargetAppConfig>(kBoxTargetApps),
    Hive.openBox<SessionRecord>(kBoxSessions),
    Hive.openBox<PetPersona>(kBoxPersona),
    Hive.openBox<PetBondState>(kBoxBondState),
    Hive.openBox<dynamic>(kBoxSettings),
  ]);
}
