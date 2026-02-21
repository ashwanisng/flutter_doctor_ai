import 'package:dio/dio.dart';
import 'package:flutter_doctor_ai/src/utils/helpers.dart';
import 'ai_provider.dart';
import 'prompt_builder.dart';

class OpenAIProvider extends AIProvider {
  final String apiKey;
  final Dio _dio;

  static const List<String> _modelFallbacks = [
    'gpt-4o-mini',
    'gpt-4o',
    'gpt-4-turbo',
    'gpt-3.5-turbo',
  ];

  OpenAIProvider(this.apiKey)
      : _dio = Dio(
          BaseOptions(
            baseUrl: 'https://api.openai.com/v1',
            headers: {'Content-Type': 'application/json'},
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 60),
          ),
        );

  @override
  String get name => 'OpenAI';

  @override
  String get defaultModel => 'gpt-4o-mini';

  @override
  List<String> get availableModels => [
        'gpt-4o-mini',
        'gpt-4o',
        'gpt-4-turbo',
        'gpt-3.5-turbo',
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

    final modelsToTry = deduplicatePreservingOrder([
      if (model != null) model,
      ..._modelFallbacks,
    ]);

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

        // Model not found - try next
        if (statusCode == 404 ||
            errorBody.contains('does not exist') ||
            errorBody.contains('invalid_model')) {
          lastError = Exception('Model $currentModel is unavailable');
          continue;
        }

        // Auth error - don't retry
        if (statusCode == 401) {
          throw Exception(
            'Invalid API key. Get one at https://platform.openai.com',
          );
        }

        // Quota/rate limit - don't retry
        if (statusCode == 429) {
          throw Exception(
            'Rate limit or quota exceeded. Check billing at https://platform.openai.com',
          );
        }

        // Other errors - don't retry
        if (e.response != null) {
          throw Exception(
            'API error: ${e.response?.statusCode} - ${e.response?.data}',
          );
        }
        throw Exception('Network error: ${e.message}');
      }
    }

    throw lastError ?? Exception('All models failed');
  }
}
