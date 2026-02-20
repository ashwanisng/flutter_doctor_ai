import 'dart:io';

import 'package:flutter_doctor_ai/src/models/ai_config.dart';
import 'package:flutter_doctor_ai/src/utils/helpers.dart';

class AiPrompt {
  static Future<AIConfig?> configure() async {
    final provider = await _selectProvider();
    if (provider == null) return null;

    final model = await _selectModel(provider);
    if (model == null) return null;

    final apiKey = await _enterApiKey(provider);
    if (apiKey == null) return null;

    return AIConfig(provider: provider, model: model, apiKey: apiKey);
  }

  static Future<String?> _selectProvider() async {
    print('');
    print('🤖 AI Configuration');
    print('');
    print('Select AI Provider:');
    print('');
    print('  [1] groq      (Free - Recommended)');
    print('  [2] gemini    (Free)');
    print('  [3] openai    (Paid)');
    print('  [4] anthropic (Paid)');
    print('  [0] Cancel');
    print('');

    while (true) {
      stdout.write('Enter choice (0-4): ');
      final input = stdin.readLineSync()?.trim();

      switch (input) {
        case '0':
          return null;
        case '1':
          return 'groq';
        case '2':
          return 'gemini';
        case '3':
          return 'openai';
        case '4':
          return 'anthropic';
        default:
          print('  ❌ Invalid choice. Please enter 0-4.');
      }
    }
  }

  static Future<String?> _selectModel(String provider) async {
    final models = _getModels(provider);

    print('');
    print('Select Model for $provider:');
    print('');

    for (var i = 0; i < models.length; i++) {
      final isDefault = i == 0 ? ' (Default)' : '';
      print('  [${i + 1}] ${models[i]}$isDefault');
    }
    print('  [0] Cancel');
    print('');

    while (true) {
      stdout.write('Enter choice (0-${models.length}): ');
      final input = stdin.readLineSync()?.trim();

      if (input == '0') return null;

      final index = int.tryParse(input ?? '');
      if (index != null && index >= 1 && index <= models.length) {
        return models[index - 1];
      }

      print('  ❌ Invalid choice. Please enter 0-${models.length}.');
    }
  }

  static Future<String?> _enterApiKey(String provider) async {
    print('');
    print('Enter API Key for $provider:');
    print(_getApiKeyHelp(provider));
    print('');
    while (true) {
      stdout.write('API Key (or "cancel" to exit): ');
      final apiKey = stdin.readLineSync()?.trim();

      if (apiKey == null || apiKey.toLowerCase() == 'cancel') {
        return null;
      }

      if (apiKey.isEmpty) {
        print('  ❌ API key cannot be empty.');
        continue;
      }

      // Basic validation based on provider
      if (!validateApiKey(provider, apiKey)) {
        continue;
      }

      return apiKey;
    }
  }

  static List<String> _getModels(String provider) {
    switch (provider) {
      case 'groq':
        return [
          'llama-3.3-70b-versatile',
          'llama-3.1-70b-versatile',
          'llama-3.1-8b-instant',
          'mixtral-8x7b-32768',
        ];
      case 'gemini':
        return [
          'gemini-2.5-flash',
          'gemini-2.5-pro',
          'gemini-2.0-flash',
          'gemini-flash-latest',
        ];
      case 'openai':
        return ['gpt-4o-mini', 'gpt-4o', 'gpt-4-turbo', 'gpt-3.5-turbo'];
      case 'anthropic':
        return [
          'claude-sonnet-4-20250514',
          'claude-3-5-sonnet-20241022',
          'claude-3-5-haiku-20241022',
        ];
      default:
        return [];
    }
  }

  static String _getApiKeyHelp(String provider) {
    switch (provider) {
      case 'groq':
        return '(Get free key: https://console.groq.com)';
      case 'gemini':
        return '(Get free key: https://aistudio.google.com)';
      case 'openai':
        return '(Get key: https://platform.openai.com)';
      case 'anthropic':
        return '(Get key: https://console.anthropic.com)';
      default:
        return '';
    }
  }
}
