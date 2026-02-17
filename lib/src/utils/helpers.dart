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

int extractLineCount(String message) {
  // Extract number from "Build method is 648 lines long..."
  final match = RegExp(r'is (\d+) lines').firstMatch(message);
  return match != null ? int.parse(match.group(1)!) : 0;
}

enum Severity { info, warning, error }
