/// Severity levels for analysis findings.
enum Severity {
  /// Informational - not necessarily a problem
  info,

  /// Warning - potential issue that should be reviewed
  warning,

  /// Error - definite problem that should be fixed
  error,
}

/// Format a number with comma separators.
///
/// Example: `formatNumber(24342)` returns `"24,342"`
String formatNumber(int num) {
  return num.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );
}

/// Format bytes to human-readable size.
///
/// Example: `formatSize(1536)` returns `"1.5 KB"`
String formatSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}

/// Format duration to human-readable string.
///
/// Example: `formatDuration(Duration(milliseconds: 1500))` returns `"1.50s"`
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

/// Get the default model for an AI provider.
///
/// Returns empty string for unknown providers.
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
///
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


/// Remove duplicates from a list while preserving insertion order.
///
/// Unlike `list.toSet().toList()`, this explicitly preserves order
/// without relying on Set implementation details.
List<T> deduplicatePreservingOrder<T>(List<T> items) {
  final seen = <T>{};
  final result = <T>[];
  for (final item in items) {
    if (seen.add(item)) {
      result.add(item);
    }
  }
  return result;
}

/// Get priority for severity (lower = higher priority)
int severityPriority(Severity severity) {
  switch (severity) {
    case Severity.error:
      return 0; // Highest priority
    case Severity.warning:
      return 1;
    case Severity.info:
      return 2; // Lowest priority
  }
}