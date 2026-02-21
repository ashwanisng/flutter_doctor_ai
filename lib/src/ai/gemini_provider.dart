import 'package:dio/dio.dart';
import 'package:flutter_doctor_ai/src/utils/helpers.dart';
import 'ai_provider.dart';
import 'prompt_builder.dart';

class GeminiProvider implements AIProvider {
  final String apiKey;
  final Dio _dio;

  // Updated model fallbacks with available models
  static const List<String> _modelFallbacks = [
    'gemini-2.5-flash',
    'gemini-2.0-flash',
    'gemini-1.5-flash-latest',
    'gemini-2.5-pro',
  ];

  GeminiProvider(this.apiKey)
      : _dio = Dio(
          BaseOptions(
            headers: {'Content-Type': 'application/json'},
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 60),
          ),
        );

  @override
  String get name => 'Gemini';

  @override
  String get defaultModel => 'gemini-2.5-flash';

  @override
  List<String> get availableModels => [
        'gemini-2.5-flash',
        'gemini-2.5-pro',
        'gemini-2.0-flash',
        'gemini-flash-latest',
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

    // Remove duplicates while preserving order
    final modelsToTry = deduplicatePreservingOrder([
      if (model != null) model,
      ..._modelFallbacks,
    ]);

    Exception? lastError;

    for (final currentModel in modelsToTry) {
      try {
        final response = await _dio.post(
          'https://generativelanguage.googleapis.com/v1beta/models/$currentModel:generateContent',
          queryParameters: {'key': apiKey},
          data: {
            'contents': [
              {
                'parts': [
                  {'text': prompt},
                ],
              },
            ],
            'generationConfig': {'maxOutputTokens': 1000, 'temperature': 0.3},
          },
        );

        // Extract response
        final candidates = response.data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          if (content != null) {
            final parts = content['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              return parts[0]['text'] ?? 'No text in response';
            }
          }
        }

        lastError = Exception('Empty response from $currentModel');
        continue;
      } on DioException catch (e) {
        final statusCode = e.response?.statusCode;
        final errorBody = e.response?.data?.toString() ?? '';

        // If model is not found, try next one
        if (statusCode == 404 ||
            (statusCode == 400 &&
                (errorBody.contains('not found') ||
                    errorBody.contains('not supported') ||
                    errorBody.contains('invalid')))) {
          lastError = Exception('Model $currentModel is unavailable');
          continue;
        }

        // Auth error - don't retry
        if (statusCode == 401 || statusCode == 403) {
          throw Exception(
            'Invalid API key. Get one at https://aistudio.google.com',
          );
        }

        // Rate limit - don't retry
        if (statusCode == 429) {
          throw Exception('Rate limit exceeded. Wait and try again.');
        }

        // For other errors, don't retry
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
