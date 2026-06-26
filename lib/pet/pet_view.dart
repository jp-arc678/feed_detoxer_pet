import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config.dart';
import '../core/providers.dart';
import 'placeholder_pet_widget.dart';

// Single widget used everywhere to display the pet.
// Swap implementations by flipping AppConfig.useRivePet in config.dart.
class PetView extends ConsumerWidget {
  const PetView({super.key, this.size = 160.0});

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(petControllerProvider);
    // Phase 10: if (AppConfig.useRivePet) return RivePetWidget(controller: controller, size: size);
    assert(!AppConfig.useRivePet, 'Set useRivePet=false until pet.riv is ready');
    return PlaceholderPetWidget(controller: controller, size: size);
  }
}
