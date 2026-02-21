import 'package:flutter_doctor_ai/flutter_doctor_ai.dart';
import 'dart:io';

void main(List<String> args) async {
  // Example: Analyze a Dart/Flutter project directory
  final projectPath = args.isNotEmpty ? args[0] : Directory.current.path;
  print('Scanning project at: $projectPath');

  // Scan the project for Dart files and metadata
  final scanner = ProjectScanner();
  final projectInfo = await scanner.scan(projectPath);
  print('Project: ${projectInfo.name} (v${projectInfo.version})');
  print(
    'Dart files: ${projectInfo.totalFiles}, Total lines: ${projectInfo.totalLinesOfCode}',
  );

  // Run static analysis rules
  final engine = AnalysisEngine();
  final result = engine.analyzeProject(projectInfo.files);

  // Print statistics
  print('');
  print('Statistics:');
  print('  Classes: ${result.totalClasses}');
  print('  Widgets: ${result.totalWidgets}');
  print('    StatelessWidget: ${result.statelessCount}');
  print('    StatefulWidget: ${result.statefulCount}');
  print('');

  // Print findings
  if (result.findings.isEmpty) {
    print('No issues found!');
  } else {
    print('Found ${result.findings.length} issue(s):');
    print('');
    for (final finding in result.findings) {
      print('[${finding.severity.name.toUpperCase()}] Rule: ${finding.rule}');
      print('  File: ${finding.filePath} (Line: ${finding.lineNumber})');
      print('  Message: ${finding.message}');
      if (finding.suggestion != null) {
        print('  Suggestion: ${finding.suggestion}');
      }
      print('');
    }
  }
}
