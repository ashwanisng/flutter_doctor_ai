import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:flutter_doctor_ai/src/analyzer/rules/base_rule.dart';
import 'package:flutter_doctor_ai/src/models/finding.dart';
import 'package:flutter_doctor_ai/src/utils/helpers.dart';

class LargeBuildRule extends BaseRule {
  final int maxLines;

  LargeBuildRule({this.maxLines = 50});

  @override
  List<Finding> analyze(CompilationUnit unit, String filePath) {
    final visitor = _BuildMethodVisitor(
      filePath,
      unit.lineInfo,
      maxLines: maxLines,
    );
    unit.visitChildren(visitor);
    return visitor.findings;
  }

  @override
  String get name => 'large_build_method';

  @override
  String get description => 'Build methods should not exceed 50 lines';

  @override
  Severity get severity => Severity.warning;
}

class _BuildMethodVisitor extends RecursiveAstVisitor<void> {
  final String filePath;
  final LineInfo lineInfo;
  final int maxLines;
  final List<Finding> findings = [];

  _BuildMethodVisitor(this.filePath, this.lineInfo, {this.maxLines = 50});

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.name.lexeme == 'build') {
      int startLine = lineInfo.getLocation(node.offset).lineNumber;
      int endLine = lineInfo.getLocation(node.end).lineNumber;

      int methodLength = endLine - startLine + 1;

      if (methodLength > maxLines) {
        findings.add(
          Finding(
            rule: 'large_build_method',
            message:
                'Build method is $methodLength lines long, which exceeds the maximum of $maxLines lines.',
            filePath: filePath,
            lineNumber: startLine,
            severity: Severity.warning,
            suggestion:
                'Extract parts into separate widget classes or helper methods.',
          ),
        );
      }
    }
    return super.visitMethodDeclaration(node);
  }
}
