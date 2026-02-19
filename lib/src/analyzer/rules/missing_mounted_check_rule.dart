import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:flutter_doctor_ai/src/analyzer/rules/base_rule.dart';
import 'package:flutter_doctor_ai/src/models/finding.dart';
import 'package:flutter_doctor_ai/src/utils/helpers.dart';

class MissingMountedCheckRule extends BaseRule {
  @override
  String get description =>
      'Check if the widget is still mounted before calling setState or performing actions that require the widget to be active.';

  @override
  String get name => 'missing_mounted_check';

  @override
  Severity get severity => Severity.warning;

  @override
  List<Finding> analyze(CompilationUnit unit, String filePath) {
    final visitor = _AsyncSetStateVisitor(filePath, unit.lineInfo);
    unit.visitChildren(visitor);
    return visitor.findings;
  }
}

class _AsyncSetStateVisitor extends RecursiveAstVisitor {
  final String filePath;
  final LineInfo lineInfo;
  final List<Finding> findings = [];

  _AsyncSetStateVisitor(this.filePath, this.lineInfo);

  bool _inAsyncMethod = false;
  bool _hasAwait = false;
  bool _hasMountedCheck = false;

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.body.isAsynchronous) {
      _inAsyncMethod = true;
      _hasAwait = false;
      _hasMountedCheck = false;

      super.visitMethodDeclaration(node);
      _inAsyncMethod = false;
    } else {
      super.visitMethodDeclaration(node);
    }
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    if (_inAsyncMethod) {
      _hasAwait = true;
      _hasMountedCheck = false;
    }
    super.visitAwaitExpression(node);
  }

  @override
  void visitIfStatement(IfStatement node) {
    final condition = node.expression.toString();
    if (condition.contains('mounted')) {
      _hasMountedCheck = true;
    }
    super.visitIfStatement(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'setState') {
      if (_inAsyncMethod && _hasAwait && !_hasMountedCheck) {
        int line = lineInfo.getLocation(node.offset).lineNumber;
        findings.add(
          Finding(
            rule: 'missing_mounted_check',
            message:
                'setState is called in an async method without checking if the widget is still mounted.',
            filePath: filePath,
            lineNumber: line,
            severity: Severity.warning,
            suggestion:
                'Add a check for mounted before calling setState to prevent potential errors when the widget is no longer active.',
          ),
        );
      }
    }
    super.visitMethodInvocation(node);
  }
}
