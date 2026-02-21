import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:flutter_doctor_ai/flutter_doctor_ai.dart';

class MissingMountedCheckRule extends BaseRule {
  @override
  String get name => 'missing_mounted_check';

  @override
  String get description =>
      'Check for mounted before calling setState after an await.';

  @override
  Severity get severity => Severity.warning;

  @override
  List<Finding> analyze(CompilationUnit unit, String filePath) {
    final visitor = _AsyncSetStateVisitor(filePath, unit.lineInfo);
    unit.visitChildren(visitor);
    return visitor.findings;
  }
}

/// Tracks state for a single async method scope
class _AsyncMethodScope {
  bool hasAwait = false;
  bool hasMountedCheck = false;
}

class _AsyncSetStateVisitor extends RecursiveAstVisitor<void> {
  final String filePath;
  final LineInfo lineInfo;
  final List<Finding> findings = [];

  /// Stack of async method scopes - handles nested async methods
  final List<_AsyncMethodScope> _scopeStack = [];

  _AsyncSetStateVisitor(this.filePath, this.lineInfo);

  /// Current scope, or null if not inside an async method
  _AsyncMethodScope? get _currentScope =>
      _scopeStack.isNotEmpty ? _scopeStack.last : null;

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.body.isAsynchronous) {
      // Push new scope for this async method
      _scopeStack.add(_AsyncMethodScope());

      // Visit method body
      super.visitMethodDeclaration(node);

      // Pop scope when done
      _scopeStack.removeLast();
    } else {
      // Not async, just visit normally
      super.visitMethodDeclaration(node);
    }
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    // Handle async closures/lambdas
    if (node.body.isAsynchronous) {
      _scopeStack.add(_AsyncMethodScope());
      super.visitFunctionExpression(node);
      _scopeStack.removeLast();
    } else {
      super.visitFunctionExpression(node);
    }
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    final scope = _currentScope;
    if (scope != null) {
      scope.hasAwait = true;
      // Reset mounted check after each await
      scope.hasMountedCheck = false;
    }
    super.visitAwaitExpression(node);
  }

  @override
  void visitIfStatement(IfStatement node) {
    // Check for: if (mounted) or if (!mounted) return;
    final condition = node.expression;
    if (_isMountedCheck(condition)) {
      final scope = _currentScope;
      if (scope != null) {
        scope.hasMountedCheck = true;
      }
    }
    super.visitIfStatement(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final scope = _currentScope;

    if (scope != null &&
        node.methodName.name == 'setState' &&
        scope.hasAwait &&
        !scope.hasMountedCheck) {
      final line = lineInfo.getLocation(node.offset).lineNumber;
      findings.add(
        Finding(
          rule: 'missing_mounted_check',
          filePath: filePath,
          lineNumber: line,
          message:
              'setState called after await without checking if widget is still mounted.',
          severity: Severity.warning,
          suggestion:
              'Add "if (!mounted) return;" before calling setState after an await.',
        ),
      );
    }
    super.visitMethodInvocation(node);
  }

  /// Check if expression is a mounted check
  bool _isMountedCheck(Expression expr) {
    // Check for: mounted
    if (expr is SimpleIdentifier && expr.name == 'mounted') {
      return true;
    }

    // Check for: !mounted
    if (expr is PrefixExpression && expr.operator.lexeme == '!') {
      final operand = expr.operand;
      if (operand is SimpleIdentifier && operand.name == 'mounted') {
        return true;
      }
    }

    // Check for: this.mounted
    if (expr is PrefixedIdentifier && expr.identifier.name == 'mounted') {
      return true;
    }

    // Check for: mounted == true, mounted == false, etc.
    if (expr is BinaryExpression) {
      final left = expr.leftOperand;
      final right = expr.rightOperand;
      if ((left is SimpleIdentifier && left.name == 'mounted') ||
          (right is SimpleIdentifier && right.name == 'mounted')) {
        return true;
      }
    }

    return false;
  }
}
