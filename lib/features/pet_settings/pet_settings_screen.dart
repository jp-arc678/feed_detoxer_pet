import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../pet/pet_controller.dart';
import '../../pet/pet_view.dart';

class PetSettingsScreen extends ConsumerWidget {
  const PetSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bond = ref.watch(bondProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pet Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Interactive pet area ─────────────────────────────────────────
          Center(
            child: Column(
              children: [
                // Tap to poke — Phase 9 adds drag + full interaction hook.
                GestureDetector(
                  onTap: () =>
                      ref.read(petControllerProvider).fire(PetController.poke),
                  child: const PetView(size: 140),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap to poke  •  Drag coming in Phase 9',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bond: ${bond.bondScore.toStringAsFixed(0)} / 100  •  '
                  'Mood baseline: ${(bond.moodBaseline * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── Persona fields ───────────────────────────────────────────────
          Text(
            'Persona',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const _PersonaField(label: 'Pet name', value: 'Peto'),
          const _PersonaField(label: 'What the pet calls you', value: 'buddy'),
          const _PersonaField(label: 'Tone', value: 'friendly'),
          const _PersonaField(label: 'Language', value: 'English'),
          const _PersonaField(
              label: 'Reminder notes', value: 'remind me about my project'),
          const SizedBox(height: 8),
          Text(
            'Persona editing + saving wired in Phase 9.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }
}

class _PersonaField extends StatelessWidget {
  const _PersonaField({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.lock_outline, size: 16),
        ),
        controller: TextEditingController(text: value),
      ),
    );
  }
}
