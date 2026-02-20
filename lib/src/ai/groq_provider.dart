import 'package:dio/dio.dart';
import 'ai_provider.dart';
import 'prompt_builder.dart';

class GroqProvider implements AIProvider {
  final String apiKey;
  final Dio _dio;

  // Model fallback order (if one fails, try next)
  static const List<String> _modelFallbacks = [
    'llama-3.3-70b-versatile',
    'llama-3.1-70b-versatile',
    'llama3-70b-8192',
    'llama-3.1-8b-instant',
    'mixtral-8x7b-32768',
  ];

  GroqProvider(this.apiKey)
      : _dio = Dio(
          BaseOptions(
            baseUrl: 'https://api.groq.com/openai/v1',
            headers: {'Content-Type': 'application/json'},
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 60),
          ),
        );

  @override
  String get name => 'Groq';

  @override
  String get defaultModel => 'llama-3.3-70b-versatile';

  @override
  List<String> get availableModels => [
        'llama-3.3-70b-versatile',
        'llama-3.1-70b-versatile',
        'llama-3.1-8b-instant',
        'mixtral-8x7b-32768',
      ];

  @override
  Future<String> getSuggestion({
    required String issue,
    required String code,
    required String filePath,
    String? model,
  }) async {
    final prompt = PromptBuilder.fixSuggestion(
      issue: issue,
      code: code,
      filePath: filePath,
    );

    // Try with specified model first, then fallbacks
    List<String> modelsToTry = [];
    if (model != null) {
      modelsToTry.add(model);
    }
    modelsToTry.addAll(_modelFallbacks);

    // Remove duplicates while preserving order
    modelsToTry = modelsToTry.toSet().toList();

    Exception? lastError;

    for (final currentModel in modelsToTry) {
      try {
        final response = await _dio.post(
          '/chat/completions',
          options: Options(headers: {'Authorization': 'Bearer $apiKey'}),
          data: {
            'model': currentModel,
            'messages': [
              {'role': 'user', 'content': prompt},
            ],
            'max_tokens': 1000,
            'temperature': 0.3,
          },
        );

        return response.data['choices'][0]['message']['content'];
      } on DioException catch (e) {
        final statusCode = e.response?.statusCode;
        final errorBody = e.response?.data?.toString() ?? '';

        // If model is deprecated/invalid, try next one
        if (statusCode == 400 &&
            (errorBody.contains('decommissioned') ||
                errorBody.contains('not found') ||
                errorBody.contains('invalid'))) {
          lastError = Exception('Model $currentModel is unavailable');
          continue; // Try next model
        }

        // For other errors (auth, rate limit), don't retry
        if (e.response != null) {
          throw Exception(
            'API error: ${e.response?.statusCode} - ${e.response?.data}',
          );
        }
        throw Exception('Network error: ${e.message}');
      }
    }

    // All models failed
    throw lastError ?? Exception('All models failed');
  }
}
