// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
// Rive 0.14.x exports File (rive's file type), RiveWidgetController,
// ArtboardNamed, StateMachineNamed, RiveWidget, Factory, and the input types.
// dart:io is NOT imported to avoid shadowing rive's 'File' class.
import 'package:rive/rive.dart';

import 'pet_controller.dart';
import 'rive_pet_controller.dart';

// Loads assets/rive/pet.riv asynchronously, wires the PetSM state machine
// inputs to RivePetController, then renders via RiveWidget.
// The file-level ignore suppresses deprecation warnings on stateMachine input
// accessor methods (.number(), .boolean(), .trigger()) — the data-binding
// alternative requires Rive-editor configuration and is not suitable here.
class RivePetWidget extends StatefulWidget {
  const RivePetWidget({
    super.key,
    required this.controller,
    this.size = 160.0,
  });

  final RivePetController controller;
  final double size;

  @override
  State<RivePetWidget> createState() => _RivePetWidgetState();
}

class _RivePetWidgetState extends State<RivePetWidget> {
  RiveWidgetController? _riveController;
  // The Rive File must be kept alive for the duration of painting.
  // ignore: unused_field
  File? _riveFile;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      // File.asset() calls RiveNative.init() internally.
      final file = await File.asset(
        'assets/rive/pet.riv',
        riveFactory: Factory.rive,
      );
      if (file == null) throw RiveFileLoaderException('pet.riv returned null');

      final ctrl = RiveWidgetController(
        file,
        artboardSelector: const ArtboardNamed('Pet'),
        stateMachineSelector: const StateMachineNamed('PetSM'),
      );

      // Build trigger map — only include inputs found in this .riv.
      final triggers = <String, TriggerInput>{};
      for (final name in [
        PetController.greet,
        PetController.poke,
        PetController.celebrate,
        PetController.cry,
        PetController.wave,
      ]) {
        final t = ctrl.stateMachine.trigger(name);
        if (t != null) triggers[name] = t;
      }

      widget.controller.bindInputs(
        moodInput: ctrl.stateMachine.number('mood'),
        triggerInputs: triggers,
        isDraggingInput: ctrl.stateMachine.boolean('isDragging'),
      );

      if (!mounted) {
        ctrl.dispose();
        file.dispose();
        return;
      }
      setState(() {
        _riveFile = file;
        _riveController = ctrl;
      });
    } on RiveArtboardException catch (e) {
      debugPrint('[RivePet] artboard error: $e — check PET_RIVE_CONTRACT.md');
      if (mounted) setState(() => _failed = true);
    } on RiveStateMachineException catch (e) {
      debugPrint('[RivePet] state machine error: $e — check PET_RIVE_CONTRACT.md');
      if (mounted) setState(() => _failed = true);
    } catch (e) {
      debugPrint('[RivePet] load error: $e');
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    // Clear controller input references before disposing the Rive objects
    // so setMood/fire calls after this point don't touch freed memory.
    widget.controller.clearInputs();
    _riveController?.dispose();
    _riveFile?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.broken_image_outlined, size: 32),
              const SizedBox(height: 4),
              Text(
                'pet.riv error\nSee PET_RIVE_CONTRACT.md',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      );
    }
    if (_riveController == null) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: RiveWidget(controller: _riveController!),
      ),
    );
  }
}
