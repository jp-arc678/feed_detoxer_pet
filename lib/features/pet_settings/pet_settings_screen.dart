import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models/pet_persona.dart';
import '../../data/repositories/bond_repository.dart';
import '../../data/repositories/persona_repository.dart';
import '../../pet/pet_controller.dart';
import '../../pet/pet_view.dart';
import '../../services/dialogue/dialogue_service.dart';
import '../../services/dialogue/pet_dialogue_provider.dart';
import '../../services/mood/mood_engine.dart';

class PetSettingsScreen extends ConsumerStatefulWidget {
  const PetSettingsScreen({super.key});

  @override
  ConsumerState<PetSettingsScreen> createState() => _PetSettingsScreenState();
}

class _PetSettingsScreenState extends ConsumerState<PetSettingsScreen> {
  // ── Persona text controllers ──────────────────────────────────────────────
  late final TextEditingController _nameCtrl;
  late final TextEditingController _nicknameCtrl;
  late final TextEditingController _toneCtrl;
  late final TextEditingController _languageCtrl;
  late final TextEditingController _notesCtrl;

  // ── Pet drag state ────────────────────────────────────────────────────────
  Offset _petOffset = Offset.zero;
  Offset _dragOriginOffset = Offset.zero;

  // ── Interaction line (shown for 3 s after poke) ───────────────────────────
  String? _interactionLine;

  @override
  void initState() {
    super.initState();
    final persona = PersonaRepository().get();
    _nameCtrl     = TextEditingController(text: persona.name);
    _nicknameCtrl = TextEditingController(text: persona.userNickname);
    _toneCtrl     = TextEditingController(text: persona.tone);
    _languageCtrl = TextEditingController(text: persona.language);
    _notesCtrl    = TextEditingController(text: persona.reminderNotes);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nicknameCtrl.dispose();
    _toneCtrl.dispose();
    _languageCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // ── Single interaction hook ───────────────────────────────────────────────
  // All pet interactions funnel through here so the bond system has one entry
  // point. Adding items / minigame later only requires new cases here.
  void _onPetInteraction(String type) {
    switch (type) {
      case 'poke':
        ref.read(petControllerProvider).fire(PetController.poke);
        _generateInteractionLine();
        _applyBondGain();
      case 'drag_end':
        ref.read(petControllerProvider).setDragging(false);
        _applyBondGain();
    }
  }

  Future<void> _generateInteractionLine() async {
    final persona = PersonaRepository().get();
    final bond = ref.read(bondProvider);
    final line = await DialogueService.instance.getLine(DialogueRequest(
      trigger: DialogueTrigger.interaction,
      persona: persona,
      moodIntensity: bond.moodBaseline,
    ));
    if (!mounted) return;
    setState(() => _interactionLine = line);
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) setState(() => _interactionLine = null);
  }

  void _applyBondGain() {
    final repo = BondRepository();
    final updated = MoodEngine.applyInteraction(repo.get());
    repo.save(updated);
    ref.invalidate(bondProvider);
  }

  // ── Persona save ──────────────────────────────────────────────────────────
  Future<void> _savePersona() async {
    final persona = PetPersona(
      name:          _nameCtrl.text.trim().isEmpty     ? 'Peto'    : _nameCtrl.text.trim(),
      userNickname:  _nicknameCtrl.text.trim().isEmpty ? 'buddy'   : _nicknameCtrl.text.trim(),
      tone:          _toneCtrl.text.trim().isEmpty     ? 'friendly': _toneCtrl.text.trim(),
      language:      _languageCtrl.text.trim().isEmpty ? 'English' : _languageCtrl.text.trim(),
      reminderNotes: _notesCtrl.text.trim(),
    );
    await PersonaRepository().save(persona);
    // Invalidating personaProvider triggers homeDialogueLineProvider to rebuild
    // with the new persona on the next home-screen visit.
    ref.invalidate(personaProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Persona saved~')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bond = ref.watch(bondProvider);
    final cs   = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: 'Save persona',
            onPressed: _savePersona,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ── Interactive pet area ─────────────────────────────────────────
          SizedBox(
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.translate(
                  offset: _petOffset,
                  child: GestureDetector(
                    onTap: () => _onPetInteraction('poke'),
                    onLongPressStart: (d) {
                      _dragOriginOffset = _petOffset;
                      ref.read(petControllerProvider).setDragging(true);
                    },
                    onLongPressMoveUpdate: (d) {
                      final next = _dragOriginOffset + d.localOffsetFromOrigin;
                      setState(() {
                        _petOffset = Offset(
                          next.dx.clamp(-90.0, 90.0),
                          next.dy.clamp(-60.0, 60.0),
                        );
                      });
                    },
                    onLongPressEnd:   (_) => _onPetInteraction('drag_end'),
                    onLongPressCancel: () => _onPetInteraction('drag_end'),
                    child: const PetView(size: 140),
                  ),
                ),
              ],
            ),
          ),

          // ── Interaction speech bubble ─────────────────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _interactionLine != null
                ? Container(
                    key: ValueKey(_interactionLine),
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _interactionLine!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: cs.onSecondaryContainer,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 6),

          // ── Bond stats + hint ─────────────────────────────────────────────
          Center(
            child: Text(
              'Tap to poke  •  Long-press and drag to move',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.outline,
                  ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'Bond: ${bond.bondScore.toStringAsFixed(0)} / 100  •  '
              'Mood: ${(bond.moodBaseline * 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(height: 28),

          // ── Persona fields ────────────────────────────────────────────────
          Text(
            'Persona',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _Field(label: 'Pet name',              ctrl: _nameCtrl),
          _Field(label: 'What the pet calls you', ctrl: _nicknameCtrl),
          _Field(
            label: 'Tone',
            ctrl: _toneCtrl,
            hint: 'e.g. friendly, cheerful, sassy',
          ),
          _Field(
            label: 'Language',
            ctrl: _languageCtrl,
            hint: 'e.g. English, Thai, Japanese',
          ),
          _Field(
            label: 'Reminder notes',
            ctrl: _notesCtrl,
            hint: 'e.g. remind me about my project',
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _savePersona,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save Persona'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─── Reusable persona text field ──────────────────────────────────────────────

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.ctrl,
    this.hint,
    this.maxLines = 1,
  });
  final String label;
  final TextEditingController ctrl;
  final String? hint;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
