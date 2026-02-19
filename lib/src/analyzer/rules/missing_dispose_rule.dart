import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:flutter_doctor_ai/src/analyzer/rules/base_rule.dart';
import 'package:flutter_doctor_ai/src/models/finding.dart';
import 'package:flutter_doctor_ai/src/utils/helpers.dart';

class MissingDisposeRule extends BaseRule {
  @override
  String get description =>
      'Stateful widgets should implement dispose() to clean up resources.';

  @override
  String get name => 'missing_dispose';

  @override
  Severity get severity => Severity.warning;

  @override
  List<Finding> analyze(CompilationUnit unit, String filePath) {
    final visitor = _MissingDisposeVisitor(filePath, unit.lineInfo);
    unit.visitChildren(visitor);
    return visitor.findings;
  }
}

class _MissingDisposeVisitor extends RecursiveAstVisitor<void> {
  final String filePath;
  final LineInfo lineInfo;
  final List<Finding> findings = [];

  _MissingDisposeVisitor(this.filePath, this.lineInfo);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final className = node.name.lexeme;
    final classNameOffset = node.name.offset;
    final superclass = node.extendsClause?.superclass.name.lexeme;
    final members = node.members;

    // Check for State subclasses
    if (superclass == 'State' ||
        (superclass != null && superclass.startsWith('State<'))) {
      // Collect disposable fields
      List<String> disposableFields = [];
      for (var member in members) {
        if (member is FieldDeclaration) {
          for (var variable in member.fields.variables) {
            String fieldType = member.fields.type?.toString() ?? '';
            final lowerFieldType = fieldType.toLowerCase();
            if (lowerFieldType.contains('controller') ||
                lowerFieldType.contains('stream') ||
                lowerFieldType.contains('subscription') ||
                lowerFieldType.contains('animation') ||
                lowerFieldType.contains('focusnode') ||
                lowerFieldType.contains('texteditingcontroller') ||
                lowerFieldType.contains('scrollcontroller') ||
                lowerFieldType.contains('tabcontroller') ||
                lowerFieldType.contains('pagecontroller')) {
              disposableFields.add(variable.name.lexeme);
            }
          }
        }
      }

      if (disposableFields.isNotEmpty) {
        MethodDeclaration? disposeMethod;
        for (var member in members) {
          if (member is MethodDeclaration && member.name.lexeme == 'dispose') {
            disposeMethod = member;
            break;
          }
        }

        if (disposeMethod == null) {
          // No dispose method: emit finding for each disposable field
          for (var field in disposableFields) {
            findings.add(
              Finding(
                rule: 'missing_dispose',
                filePath: filePath,
                lineNumber: lineInfo.getLocation(classNameOffset).lineNumber,
                message:
                    'Field "$field" should be disposed in dispose() method.',
                severity: Severity.warning,
                suggestion: 'Add $field.dispose() in the dispose() method.',
              ),
            );
          }
          findings.add(
            Finding(
              rule: 'missing_dispose',
              filePath: filePath,
              lineNumber: lineInfo.getLocation(classNameOffset).lineNumber,
              message:
                  'Missing dispose() method in $className. Override dispose() and dispose all controllers/resources.',
              severity: Severity.warning,
              suggestion:
                  '@override\nvoid dispose() {\n  // Dispose controllers here\n  super.dispose();\n}',
            ),
          );
        } else {
          // Dispose method exists: check its body
          Set<String> disposedFields = {};
          bool superDisposeCalled = false;

          if (disposeMethod.body is BlockFunctionBody) {
            var block = (disposeMethod.body as BlockFunctionBody).block;
            for (var statement in block.statements) {
              if (statement is ExpressionStatement) {
                var expr = statement.expression;

                if (expr is MethodInvocation) {
                  var target = expr.target;
                  var methodName = expr.methodName.name;

                  // Check for field.dispose() or field.close()
                  if (target is SimpleIdentifier) {
                    if ((methodName == 'dispose' || methodName == 'close') &&
                        disposableFields.contains(target.name)) {
                      disposedFields.add(target.name);
                    }
                  }

                  // Check for super.dispose()
                  if (target is SuperExpression && methodName == 'dispose') {
                    superDisposeCalled = true;
                  }
                }
              }
            }
          }

          // Emit findings for fields not disposed
          for (var field in disposableFields) {
            if (!disposedFields.contains(field)) {
              findings.add(
                Finding(
                  rule: 'missing_dispose',
                  filePath: filePath,
                  lineNumber: lineInfo.getLocation(classNameOffset).lineNumber,
                  message:
                      'Field "$field" is not disposed in dispose() method.',
                  severity: Severity.warning,
                  suggestion:
                      'Add $field.dispose() inside the dispose() method.',
                ),
              );
            }
          }

          // Emit finding if super.dispose() is not called
          if (!superDisposeCalled) {
            final disposeNameOffset = disposeMethod.name.offset;
            findings.add(
              Finding(
                rule: 'missing_dispose',
                filePath: filePath,
                lineNumber: lineInfo.getLocation(disposeNameOffset).lineNumber,
                message: 'super.dispose() is not called in dispose() method.',
                severity: Severity.warning,
                suggestion:
                    'Add super.dispose() at the end of dispose() method.',
              ),
            );
          }
        }
      }
    }

    super.visitClassDeclaration(node);
  }
}
