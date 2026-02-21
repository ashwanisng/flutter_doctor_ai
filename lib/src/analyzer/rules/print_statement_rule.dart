import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:flutter_doctor_ai/src/analyzer/rules/base_rule.dart';
import 'package:flutter_doctor_ai/src/models/finding.dart';
import 'package:flutter_doctor_ai/src/utils/helpers.dart';
import 'package:path/path.dart' as p;

/// Detects print statements that should not be in production code.
class PrintStatementRule extends BaseRule {
  /// Path segments to exclude from this rule (CLI tools need print)
  static const List<String> _excludedSegments = ['cli', 'bin'];

  /// Specific files to exclude
  static const List<String> _excludedFiles = ['helpers.dart'];

  @override
  List<Finding> analyze(CompilationUnit unit, String filePath) {
    // Skip excluded paths (CLI files where print is intentional)
    if (_shouldExclude(filePath)) {
      return [];
    }

    final visitor = _PrintStatementVisitor(filePath, unit.lineInfo);
    unit.visitChildren(visitor);
    return visitor.findings;
  }

  /// Check if file should be excluded from this rule.
  bool _shouldExclude(String filePath) {
    // Normalize path separators for cross-platform support
    final segments = p.split(filePath);
    final fileName = p.basename(filePath);

    // Check if any excluded segment is in the path
    for (final excluded in _excludedSegments) {
      if (segments.contains(excluded)) {
        return true;
      }
    }

    // Check if file name matches excluded files
    if (_excludedFiles.contains(fileName)) {
      return true;
    }

    return false;
  }

  @override
  String get description => 'Avoid using print statements in production code';

  @override
  String get name => 'print_statement';

  @override
  Severity get severity => Severity.warning;
}

class _PrintStatementVisitor extends RecursiveAstVisitor<void> {
  final String filePath;
  final LineInfo lineInfo;
  final List<Finding> findings = [];

  _PrintStatementVisitor(this.filePath, this.lineInfo);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'print') {
      int line = lineInfo.getLocation(node.offset).lineNumber;
      findings.add(
        Finding(
          rule: 'print_statement',
          message: 'Avoid using print statements in production code',
          filePath: filePath,
          lineNumber: line,
          severity: Severity.warning,
          suggestion:
          'Consider using a logging package like logger or flutter_logs for better control over logging.',
        ),
      );
    }
    super.visitMethodInvocation(node);
  }
}