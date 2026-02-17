import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:flutter_doctor_ai/src/analyzer/rules/base_rule.dart';
import 'package:flutter_doctor_ai/src/models/finding.dart';
import 'package:flutter_doctor_ai/src/utils/helpers.dart';

class EmptySetStateRule extends BaseRule {
  @override
  List<Finding> analyze(CompilationUnit unit, String filePath) {
    final visitor = _SetStateVisitor(filePath, unit.lineInfo);
    unit.visitChildren(visitor);
    return visitor.findings;
  }

  @override
  String get description => 'setState should not have an empty body';

  @override
  String get name => 'empty_setstate';

  @override
  Severity get severity => Severity.warning;
}

class _SetStateVisitor extends RecursiveAstVisitor<void> {
  final String filePath;
  final LineInfo lineInfo;
  final List<Finding> findings = [];

  _SetStateVisitor(this.filePath, this.lineInfo);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'setState' &&
        node.argumentList.arguments.isNotEmpty) {
      final firstArg = node.argumentList.arguments.first;

      if (firstArg is FunctionExpression) {
        final body = firstArg.body;

        if (body is BlockFunctionBody) {
          final block = body.block;

          if (block.statements.isEmpty) {
            int line = lineInfo.getLocation(node.offset).lineNumber;
            findings.add(
              Finding(
                rule: 'empty_setstate',
                message: 'setState has an empty body',
                filePath: filePath,
                lineNumber: line,
                severity: Severity.warning,
                suggestion: 'Add state changes inside setState or remove it.',
              ),
            );
          }
        }
      }
    }

    super.visitMethodInvocation(node);
  }
}
