import 'package:firebase_ai/firebase_ai.dart';

import '../../core/config.dart';
import 'pet_dialogue_provider.dart';
import 'prompt_builder.dart';

class FirebaseAiDialogueProvider implements PetDialogueProvider {
  @override
  Future<String> generateLine(DialogueRequest request) async {
    final model = FirebaseAI.googleAI().generativeModel(
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
