import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../database.dart';
import '../models/pet_persona.dart';

final personaRepositoryProvider =
    Provider<PersonaRepository>((_) => PersonaRepository());

class PersonaRepository {
  static const _key = 'persona';
  Box<PetPersona> get _box => Hive.box<PetPersona>(kBoxPersona);

  PetPersona get() =>
      _box.get(_key) ?? const PetPersona();

  Future<void> save(PetPersona persona) => _box.put(_key, persona);
}
