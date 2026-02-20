class FileAnalysis {
  final String filePath;
  final List<ClassInfo> classes;
  final List<WidgetInfo> widgets;

  const FileAnalysis({
    required this.filePath,
    required this.classes,
    required this.widgets,
  });
}

class ClassInfo {
  final String name;
  final String? superClass;
  final List<String> methods;
  final int lineNumber;

  const ClassInfo({
    required this.name,
    required this.methods,
    this.superClass,
    required this.lineNumber,
  });

  bool get isStatefulWidget => superClass == 'StatefulWidget';
  bool get isStatelessWidget => superClass == 'StatelessWidget';
  bool get isState => superClass?.startsWith('State<') ?? false;
}

class WidgetInfo {
  final String name;
  final String type; // e.g., StatelessWidget, StatefulWidget
  final bool hasConstConstructor;
  final int lineNumber;

  const WidgetInfo({
    required this.name,
    required this.type,
    required this.hasConstConstructor,
    required this.lineNumber,
  });
}
