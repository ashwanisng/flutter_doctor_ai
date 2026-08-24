## 0.2.0

- Upgrade `analyzer` dependency to `^14.1.0`
- Add CI workflow to automatically publish to pub.dev on version bumps merged to `main`
- Remove unused imports from `missing_dispose_rule.dart` and `missing_mounted_check_rule.dart`
- Restructure README code examples to wrap `await`/`print` usage in `main()` functions

## 0.1.0

Initial release.

### Features

- **5 built-in static analysis rules**
  - `large_build_method` — warns when a `build` method exceeds 50 lines
  - `empty_setstate` — warns on `setState(() {})` calls with an empty closure
  - `print_statement` — flags `print()` calls in production code (outside `test/`)
  - `missing_mounted_check` — warns when `setState` is called after `await` without a `mounted` guard
  - `missing_dispose` — warns when disposable fields (`AnimationController`, `TextEditingController`, `ScrollController`, `StreamSubscription`, etc.) are not disposed in the `dispose()` method; also detects missing `super.dispose()` calls

- **`AnalysisEngine`** — single-parse architecture: each file is parsed once and all rules run against the same AST, returning both findings and codebase statistics (`totalClasses`, `totalWidgets`, `statelessCount`, `statefulCount`) in a single `ProjectAnalysisResult`

- **`ProjectScanner`** — recursively scans a project's `lib/` directory, reads `pubspec.yaml` for metadata, and reports file count, total lines of code, and scan time

- **`HealthScorer`** — calculates a 0–100 health score with letter grade (A–F), normalised by issues per 1 000 lines of code; errors weighted 3×, warnings 1×, info 0.25×

- **AI integration** — optional AI-powered fix suggestions for the top 3 issues; supports four providers with automatic model fallback:
  - **Groq** (default: `llama-3.3-70b-versatile`)
  - **Gemini** (default: `gemini-2.5-flash`)
  - **OpenAI** (default: `gpt-4o-mini`)
  - **Anthropic** (default: `claude-sonnet-4-20250514`)

- **CLI** (`flutter_doctor_ai analyze`)
  - `--verbose` / `-v` — show all individual issues with file and line number
  - `--json` / `-j` — emit structured JSON output for CI/CD pipelines
  - `--ai` — enable AI suggestions (interactive or via `--api-key`)
  - `--provider` / `-p` — choose AI provider (`groq`, `gemini`, `openai`, `anthropic`)
  - `--model` / `-m` — override the AI model

- **Extensible rule system** — implement `BaseRule` to add custom checks without modifying the package