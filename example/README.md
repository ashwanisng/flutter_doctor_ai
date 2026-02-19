# Example usage for flutter_doctor_ai

This directory contains sample code demonstrating how to use the flutter_doctor_ai package in your own projects.

## Getting Started

1. Add `flutter_doctor_ai` to your `pubspec.yaml` dependencies.
2. Run `dart pub get` to install the package.
3. Import the package in your Dart code:
   ```dart
   import 'package:flutter_doctor_ai/flutter_doctor_ai.dart';
   ```
4. Use the provided API to analyze your Flutter project or integrate custom rules.

## Example

See [`main.dart`](main.dart) in this folder for a practical usage example:

```dart
import 'package:flutter_doctor_ai/flutter_doctor_ai.dart';
import 'dart:io';

void main(List<String> args) async {
  final projectPath = args.isNotEmpty ? args[0] : Directory.current.path;
  print('Scanning project at: $projectPath');

  final scanner = ProjectScanner();
  final projectInfo = await scanner.scan(projectPath);
  print('Project: \\${projectInfo.name} (v\\${projectInfo.version})');
  print('Dart files: \\${projectInfo.totalFiles}, Total lines: \\${projectInfo.totalLinesOfCode}');

  final engine = AnalysisEngine();
  final findings = engine.analyzeProject(projectInfo.files);
  if (findings.isEmpty) {
    print('No issues found!');
  } else {
    for (final finding in findings) {
      print('[\${finding.severity.name.toUpperCase()}] Rule: \${finding.rule}');
      print('  File: \${finding.filePath} (Line: \${finding.lineNumber})');
      print('  Message: \${finding.message}');
      if (finding.suggestion != null) {
        print('  Suggestion: \${finding.suggestion}');
      }
      print('');
    }
  }
}
```

This will scan and analyze a Dart/Flutter project in the current directory (or a provided path) and print all findings.
