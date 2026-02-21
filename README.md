# flutter_doctor_ai

[![pub package](https://img.shields.io/pub/v/flutter_doctor_ai.svg)](https://pub.dev/packages/flutter_doctor_ai)
[![Dart SDK](https://img.shields.io/badge/dart-%3E%3D3.0.0-blue)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

AI-powered static analysis CLI and library for Flutter/Dart projects. Detect common anti-patterns, measure project health, and get AI-generated fix suggestions — all from a single command.

---

## Table of Contents

- [Features](#features)
- [Installation](#installation)
  - [Global CLI](#global-cli)
  - [Library dependency](#library-dependency)
- [Quick Start](#quick-start)
- [CLI Usage](#cli-usage)
  - [Basic analysis](#basic-analysis)
  - [Flags and options](#flags-and-options)
  - [AI suggestions](#ai-suggestions)
  - [JSON output](#json-output)
- [AI Providers](#ai-providers)
  - [Groq](#groq)
  - [Gemini](#gemini)
  - [OpenAI](#openai)
  - [Anthropic](#anthropic)
- [Library API](#library-api)
  - [Scan a project](#scan-a-project)
  - [Run analysis](#run-analysis)
  - [Health scoring](#health-scoring)
- [Analysis Rules](#analysis-rules)
- [Custom Rules](#custom-rules)
- [JSON Output Schema](#json-output-schema)
- [Health Score](#health-score)
- [Contributing](#contributing)
- [License](#license)

---

## Features

- **5 built-in static rules** covering the most common Flutter anti-patterns
- **Project health score** (0–100) with letter grade, normalised by lines of code
- **AI-powered fix suggestions** from Groq, Gemini, OpenAI, or Anthropic
- **Automatic model fallback** — if your chosen model is unavailable, the next one is tried automatically
- **JSON output** for CI/CD pipelines and custom tooling
- **Extensible** — implement `BaseRule` to add your own checks
- **Zero Flutter SDK required** — pure Dart, works anywhere the Dart SDK is installed

---

## Installation

### Global CLI

Install the tool globally to use it from any directory:

```bash
dart pub global activate flutter_doctor_ai
```

Then run it anywhere:

```bash
flutter_doctor_ai analyze /path/to/your/flutter/project
```

### Library dependency

Add the package to your `pubspec.yaml` to use it programmatically:

```yaml
dependencies:
  flutter_doctor_ai: ^0.1.0
```

```bash
dart pub get
```

---

## Quick Start

```bash
# Analyze the current directory
flutter_doctor_ai analyze .

# Analyze a specific project
flutter_doctor_ai analyze /path/to/my_app

# Verbose output (shows every individual issue)
flutter_doctor_ai analyze . --verbose

# Get AI suggestions for the top 3 issues (interactive setup)
flutter_doctor_ai analyze . --ai

# Non-interactive: pass provider and key directly
flutter_doctor_ai analyze . --ai --provider groq --api-key gsk_...

# Machine-readable JSON output
flutter_doctor_ai analyze . --json
```

---

## CLI Usage

### Basic analysis

```
flutter_doctor_ai analyze [project_path] [options]
```

If `project_path` is omitted, the current directory is used.

### Flags and options

| Flag / Option | Short | Default | Description |
|---|---|---|---|
| `--verbose` | `-v` | `false` | Show every individual issue with file and line number |
| `--json` | `-j` | `false` | Output results as a JSON document (suppresses all other output) |
| `--ai` | | `false` | Fetch AI-generated fix suggestions for the top 3 issues |
| `--provider` | `-p` | `groq` | AI provider: `groq`, `gemini`, `openai`, `anthropic` |
| `--api-key` | | | API key for the chosen provider (skips interactive prompt) |
| `--model` | `-m` | provider default | Override the AI model (falls back to provider defaults if unavailable) |

### AI suggestions

When `--ai` is passed without `--api-key`, the tool enters an interactive setup wizard that prompts for provider, API key, and optionally a model name.

To run non-interactively (useful in scripts):

```bash
flutter_doctor_ai analyze . \
  --ai \
  --provider anthropic \
  --api-key sk-ant-... \
  --model claude-sonnet-4-6
```

Suggestions are fetched for the **top 3 issues**, sorted by severity (errors first, then warnings, then info).

### JSON output

Use `--json` to emit a single JSON document to `stdout`. All human-readable output is suppressed, making it easy to pipe into `jq` or a CI step:

```bash
flutter_doctor_ai analyze . --json | jq '.healthScore'
```

See [JSON Output Schema](#json-output-schema) for the full structure.

---

## AI Providers

### Groq

Fast, free tier available. Best for quick iteration.

```bash
flutter_doctor_ai analyze . --ai --provider groq --api-key gsk_...
```

**Default model:** `llama-3.3-70b-versatile`

| Model | Notes |
|---|---|
| `llama-3.3-70b-versatile` | Default, recommended |
| `llama-3.1-70b-versatile` | Fallback |
| `llama-3.1-8b-instant` | Fastest |
| `mixtral-8x7b-32768` | Long context |

Get an API key at [console.groq.com](https://console.groq.com).

---

### Gemini

Google's multimodal models. Free tier available via Google AI Studio.

```bash
flutter_doctor_ai analyze . --ai --provider gemini --api-key AIza...
```

**Default model:** `gemini-2.5-flash`

| Model | Notes |
|---|---|
| `gemini-2.5-flash` | Default, fast and capable |
| `gemini-2.5-pro` | Most capable |
| `gemini-2.0-flash` | Stable release |

Get an API key at [aistudio.google.com](https://aistudio.google.com).

---

### OpenAI

GPT models via the OpenAI API.

```bash
flutter_doctor_ai analyze . --ai --provider openai --api-key sk-...
```

**Default model:** `gpt-4o-mini`

| Model | Notes |
|---|---|
| `gpt-4o-mini` | Default, fast and cost-efficient |
| `gpt-4o` | Most capable GPT-4 class model |
| `gpt-4-turbo` | Long context |
| `gpt-3.5-turbo` | Fastest, lowest cost |

Get an API key at [platform.openai.com](https://platform.openai.com).

---

### Anthropic

Claude models, known for strong code analysis and explanation quality.

```bash
flutter_doctor_ai analyze . --ai --provider anthropic --api-key sk-ant-...
```

**Default model:** `claude-haiku-4-5-20251001`

| Model | Notes |
|---|---|
| `claude-haiku-4-5-20251001` | Default, fastest Claude |
| `claude-sonnet-4-6` | Best balance of speed and capability |
| `claude-opus-4-6` | Most capable |

Get an API key at [console.anthropic.com](https://console.anthropic.com).

---

## Library API

### Scan a project

`ProjectScanner` recursively finds all `.dart` files under `lib/` and collects metadata from `pubspec.yaml`.

```dart
import 'package:flutter_doctor_ai/flutter_doctor_ai.dart';

final scanner = ProjectScanner();
final projectInfo = await scanner.scan('/path/to/my_app');

print('Project: ${projectInfo.name} v${projectInfo.version}');
print('Files:   ${projectInfo.totalFiles}');
print('Lines:   ${projectInfo.totalLinesOfCode}');
print('Flutter: ${projectInfo.isFlutterProject}');
```

### Run analysis

`AnalysisEngine` parses each file **once** and runs all rules against the resulting AST, then returns both findings and codebase statistics in a single `ProjectAnalysisResult`.

```dart
import 'package:flutter_doctor_ai/flutter_doctor_ai.dart';

final scanner = ProjectScanner();
final projectInfo = await scanner.scan('/path/to/my_app');

final engine = AnalysisEngine();
final result = engine.analyzeProject(projectInfo.files);

print('Issues:   ${result.findings.length}');
print('Classes:  ${result.totalClasses}');
print('Widgets:  ${result.totalWidgets}');
print('  StatelessWidget: ${result.statelessCount}');
print('  StatefulWidget:  ${result.statefulCount}');

for (final finding in result.findings) {
  print('[${finding.severity.name.toUpperCase()}] ${finding.rule}');
  print('  ${finding.filePath}:${finding.lineNumber}');
  print('  ${finding.message}');
  if (finding.suggestion != null) {
    print('  Suggestion: ${finding.suggestion}');
  }
}
```

#### Analyze a single file

```dart
final file = DartFile(
  path: 'lib/main.dart',
  content: await File('lib/main.dart').readAsString(),
);

final findings = engine.analyzeFile(file);
```

#### Use a custom set of rules

```dart
final engine = AnalysisEngine(rules: [
  LargeBuildRule(),
  MissingDisposeRule(),
  MyCustomRule(),
]);
```

### Health scoring

`HealthScorer` produces a normalised 0–100 score and letter grade based on issue density (weighted issues per 1 000 lines of code).

```dart
import 'package:flutter_doctor_ai/flutter_doctor_ai.dart';

final scorer = HealthScorer(
  totalLines: projectInfo.totalLinesOfCode,
  findings: result.findings,
);

final health = scorer.calculate();

print('Score: ${health.score}/100 (${health.grade})');
print('${health.emoji} ${health.message}');
print('Issues/KLOC: ${health.issuesPerKLOC.toStringAsFixed(1)}');
```

---

## Analysis Rules

All rules ship with the default `AnalysisEngine`. Each finding includes the rule name, file path, line number, a human-readable message, and an optional code suggestion.

### `large_build_method`

**Severity:** warning

Fires when a `build` method exceeds 50 lines. Long build methods are hard to read, test, and maintain. Extract subtrees into smaller widget methods or dedicated widget classes.

```
WARNING  large_build_method
  lib/screens/home_screen.dart:12
  build() method is 87 lines long. Consider breaking it into smaller widgets.
  Suggestion: Extract subtrees into private widget methods or separate Widget classes.
```

---

### `empty_setstate`

**Severity:** warning

Fires when `setState(() {})` is called with an empty closure. An empty `setState` triggers a rebuild with no state change, wasting CPU cycles and causing unnecessary repaints.

```
WARNING  empty_setstate
  lib/widgets/counter.dart:34
  Empty setState() call found. Remove it or move state changes inside the closure.
```

---

### `print_statement`

**Severity:** info

Fires when a top-level `print()` call is found in production code (files outside `test/`). Use a structured logging package instead, and remove debug prints before shipping.

```
INFO  print_statement
  lib/services/auth_service.dart:56
  Avoid using print() in production code.
  Suggestion: Use a logging package such as 'logger' or 'logging'.
```

---

### `missing_mounted_check`

**Severity:** warning

Fires when `setState` is called inside an `async` function body without a preceding `if (mounted)` guard. Calling `setState` on an unmounted widget throws a runtime exception.

```
WARNING  missing_mounted_check
  lib/screens/detail_screen.dart:78
  setState() called in async context without mounted check.
  Suggestion: Add `if (!mounted) return;` before calling setState().
```

---

### `missing_dispose`

**Severity:** warning

Fires on `State` subclasses that declare disposable fields (`AnimationController`, `TextEditingController`, `ScrollController`, `TabController`, `PageController`, `FocusNode`, `StreamController`, `StreamSubscription`, etc.) but:

1. Have **no `dispose()` method** at all, or
2. Have a `dispose()` method that **does not call `.dispose()`/`.close()`/`.cancel()`** on every disposable field, or
3. Have a `dispose()` method that **does not call `super.dispose()`**.

```
WARNING  missing_dispose
  lib/screens/profile_screen.dart:10
  Field "_tabController" is not disposed in dispose() method.
  Suggestion: Add _tabController.dispose() inside the dispose() method.

WARNING  missing_dispose
  lib/screens/profile_screen.dart:10
  super.dispose() is not called in dispose() method.
  Suggestion: Add super.dispose() at the end of dispose() method.
```

---

## Custom Rules

Extend `BaseRule` to add your own checks. Pass your rules to `AnalysisEngine` at construction time.

```dart
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_doctor_ai/flutter_doctor_ai.dart';

class NoDebuggerRule extends BaseRule {
  @override
  String get name => 'no_debugger';

  @override
  String get description => 'Disallows debugger() calls in production code.';

  @override
  Severity get severity => Severity.error;

  @override
  List<Finding> analyze(CompilationUnit unit, String filePath) {
    final visitor = _DebuggerVisitor(filePath, unit.lineInfo);
    unit.visitChildren(visitor);
    return visitor.findings;
  }
}

class _DebuggerVisitor extends RecursiveAstVisitor<void> {
  final String filePath;
  final lineInfo;
  final findings = <Finding>[];

  _DebuggerVisitor(this.filePath, this.lineInfo);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'debugger' && node.target == null) {
      findings.add(Finding(
        rule: 'no_debugger',
        filePath: filePath,
        lineNumber: lineInfo.getLocation(node.offset).lineNumber,
        message: 'Remove debugger() before shipping to production.',
        severity: Severity.error,
      ));
    }
    super.visitMethodInvocation(node);
  }
}

// Use it:
final engine = AnalysisEngine(rules: [
  ...AnalysisEngine().rules, // keep the defaults
  NoDebuggerRule(),
]);
```

---

## JSON Output Schema

When `--json` is passed, the tool writes a single JSON object to `stdout`. The schema is stable across patch versions.

```json
{
  "project": {
    "name": "my_app",
    "version": "1.0.0",
    "path": "/Users/me/my_app",
    "isFlutterProject": true,
    "scanTimeMs": "120ms"
  },
  "statistics": {
    "totalFiles": 42,
    "totalLinesOfCode": 8500,
    "totalClasses": 67,
    "totalWidgets": 30,
    "statelessWidgets": 18,
    "statefulWidgets": 12
  },
  "summary": {
    "total": 7,
    "errors": 0,
    "warnings": 6,
    "info": 1
  },
  "healthScore": {
    "score": 82,
    "grade": "B",
    "issuesPerKLOC": 7.18
  },
  "findings": [
    {
      "rule": "missing_dispose",
      "message": "Field \"_controller\" is not disposed in dispose() method.",
      "filePath": "/Users/me/my_app/lib/screens/home.dart",
      "lineNumber": 12,
      "severity": "warning",
      "suggestion": "Add _controller.dispose() inside the dispose() method."
    }
  ]
}
```

### CI/CD integration example

```yaml
# .github/workflows/analysis.yml
- name: Run flutter_doctor_ai
  run: |
    dart pub global activate flutter_doctor_ai
    flutter_doctor_ai analyze . --json > analysis.json
    score=$(jq '.healthScore.score' analysis.json)
    echo "Health score: $score"
    if [ "$score" -lt 70 ]; then
      echo "Health score below threshold (70). Failing build."
      exit 1
    fi
```

---

## Health Score

The health score is a single number from **0 to 100** that summarises code quality relative to project size.

### Formula

```
weightedIssues = (errors × 3) + (warnings × 1) + (info × 0.25)
kloc           = max(totalLines / 1000, 1.0)
issuesPerKLOC  = weightedIssues / kloc
score          = clamp(100 − issuesPerKLOC × 2.5, 0, 100)
```

### Grade table

| Score | Grade | Meaning |
|---|---|---|
| 90–100 | A | Excellent — code is in great shape |
| 80–89 | B | Good — minor improvements possible |
| 70–79 | C | Fair — consider addressing some issues |
| 60–69 | D | Needs attention — several issues found |
| 0–59 | F | Critical — major issues require attention |

Errors are weighted **3×** and info findings **0.25×** to reflect their relative impact on maintainability. The score is normalised by KLOC so it stays comparable across projects of different sizes.

---

## Contributing

Contributions are welcome! Please open an issue before submitting a pull request for large changes.

1. Fork the repository
2. Create a feature branch: `git checkout -b feat/my-rule`
3. Write your change and add tests under `test/`
4. Run the test suite: `dart test`
5. Submit a pull request

Report bugs and request features at the [issue tracker](https://github.com/ashwanisng/flutter_doctor_ai/issues).

---

## License

MIT — see [LICENSE](LICENSE) for the full text.