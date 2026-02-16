import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:flutter_doctor_ai/src/models/analysis_result.dart';
import 'package:flutter_doctor_ai/src/models/project_info.dart';

class AstParser {
  FileAnalysis parseFile(DartFile file) {
    final parseResult = parseString(content: file.content);
    final unit = parseResult.unit;

    final visitor = _ClassVisitor(lineInfo: unit.lineInfo);
    unit.visitChildren(visitor);

    return FileAnalysis(
      filePath: file.path,
      classes: visitor.classes,
      widgets: visitor.widgets,
    );
  }
}

class _ClassVisitor extends RecursiveAstVisitor<void> {
  _ClassVisitor({LineInfo? lineInfo})
    : lineInfo = lineInfo ?? LineInfo(const []);

  final LineInfo lineInfo;
  final List<ClassInfo> classes = [];
  final List<WidgetInfo> widgets = [];

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    String className = node.name.lexeme;
    String? superclass = node.extendsClause?.superclass.name.lexeme;

    List<String> methods = node.members
        .whereType<MethodDeclaration>()
        .map((e) => e.name.lexeme)
        .toList();

    int lineNumber = lineInfo.getLocation(node.offset).lineNumber;

    bool hasConstructor = node.members.any(
      (member) =>
          member is ConstructorDeclaration && member.constKeyword != null,
    );

    classes.add(
      ClassInfo(
        name: className,
        methods: methods,
        lineNumber: lineNumber,
        superClass: superclass,
      ),
    );

    if (superclass == 'StatelessWidget' || superclass == 'StatefulWidget') {
      widgets.add(
        WidgetInfo(
          name: className,
          type: superclass!,
          lineNumber: lineNumber,
          hasConstConstructor: hasConstructor,
        ),
      );
    }

    super.visitClassDeclaration(node);
  }
}
