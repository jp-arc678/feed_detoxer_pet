import 'package:flutter/material.dart';

class PetSettingsScreen extends StatelessWidget {
  const PetSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet Settings'),
        backgroundColor: colorScheme.surface,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Interactive pet area
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Poke! — interactions wired Phase 9')),
                    );
                  },
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(70),
                    ),
                    child: const Center(
                      child: Text('🐾', style: TextStyle(fontSize: 56)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap to poke • Drag to move — Phase 9',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.outline,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Persona fields (read-only stubs)
          Text(
            'Persona',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          _PersonaField(label: 'Pet name', value: 'Peto'),
          _PersonaField(label: 'What the pet calls you', value: 'buddy'),
          _PersonaField(label: 'Tone', value: 'friendly'),
          _PersonaField(label: 'Language', value: 'English'),
          _PersonaField(
              label: 'Reminder notes', value: 'remind me about my project'),
          const SizedBox(height: 8),
          Text(
            'Persona editing wired in Phase 9',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }
}

class _PersonaField extends StatelessWidget {
  final String label;
  final String value;
  const _PersonaField({required this.label, required this.value});

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
