import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:velora/presentation/screens/Weather/const.dart';
import 'dart:math' as math;

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  late final GenerativeModel _model;
  late final ChatSession _chatSession;
  bool _isInitialized = false;

  // Using the correct model name for Gemini API
  static const String MODEL_NAME = 'gemini-1.5-flash';

  factory GeminiService() {
    return _instance;
  }

  GeminiService._internal() {
    print('GeminiService: Starting initialization...');
    print('GeminiService: Using model: $MODEL_NAME');
    print('GeminiService: API Key provided: ${GEMINI_API_KEY.substring(0, math.min(10, GEMINI_API_KEY.length))}...');
    _validateAndInitialize();
  }

  bool _validateApiKey() {
    print('GeminiService: Validating API key...');
    
    if (!isGeminiKeyValid()) {
      print('GeminiService: ERROR - Invalid API key format. Please check the API key in const.dart');
      print('GeminiService: API Key should:');
      print('1. Start with "AI"');
      print('2. Be at least 39 characters long');
      print('3. Not contain any spaces or special characters');
      return false;
    }

    print('GeminiService: API key validation successful');
    return true;
  }

  Future<void> _validateAndInitialize() async {
    try {
      if (!_validateApiKey()) {
        print('GeminiService: Failed API key validation');
        _isInitialized = false;
        return;
      }

      print('GeminiService: Creating GenerativeModel...');
      
      try {
        _model = GenerativeModel(
          model: MODEL_NAME,
          apiKey: GEMINI_API_KEY,
          generationConfig: GenerationConfig(
            temperature: 0.3,
            topK: 20,
            topP: 0.8,
            maxOutputTokens: 2048,
          ),
        );
        print('GeminiService: GenerativeModel created successfully');
      } catch (e) {
        print('GeminiService: Error creating GenerativeModel: $e');
        _isInitialized = false;
        return;
      }

      // Test the API key with a simple query
      print('GeminiService: Testing API connection...');
      final testContent = Content.text('Hello');
      try {
        final response = await _model.generateContent([testContent]);
        if (response.text == null || response.text!.isEmpty) {
          throw Exception('Empty response from API');
        }
        print('GeminiService: API test response: ${response.text}');
        print('GeminiService: API connection test successful');
      } catch (e) {
        print('GeminiService: API test failed: $e');
        _isInitialized = false;
        return;
      }
      
      _resetChatSession();
      _isInitialized = true;
      print('GeminiService: Initialization complete');
    } catch (e, stackTrace) {
      print('GeminiService: Initialization error: $e');
      print('GeminiService: Stack trace: $stackTrace');
      _isInitialized = false;
    }
  }

  void _resetChatSession() {
    try {
      print('GeminiService: Starting new chat session...');
      _chatSession = _model.startChat(
        history: [
          Content.text('''
You are Velo Assistant, a highly knowledgeable cycling expert with years of experience. Your role is to provide accurate, practical advice about cycling, bike maintenance, and related topics. Follow these guidelines strictly:

1. Accuracy and Reliability:
   - Base all advice on established cycling knowledge and best practices
   - Distinguish clearly between facts and opinions
   - Acknowledge when you're unsure about something
   - Prioritize safety over convenience
   - Recommend professional service when appropriate

2. Expertise Areas:
   - Bike maintenance and repair
   - Cycling techniques and best practices
   - Bike components and their functions
   - Safety guidelines and equipment
   - Training and performance tips
   - Bike selection and fitting

3. Response Style:
   - Be precise and technical when needed
   - Use clear, easy-to-understand language
   - Provide step-by-step instructions when relevant
   - Include specific measurements and specifications when applicable
   - Explain the reasoning behind recommendations
   - Include safety warnings when necessary

4. Quality Standards:
   - Double-check technical specifications
   - Verify compatibility of components
   - Consider different bike types and riding styles
   - Account for varying skill levels
   - Mention relevant standards or certifications

5. Safety First:
   - Always prioritize user safety
   - Highlight potential risks
   - Recommend professional service for complex repairs
   - Suggest appropriate safety gear
   - Warn about dangerous practices

Remember: When in doubt, err on the side of caution and recommend professional service. Your advice could directly impact user safety.
'''),
        ],
      );
      print('GeminiService: Chat session started successfully');
    } catch (e, stackTrace) {
      print('GeminiService: Chat session error: $e');
      print('GeminiService: Stack trace: $stackTrace');
      _isInitialized = false;
    }
  }

  Future<String> sendMessage(String message) async {
    if (!_isInitialized) {
      print('GeminiService: Service not initialized, attempting to initialize...');
      await _validateAndInitialize();
      if (!_isInitialized) {
        return 'Error: The Gemini service is not properly initialized. Please check your API key in the .env file. The API key should start with "AI" and be at least 40 characters long.';
      }
    }

    try {
      print('GeminiService: Sending message to API...');
      final response = await _chatSession.sendMessage(Content.text(message));
      
      if (response.text == null || response.text!.isEmpty) {
        print('GeminiService: Received empty response');
        return 'I apologize, but I was unable to generate a response. Please try rephrasing your question.';
      }

      print('GeminiService: Successfully received response');
      return response.text!;
    } catch (e, stackTrace) {
      print('GeminiService: Error during message send: $e');
      print('GeminiService: Stack trace: $stackTrace');
      
      if (e.toString().contains('Invalid')) {
        print('GeminiService: Invalid API key detected');
        return 'Error: Invalid API key. Please make sure you have added a valid Gemini API key to your .env file.';
      }
      
      return 'I apologize, but I encountered an error. Please check your internet connection and try again.';
    }
  }

  bool get isInitialized => _isInitialized;

  void resetChat() {
    print('GeminiService: Resetting chat session...');
    _resetChatSession();
  }
} 