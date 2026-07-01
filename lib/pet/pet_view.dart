import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config.dart';
import '../core/providers.dart';
import 'placeholder_pet_widget.dart';
import 'rive_pet_controller.dart';
import 'rive_pet_widget.dart';

// Single widget used everywhere to display the pet.
// Swap implementations by flipping AppConfig.useRivePet in config.dart.
class PetView extends ConsumerWidget {
  const PetView({super.key, this.size = 160.0});

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(petControllerProvider);
    if (AppConfig.useRivePet) {
      return RivePetWidget(
        controller: controller as RivePetController,
        size: size,
      );
    }
    return PlaceholderPetWidget(controller: controller, size: size);
  }
}
