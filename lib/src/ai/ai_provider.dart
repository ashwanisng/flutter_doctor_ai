/// Abstract interface for AI providers.
///
/// Implement this interface to add support for a new AI provider.
/// See [GroqProvider], [GeminiProvider], [OpenAIProvider], [AnthropicProvider]
/// for implementations.
abstract class AIProvider {
  /// Display name of the provider (e.g., 'Groq', 'OpenAI')
  String get name;

  /// Default model to use if none specified
  String get defaultModel;

  /// List of available models for this provider
  List<String> get availableModels;

  /// Get an AI-powered suggestion for fixing a code issue.
  ///
  /// [issue] - Description of the issue
  /// [code] - Code snippet containing the issue
  /// [filePath] - Path to the file
  /// [model] - Optional model override
  ///
  /// Returns the AI's suggested fix as a string.
  Future<String> getSuggestion({
    required String issue,
    required String code,
    required String filePath,
    String? model,
  });
}
