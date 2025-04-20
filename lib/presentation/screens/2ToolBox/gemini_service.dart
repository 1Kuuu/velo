import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:velora/presentation/screens/Weather/const.dart';

class GeminiService {
  late final GenerativeModel model;
  
  GeminiService() {
    // Ensure we have a valid API key
    final apiKey = geminiKey ?? '';
    if (apiKey.isEmpty) {
      print('Warning: Gemini API key is missing or empty');
    }
    
    model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: apiKey,
    );
  }

  Future<String> getResponse(String prompt) async {
    try {
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      
      // Debugging: Log the response to the console
      print("Gemini API Response: ${response.text}");
      
      if (response.text != null && response.text!.isNotEmpty) {
        return response.text!;
      } else {
        return "I'm sorry, I couldn't generate a response. Please try again.";
      }
    } catch (e) {
      // Print the error to the console for debugging
      print('Error in GeminiService: $e');
      return "I'm having trouble connecting right now. Please try again in a moment.";
    }
  }
}
