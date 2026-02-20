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

