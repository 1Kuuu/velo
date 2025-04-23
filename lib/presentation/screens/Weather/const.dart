// ignore: constant_identifier_names
const OPENWEATHER_API_KEY = "febe97a7956586916174fe077174c959";
// ignore: constant_identifier_names
const GEMINI_API_KEY = "AIzaSyAcYHCCaNDeI1ZIoU9pgkdZC8ACdDkwqak";

// Validation functions
bool isGeminiKeyValid() {
  print('Validating Gemini API key:');
  print('Key length: ${GEMINI_API_KEY.length}');
  print('Key starts with AI: ${GEMINI_API_KEY.startsWith('AI')}');
  
  if (GEMINI_API_KEY.isEmpty) {
    print('Error: Gemini API key is empty');
    return false;
  }
  
  if (!GEMINI_API_KEY.startsWith('AI')) {
    print('Error: Gemini API key must start with "AI"');
    return false;
  }
  
  if (GEMINI_API_KEY.length < 39) {
    print('Error: Gemini API key is too short (${GEMINI_API_KEY.length} chars)');
    return false;
  }
  
  print('Gemini API key validation successful');
  return true;
}

bool isWeatherKeyValid() {
  print('Validating Weather API key:');
  print('Key length: ${OPENWEATHER_API_KEY.length}');
  
  if (OPENWEATHER_API_KEY.isEmpty) {
    print('Error: Weather API key is empty');
    return false;
  }
  
  if (OPENWEATHER_API_KEY.length < 25) {
    print('Error: Weather API key is too short (${OPENWEATHER_API_KEY.length} chars)');
    return false;
  }
  
  print('Weather API key validation successful');
  return true;
}
