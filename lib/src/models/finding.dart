import 'package:flutter_doctor_ai/src/utils/helpers.dart';

class Finding {
  final String rule;
  final String message;
  final String filePath;
  final int lineNumber;
  final Severity severity;
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
