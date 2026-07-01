import 'package:firebase_ai/firebase_ai.dart';

import '../../core/config.dart';
import 'pet_dialogue_provider.dart';
import 'prompt_builder.dart';

class FirebaseAiDialogueProvider implements PetDialogueProvider {
  // A lightweight model instance reused across calls; system instruction is
  // per-request so we pass it in generateContent, not the constructor.
  final _firebase = FirebaseAI.googleAI();

  @override
  Future<String> generateLine(DialogueRequest request) async {
    final model = _firebase.generativeModel(
      model: AppConfig.geminiModel,
      systemInstruction: Content.system(PromptBuilder.systemInstruction(request)),
    );
    final response = await model.generateContent(
      [Content.text(PromptBuilder.userMessage(request))],
    );
    final text = response.text?.trim();
    if (text == null || text.isEmpty) throw Exception('Empty AI response');
    return text;
  }

  @override
  void dispose() {}
}
