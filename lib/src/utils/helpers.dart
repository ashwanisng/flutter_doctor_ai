enum Severity { info, warning, error }

/// Format number with commas (e.g., 24342 → "24,342")
String formatNumber(int num) {
  return num.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );
}

/// Format file size in bytes to human readable (e.g., "1.5 MB")
String formatSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}

/// Format duration to human readable
String formatDuration(Duration duration) {
  if (duration.inMilliseconds < 1000) {
    return '${duration.inMilliseconds}ms';
  }
  return '${(duration.inMilliseconds / 1000).toStringAsFixed(2)}s';
}

/// Extract line count from message like "Build method is 648 lines long..."
int extractLineCount(String message) {
  final match = RegExp(r'is (\d+) lines').firstMatch(message);
  return match != null ? int.parse(match.group(1)!) : 0;
}

/// Get default model for a provider
String getDefaultModel(String provider) {
  switch (provider) {
    case 'groq':
      return 'llama-3.3-70b-versatile';
    case 'gemini':
      return 'gemini-2.5-flash';
    case 'openai':
      return 'gpt-4o-mini';
    case 'anthropic':
      return 'claude-sonnet-4-20250514';
    default:
      return '';
  }
}

/// Validate API key format for a provider.
/// Returns null if valid, or an error message if invalid.
String? validateApiKey(String provider, String apiKey) {
  switch (provider) {
    case 'groq':
      if (!apiKey.startsWith('gsk_')) {
        return 'Groq API key should start with "gsk_"';
      }
      if (apiKey.length < 20) {
        return 'API key seems too short. Please check and try again.';
      }
      return null;

    case 'gemini':
      if (apiKey.length < 20) {
        return 'API key seems too short. Please check and try again.';
      }
      return null;

    case 'openai':
      if (!apiKey.startsWith('sk-')) {
        return 'OpenAI API key should start with "sk-"';
      }
      return null;

    case 'anthropic':
      if (!apiKey.startsWith('sk-ant-')) {
        return 'Anthropic API key should start with "sk-ant-"';
      }
      return null;

    default:
      return null;
  }
}
