/// AI-powered Flutter code analysis library.
///
/// This library provides tools to analyze Flutter/Dart projects for common
/// issues like large build methods, missing dispose calls, empty setState,
/// and more. It also integrates with AI providers (Groq, Gemini, OpenAI,
/// Anthropic) to provide intelligent fix suggestions.
///
/// ## Quick Start
///
/// ```dart
/// import 'package:flutter_doctor_ai/flutter_doctor_ai.dart';
///
/// void main() async {
///   // Scan a project
///   final scanner = ProjectScanner();
///   final projectInfo = await scanner.scan('/path/to/project');
///
///   // Run analysis
///   final engine = AnalysisEngine();
///   final findings = engine.analyzeProject(projectInfo.files);
///
///   // Print results
///   for (final finding in findings) {
///     print('[${finding.severity.name}] ${finding.message}');
///     print('  File: ${finding.filePath}:${finding.lineNumber}');
///   }
/// }
/// ```
///
/// ## AI Integration
///
/// ```dart
/// // Get AI-powered fix suggestions
/// final ai = AIFactory.create('groq', 'your-api-key');
/// final suggestion = await ai.getSuggestion(
///   issue: finding.message,
///   code: sourceCode,
///   filePath: finding.filePath,
/// );
/// print(suggestion);
/// ```
///
/// ## Available Rules
///
/// - `large_build_method` - Detects build methods over 50 lines
/// - `empty_setstate` - Detects empty setState calls
/// - `print_statement` - Detects print statements in production code
/// - `missing_mounted_check` - Detects setState after await without mounted check
/// - `missing_dispose` - Detects undisposed controllers and streams
///
/// ## CLI Usage
///
/// ```bash
/// # Install globally
/// dart pub global activate flutter_doctor_ai
///
/// # Analyze a project
/// flutter_doctor_ai analyze /path/to/project
///
/// # With AI suggestions
/// flutter_doctor_ai analyze . --ai --provider=groq --api-key=YOUR_KEY
///
/// # JSON output for CI/CD
/// flutter_doctor_ai analyze . --json
/// ```
library;

// Core models
export 'src/models/analysis_result.dart';
export 'src/models/finding.dart';
export 'src/models/project_info.dart';

// Scanner
export 'src/scanner/ast_parser.dart';
export 'src/scanner/project_scanner.dart';

// Analyzer
export 'src/analyzer/analysis_engine.dart';
export 'src/analyzer/rules/base_rule.dart';
export 'src/analyzer/rules/empty_state_rule.dart';
export 'src/analyzer/rules/large_build_rule.dart';
export 'src/analyzer/rules/missing_dispose_rule.dart';
export 'src/analyzer/rules/missing_mounted_check_rule.dart';
export 'src/analyzer/rules/print_statement_rule.dart';

// Scoring
export 'src/scoring/health_score.dart';

// AI (for library users who want AI integration)
export 'src/ai/ai_provider.dart';
export 'src/ai/ai_factory.dart';
export 'src/ai/groq_provider.dart';
export 'src/ai/gemini_provider.dart';
export 'src/ai/openai_provider.dart';
export 'src/ai/anthropic_provider.dart';
export 'src/ai/prompt_builder.dart';
export 'src/models/ai_config.dart';
export 'src/utils/helpers.dart';