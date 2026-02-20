import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:flutter_doctor_ai/src/analyzer/rules/base_rule.dart';
import 'package:flutter_doctor_ai/src/models/finding.dart';
import 'package:flutter_doctor_ai/src/utils/helpers.dart';

class PrintStatementRule extends BaseRule {
  @override
  List<Finding> analyze(CompilationUnit unit, String filePath) {
    if (filePath.contains('/cli/') || filePath.contains('/utils/helpers')) {
      return [];
    }

    final visitor = _PrintStatementVisitor(filePath, unit.lineInfo);
    unit.visitChildren(visitor);
    return visitor.findings;
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
