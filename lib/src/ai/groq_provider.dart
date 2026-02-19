import 'package:dio/dio.dart';
import 'ai_provider.dart';
import 'prompt_builder.dart';

class GroqProvider implements AIProvider {
  final String apiKey;
  final Dio _dio;

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
    final selectedModel = model ?? defaultModel;
    final prompt = PromptBuilder.fixSuggestion(
      issue: issue,
      code: code,
      filePath: filePath,
    );

    try {
      final response = await _dio.post(
        '/chat/completions',
        options: Options(headers: {'Authorization': 'Bearer $apiKey'}),
        data: {
          'model': selectedModel,
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': 1000,
          'temperature': 0.3,
        },
      );

      return response.data['choices'][0]['message']['content'];
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          'API error: ${e.response?.statusCode} - ${e.response?.data}',
        );
      }
      throw Exception('Network error: ${e.message}');
    }
  }
}
