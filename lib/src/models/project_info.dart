class ProjectInfo {
  final String path;
  final String name;
  final String version;
  final List<DartFile> files;
  final bool isFlutterProject;
  final Duration scanTime;

  const ProjectInfo({
    required this.path,
    required this.name,
    required this.version,
    required this.files,
    required this.isFlutterProject,
    required this.scanTime,
  });

  int get totalFiles => files.length;

  int get totalLinesOfCode => files.fold(0, (sum, f) => sum + f.linesOfCode);
}

class DartFile {
  final String path;
  final String name;
  final String content;
  final int linesOfCode;

  const DartFile({
    required this.path,
    required this.name,
    required this.content,
    required this.linesOfCode,
  });
}
