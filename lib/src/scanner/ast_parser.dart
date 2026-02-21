import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:flutter_doctor_ai/src/models/analysis_result.dart';
import 'package:flutter_doctor_ai/src/models/project_info.dart';

/// Parses Dart source files into structured analysis results.
///
/// @deprecated Use [AnalysisEngine.analyzeProject] instead, which parses
/// each file only once for better performance.
@Deprecated('Use AnalysisEngine.analyzeProject instead')
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
    String className = node.namePart.typeName.lexeme;

    // Store the base class name only (e.g. "State" not "State<MyWidget>"),
    // so ClassInfo.superClass is consistent with .name.lexeme used in rules.
    String? superclassName = node.extendsClause?.superclass.name.lexeme;

    final nodeBody = node.body;
    final bodyMembers =
        nodeBody is BlockClassBody ? nodeBody.members : <ClassMember>[];

    List<String> methods = bodyMembers
        .whereType<MethodDeclaration>()
        .map((e) => e.name.lexeme)
        .toList();

    int lineNumber = lineInfo.getLocation(node.offset).lineNumber;

    bool hasConstructor = bodyMembers.any(
      (member) =>
          member is ConstructorDeclaration && member.constKeyword != null,
    );

    classes.add(
      ClassInfo(
        name: className,
        methods: methods,
        lineNumber: lineNumber,
        superClass: superclassName,
      ),
    );

    if (superclassName == 'StatelessWidget' ||
        superclassName == 'StatefulWidget') {
      widgets.add(
        WidgetInfo(
          name: className,
          type: superclassName!,
          lineNumber: lineNumber,
          hasConstConstructor: hasConstructor,
        ),
      );
    }

    super.visitClassDeclaration(node);
  }
}
