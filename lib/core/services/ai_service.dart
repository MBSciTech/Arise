import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:drift/drift.dart' as drift;
import '../../features/profile/profile_screen.dart';
import '../database/database.dart';

final aiServiceProvider = Provider<AiService>((ref) {
  return AiService(ref);
});

class AiService {
  final Ref ref;
  ChatSession? _chatSession;
  
  AiService(this.ref);

  Future<GenerativeModel?> _getModel() async {
    final apiKey = await ref.read(apiKeyProvider.future);
    if (apiKey == null || apiKey.isEmpty) return null;

    final customModelName = await ref.read(modelNameProvider.future);
    final modelToUse = (customModelName != null && customModelName.isNotEmpty) ? customModelName : 'gemini-1.5-flash';

    final db = ref.read(appDatabaseProvider);
    final now = DateTime.now();
    
    // Fetch recent data for context
    final meals = await db.mealsDao.getRecentDistinctMeals(); 
    
    final mealContext = meals.map((m) => '${m.name} (${m.calories}kcal, ${m.protein}P/${m.carbs}C/${m.fats}F) [${m.category}]').join('\n');

    final systemInstruction = '''
You are Arise, a highly advanced, premium personal health and fitness AI companion. 
Your tone is encouraging, professional, and concise.

Current Date and Time: ${DateFormat('yyyy-MM-dd HH:mm').format(now)}

# Context
Here is a list of the user's recently logged meals and foods from their local database:
$mealContext

# Instructions
- If the user asks about their diet, refer to this context.
- Keep your responses relatively short as this is a mobile chat interface.
- If the user uploads an image of food, analyze it, estimate the calories and macros.
- IMPORTANT: If the user explicitly asks you to LOG A MEAL (or if you analyze food and the user wants to log it), you MUST respond ONLY with a raw JSON object in this exact format (do not wrap it in markdown block):
{"action": "log_meal", "name": "Meal Name", "calories": 500, "protein": 30, "carbs": 40, "fats": 15, "category": "Lunch"}
Do not include any other text if you output this JSON.
''';

    return GenerativeModel(
      model: modelToUse,
      apiKey: apiKey,
      systemInstruction: Content.system(systemInstruction),
    );
  }

  Future<void> _handleJsonAction(Map<String, dynamic> json) async {
    if (json['action'] == 'log_meal') {
      final db = ref.read(appDatabaseProvider);
      await db.mealsDao.insertMeal(
        MealsCompanion.insert(
          name: json['name'].toString(),
          calories: (json['calories'] as num).toDouble(),
          protein: (json['protein'] as num).toDouble(),
          carbs: (json['carbs'] as num).toDouble(),
          fats: (json['fats'] as num).toDouble(),
          quantity: const drift.Value(1.0),
          category: drift.Value(json['category']?.toString() ?? 'Miscellaneous'),
          date: DateTime.now(),
        ),
      );
    }
  }

  Future<String> sendMessage(String text, {Uint8List? imageBytes}) async {
    final model = await _getModel();
    if (model == null) {
      return "Please configure your Gemini API Key in the Profile tab first!";
    }

    if (_chatSession == null) {
      _chatSession = model.startChat();
    }

    try {
      final contentParts = <Part>[TextPart(text)];
      if (imageBytes != null) {
        contentParts.add(DataPart('image/jpeg', imageBytes));
      }

      final response = await _chatSession!.sendMessage(Content.multi(contentParts));
      final responseText = response.text ?? "";

      // Check if response is JSON action
      try {
        final parsedText = responseText.trim().replaceAll('```json', '').replaceAll('```', '').trim();
        if (parsedText.startsWith('{') && parsedText.endsWith('}')) {
          final jsonMap = jsonDecode(parsedText) as Map<String, dynamic>;
          if (jsonMap.containsKey('action')) {
            await _handleJsonAction(jsonMap);
            return "✅ Successfully logged ${jsonMap['name']} to your database!";
          }
        }
      } catch (e) {
        // Not valid JSON, proceed as normal text
      }

      return responseText.isEmpty ? "I'm not sure how to respond to that." : responseText;
    } catch (e, st) {
      print('AI Error: $e');
      print('StackTrace: $st');
      return "Error: $e";
    }
  }
}
