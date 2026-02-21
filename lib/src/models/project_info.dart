/// Information about a scanned Dart/Flutter project.
///
/// Contains metadata from pubspec.yaml and statistics
/// about the project's Dart files.
class ProjectInfo {
  /// Project name from pubspec.yaml
  final String name;

  /// Project version from pubspec.yaml
  final String version;

  /// Absolute path to the project root
  final String path;

  /// Whether this is a Flutter project (has flutter dependency)
  final bool isFlutterProject;

  /// List of all Dart files found in the project
  final List<DartFile> files;

  /// Time taken to scan the project
  final Duration scanTime;

  /// Total number of files in the project
  int get totalFiles => files.length;

  /// Total lines of code in the project
  int get totalLinesOfCode => files.fold(0, (sum, f) => sum + f.linesOfCode);

  const ProjectInfo({
    required this.name,
    required this.version,
    required this.path,
    required this.isFlutterProject,
    required this.files,
    required this.scanTime,
  });
}

/// Represents a single Dart source file.
class DartFile {

  /// The full name of the file including extension (e.g., 'main.dart').
  final String name;

  /// Absolute path to the file
  final String path;

  /// Full source content of the file
  final String content;

  /// Number of lines in the file
  final int linesOfCode;

  const DartFile({
    required this.path,
    required this.content,
    required this.linesOfCode,
    required this.name,
  });
}