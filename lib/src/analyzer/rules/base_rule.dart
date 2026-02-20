import 'package:analyzer/dart/ast/ast.dart';
import 'package:flutter_doctor_ai/src/models/finding.dart';
import 'package:flutter_doctor_ai/src/utils/helpers.dart';

/// Base class for all analysis rules.
///
/// Extend this class to create a custom analysis rule.
///
/// Example:
/// ```dart
/// class MyCustomRule extends BaseRule {
///   @override
///   String get name => 'my_custom_rule';
///
///   @override
///   String get description => 'Checks for my custom pattern';
///
///   @override
///   Severity get severity => Severity.warning;
///
///   @override
///   List<Finding> analyze(CompilationUnit unit, String filePath) {
///     // ... implementation
///   }
/// }
/// ```
abstract class BaseRule {
  /// Unique identifier for this rule
  String get name;

  /// Human-readable description of what this rule checks
  String get description;

  /// Default severity level for findings from this rule
  Severity get severity;

  /// Analyze a compilation unit and return findings.
  ///
  /// [unit] - The parsed AST of the Dart file
  /// [filePath] - Path to the file being analyzed
  List<Finding> analyze(CompilationUnit unit, String filePath);
}
