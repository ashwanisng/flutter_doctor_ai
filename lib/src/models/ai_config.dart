/// Configuration for AI provider integration.
///
/// Holds the selected provider, model, and API credentials
/// needed to make AI suggestion requests.
class AIConfig {
  /// The AI provider name (e.g., 'groq', 'gemini', 'openai', 'anthropic')
  final String provider;

  /// The model to use (e.g., 'llama-3.3-70b-versatile', 'gpt-4o-mini')
  final String model;

  /// API key for authenticating with the provider
  final String apiKey;

  const AIConfig({
    required this.provider,
    required this.model,
    required this.apiKey,
  });
}