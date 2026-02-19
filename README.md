# flutter_doctor_ai

AI-powered Flutter code analysis tool.

---

## Overview

`flutter_doctor_ai` is a static analysis and linting tool for Dart and Flutter projects, powered by both traditional static rules and optional AI suggestions. It helps you:
- Detect common Flutter anti-patterns and code smells
- Enforce best practices in your codebase
- Get actionable suggestions for code improvement
- Optionally, receive AI-powered fix suggestions (with your API key)

## Features
- **Static rules** for large build methods, missing dispose, print statements, empty setState, and more
- **Project health scoring**
- **AI integration** (Groq, Gemini, OpenAI, Anthropic) for advanced suggestions
- **Command-line interface** for easy use
- **Extensible**: add your own rules

## Getting Started

### 1. Install
Add to your `pubspec.yaml`:
```yaml
dependencies:
  flutter_doctor_ai: ^0.1.0
```
Then run:
```bash
dart pub get
```

### 2. Usage
#### Command Line
You can run the analyzer from the command line:
```bash
dart run bin/flutter_doctor_ai.dart [project_path]
```
- If no path is given, it analyzes the current directory.
- Use `--ai` to enable AI suggestions (requires API key).

#### As a Library
You can use the API in your own Dart code:
```dart
import 'package:flutter_doctor_ai/flutter_doctor_ai.dart';
import 'dart:io';

void main(List<String> args) async {
  final projectPath = args.isNotEmpty ? args[0] : Directory.current.path;
  final scanner = ProjectScanner();
  final projectInfo = await scanner.scan(projectPath);
  final engine = AnalysisEngine();
  final findings = engine.analyzeProject(projectInfo.files);
  for (final finding in findings) {
    print('[[33m${finding.severity.name.toUpperCase()}[0m] Rule: ${finding.rule}');
    print('  File: ${finding.filePath} (Line: ${finding.lineNumber})');
    print('  Message: ${finding.message}');
    if (finding.suggestion != null) {
      print('  Suggestion: ${finding.suggestion}');
    }
    print('');
  }
}
```

## Example
See the [`example/`](example/) directory for a full working example.

## Rules
- **large_build_method**: Warns if a build method is too long
- **empty_setstate**: Warns if setState is called with an empty body
- **print_statement**: Warns if print statements are used
- **missing_mounted_check**: Warns if setState is called in async methods without checking `mounted`
- **missing_dispose**: Warns if disposable resources are not disposed in State classes

## AI Suggestions
To enable AI-powered suggestions, use the `--ai` flag and provide your API key for the selected provider (Groq, Gemini, OpenAI, Anthropic). You can configure the provider and model interactively or via CLI options.

## Contributing
See [CONTRIBUTING.md](CONTRIBUTING.md).

## License
MIT
