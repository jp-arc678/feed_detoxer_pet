import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../database.dart';
import '../models/pet_bond_state.dart';

final bondRepositoryProvider =
    Provider<BondRepository>((_) => BondRepository());

class BondRepository {
  static const _key = 'bond';
  Box<PetBondState> get _box => Hive.box<PetBondState>(kBoxBondState);

  PetBondState get() => _box.get(_key) ??
      PetBondState(lastInteractionAt: DateTime.now());

  Future<void> save(PetBondState state) => _box.put(_key, state);
}
