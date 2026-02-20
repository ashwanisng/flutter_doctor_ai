import 'package:flutter_doctor_ai/src/utils/helpers.dart';

/// Represents a single code analysis finding/issue.
///
/// Contains information about where the issue was found,
/// what rule triggered it, and how to fix it.
class Finding {
  /// The rule that triggered this finding (e.g., 'missing_dispose')
  final String rule;

  /// Human-readable description of the issue
  final String message;

  /// Absolute path to the file containing the issue
  final String filePath;

  /// Line number where the issue was found (1-indexed)
  final int lineNumber;

  /// Severity level of the finding
  final Severity severity;

  /// Optional suggestion for how to fix the issue
  final String? suggestion;

  const Finding({
    required this.rule,
    required this.message,
    required this.filePath,
    required this.lineNumber,
    required this.severity,
    this.suggestion,
  });
}