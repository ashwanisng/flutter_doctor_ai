import 'ai_provider.dart';
import 'groq_provider.dart';

class AIFactory {
  static AIProvider create(String provider, String apiKey) {
    switch (provider.toLowerCase()) {
      case 'groq':
        return GroqProvider(apiKey);
      default:
        throw Exception(
          'Unknown provider: $provider. Supported: groq',
        );
    }
  }
}