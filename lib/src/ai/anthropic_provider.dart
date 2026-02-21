import 'package:dio/dio.dart';
import 'package:flutter_doctor_ai/src/utils/helpers.dart';
import 'ai_provider.dart';
import 'prompt_builder.dart';

class AnthropicProvider extends AIProvider {
  final String apiKey;
  final Dio _dio;

  static const List<String> _modelFallbacks = [
    'claude-sonnet-4-20250514',
    'claude-3-5-sonnet-20241022',
    'claude-3-5-haiku-20241022',
    'claude-3-haiku-20240307',
  ];

  AnthropicProvider(this.apiKey)
      : _dio = Dio(
          BaseOptions(
            baseUrl: 'https://api.anthropic.com/v1',
            headers: {'Content-Type': 'application/json'},
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 60),
          ),
        );

  @override
  String get name => 'Anthropic';

  @override
  String get defaultModel => 'claude-sonnet-4-20250514';

  @override
  List<String> get availableModels => [
        'claude-sonnet-4-20250514',
        'claude-3-5-sonnet-20241022',
        'claude-3-5-haiku-20241022',
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
          '/messages',
          options: Options(
            headers: {'x-api-key': apiKey, 'anthropic-version': '2023-06-01'},
          ),
          data: {
            'model': currentModel,
            'max_tokens': 1000,
            'messages': [
              {'role': 'user', 'content': prompt},
            ],
          },
        );

        return response.data['content'][0]['text'];
      } on DioException catch (e) {
        final statusCode = e.response?.statusCode;
        final responseData = e.response?.data;

        // Extract Anthropic-specific error details if available
        String? errorType;
        String? errorMessage;
        if (responseData is Map) {
          errorType = responseData['error']?['type'];
          errorMessage = responseData['error']?['message'];
        }

        if (statusCode == 404 ||
            errorType == 'not_found_error' ||
            (errorMessage?.contains('model') ?? false)) {
          lastError = Exception('Model $currentModel is unavailable');
          continue;
        }

        if (statusCode == 400) {
          throw Exception(
              'Invalid request for $currentModel: ${errorMessage ?? "Malformed request"}');
        }

        // 3. Auth error: Do NOT retry
        if (statusCode == 401) {
          throw Exception(
              'Invalid API key. Get one at https://console.anthropic.com');
        }

        // 4. Rate limit: Do NOT retry (retrying immediately will just fail again)
        if (statusCode == 429) {
          throw Exception(
              'Rate limit exceeded for $currentModel. Wait and try again.');
        }

        // 5. Generic API/Network errors
        if (e.response != null) {
          throw Exception(
              'API error: $statusCode - ${responseData ?? e.message}');
        }
        throw Exception('Network error: ${e.message}');
      }
    }

    throw lastError ?? Exception('All models failed');
  }
}
