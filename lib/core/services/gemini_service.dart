import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:velora/presentation/screens/Weather/const.dart';
import 'package:flutter/foundation.dart';

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  late final GenerativeModel _model;
  late final ChatSession _chatSession;
  bool _isInitialized = false;
  bool _isInitializing = false;
  String _lastErrorMessage = "";

  // Using the correct model name for Gemini API
  //ignore: constant_identifier_names
  static const String MODEL_NAME = 'gemini-1.5-flash';

  factory GeminiService() {
    return _instance;
  }

  GeminiService._internal() {
    debugPrint('GeminiService: Starting initialization...');
    debugPrint('GeminiService: Using model: $MODEL_NAME');
    
    if (GEMINI_API_KEY.isNotEmpty) {
      debugPrint('GeminiService: API Key provided: ${_maskApiKey(GEMINI_API_KEY)}');
    } else {
      debugPrint('GeminiService: ERROR - API key is empty!');
    }
    
    _initializeService();
  }

  String _maskApiKey(String key) {
    if (key.length <= 10) return "****";
    return "${key.substring(0, 4)}****${key.substring(key.length - 4)}";
  }

  bool isGeminiKeyValid() {
    // Basic validation to check if API key looks reasonable
    return GEMINI_API_KEY.isNotEmpty && 
           GEMINI_API_KEY.length > 10 &&
           !GEMINI_API_KEY.contains(' ');
  }

  bool _validateApiKey() {
    debugPrint('GeminiService: Validating API key...');
    
    if (!isGeminiKeyValid()) {
      _lastErrorMessage = "Invalid API key format. Please check your API key configuration.";
      debugPrint('GeminiService: ERROR - $_lastErrorMessage');
      return false;
    }

    debugPrint('GeminiService: API key validation successful');
    return true;
  }

  Future<void> _initializeService() async {
    if (_isInitializing) return;
    _isInitializing = true;
    
    try {
      if (!_validateApiKey()) {
        debugPrint('GeminiService: Failed API key validation');
        _isInitialized = false;
        _isInitializing = false;
        return;
      }

      debugPrint('GeminiService: Creating GenerativeModel...');
      
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
        debugPrint('GeminiService: GenerativeModel created successfully');
      } catch (e) {
        _lastErrorMessage = "Error creating GenerativeModel: $e";
        debugPrint('GeminiService: $_lastErrorMessage');
        _isInitialized = false;
        _isInitializing = false;
        return;
      }

      // Test the API key with a simple query
      debugPrint('GeminiService: Testing API connection...');
      final testContent = Content.text('Hello');
      try {
        final response = await _model.generateContent([testContent]);
        if (response.text == null || response.text!.isEmpty) {
          throw Exception('Empty response from API');
        }
        debugPrint('GeminiService: API test response received');
        debugPrint('GeminiService: API connection test successful');
      } catch (e) {
        _lastErrorMessage = "API connection test failed: $e";
        debugPrint('GeminiService: $_lastErrorMessage');
        _isInitialized = false;
        _isInitializing = false;
        return;
      }
      
      _resetChatSession();
      _isInitialized = true;
      _isInitializing = false;
      debugPrint('GeminiService: Initialization complete');
    } catch (e, stackTrace) {
      _lastErrorMessage = "Initialization error: $e";
      debugPrint('GeminiService: $_lastErrorMessage');
      debugPrint('GeminiService: Stack trace: $stackTrace');
      _isInitialized = false;
      _isInitializing = false;
    }
  }

  void _resetChatSession() {
    try {
      debugPrint('GeminiService: Starting new chat session...');
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
   - NEVER use asterisks (*) in your responses for formatting

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
      debugPrint('GeminiService: Chat session started successfully');
    } catch (e, stackTrace) {
      _lastErrorMessage = "Chat session error: $e";
      debugPrint('GeminiService: $_lastErrorMessage');
      debugPrint('GeminiService: Stack trace: $stackTrace');
      _isInitialized = false;
    }
  }

  String getFallbackResponse(String topic) {
    return "I'm sorry, I'm having trouble connecting to my knowledge base right now. For questions about $topic, you might want to check cycling forums or consult with your local bike shop. Please try asking me again later.";
  }

  Future<String> sendMessage(String message) async {
    if (!_isInitialized && !_isInitializing) {
      debugPrint('GeminiService: Service not initialized, attempting to initialize...');
      await _initializeService();
    }
    
    if (!_isInitialized) {
      debugPrint('GeminiService: Still not initialized after attempt, returning error message');
      String topic = _extractTopic(message);
      
      if (_lastErrorMessage.contains("API key")) {
        return 'I apologize, but there seems to be an issue with my configuration. The API key may be invalid or missing. Please check the API key in your settings.';
      } else if (_lastErrorMessage.contains("connection")) {
        return 'I apologize, but I\'m having trouble connecting to the internet. Please check your connection and try again.';
      } else {
        return getFallbackResponse(topic);
      }
    }

    try {
      debugPrint('GeminiService: Sending message to API...');
      final response = await _chatSession.sendMessage(Content.text(message));
      
      if (response.text == null || response.text!.isEmpty) {
        debugPrint('GeminiService: Received empty response');
        return 'I apologize, but I was unable to generate a response. Please try rephrasing your question.';
      }

      debugPrint('GeminiService: Successfully received response');
      // Remove any asterisks from the response
      return response.text!.replaceAll('*', '');
    } catch (e, stackTrace) {
      debugPrint('GeminiService: Error during message send: $e');
      debugPrint('GeminiService: Stack trace: $stackTrace');
      
      if (e.toString().contains("Invalid")) {
        debugPrint('GeminiService: Invalid API key detected');
        return 'Error: Invalid API key. Please make sure you have added a valid Gemini API key to your settings.';
      } else if (e.toString().contains("Failed host lookup") || 
                e.toString().contains("SocketException") ||
                e.toString().contains("connection")) {
        return 'I apologize, but I\'m having trouble connecting to my knowledge base. Please check your internet connection and try again.';
      } else if (e.toString().contains("timeout")) {
        return 'I apologize, but my response timed out. Please try asking a shorter or simpler question.';
      }
      
      String topic = _extractTopic(message);
      return getFallbackResponse(topic);
    }
  }

  String _extractTopic(String message) {
    message = message.toLowerCase();
    
    if (message.contains("fix") || message.contains("repair") || message.contains("broke")) {
      return "bike repairs";
    } else if (message.contains("tire") || message.contains("chain") || message.contains("gear")) {
      return "bike components";
    } else if (message.contains("training") || message.contains("exercise") || message.contains("ride")) {
      return "cycling techniques";
    } else {
      return "cycling";
    }
  }

  bool get isInitialized => _isInitialized;
  String get lastError => _lastErrorMessage;

  void resetChat() {
    debugPrint('GeminiService: Resetting chat session...');
    if (_isInitialized) {
      _resetChatSession();
    } else {
      _initializeService();
    }
  }
} 