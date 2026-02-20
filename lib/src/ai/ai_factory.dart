import 'package:flutter_doctor_ai/flutter_doctor_ai.dart';

class AIFactory {
  static AIProvider create(String provider, String apiKey) {
    switch (provider.toLowerCase()) {
      case 'groq':
        return GroqProvider(apiKey);

      case 'gemini':
        return GeminiProvider(apiKey);

      case 'openai':
        return OpenAIProvider(apiKey);

      case 'anthropic':
        return AnthropicProvider(apiKey);

      default:
        throw Exception('Unknown provider: $provider. Supported: groq');
    }
  }
}
