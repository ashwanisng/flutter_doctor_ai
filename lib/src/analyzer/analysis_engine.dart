import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:flutter_doctor_ai/src/analyzer/rules/base_rule.dart';
import 'package:flutter_doctor_ai/src/analyzer/rules/empty_state_rule.dart';
import 'package:flutter_doctor_ai/src/analyzer/rules/large_build_rule.dart';
import 'package:flutter_doctor_ai/src/analyzer/rules/missing_dispose_rule.dart';
import 'package:flutter_doctor_ai/src/analyzer/rules/missing_mounted_check_rule.dart';
import 'package:flutter_doctor_ai/src/analyzer/rules/print_statement_rule.dart';
import 'package:flutter_doctor_ai/src/models/finding.dart';
import 'package:flutter_doctor_ai/src/models/project_info.dart';

/// Result of analyzing an entire project.
class ProjectAnalysisResult {
  /// All findings from all rules
  final List<Finding> findings;

  /// Total number of classes found
  final int totalClasses;

  /// Total number of widgets found
  final int totalWidgets;

  /// Number of StatelessWidget classes
  final int statelessCount;

  /// Number of StatefulWidget classes
  final int statefulCount;

  const ProjectAnalysisResult({
    required this.findings,
    required this.totalClasses,
    required this.totalWidgets,
    required this.statelessCount,
    required this.statefulCount,
  });
}

/// Main analysis engine that runs all rules against a project.
///
/// Parses each file only once for efficiency.
///
/// Example:
/// ```dart
/// final engine = AnalysisEngine();
/// final result = engine.analyzeProject(projectInfo.files);
/// print('Found ${result.findings.length} issues');
/// print('Classes: ${result.totalClasses}, Widgets: ${result.totalWidgets}');
/// ```
class AnalysisEngine {
  /// List of analysis rules to run
  final List<BaseRule> rules;

  AnalysisEngine({List<BaseRule>? rules}) : rules = rules ?? _defaultRules();

  /// Creates an engine with all built-in rules.
  static List<BaseRule> _defaultRules() {
    return [
      LargeBuildRule(),
      EmptySetStateRule(),
      PrintStatementRule(),
      MissingMountedCheckRule(),
      MissingDisposeRule(),
    ];
  }

  /// Analyze all files and return findings along with statistics.
  ///
  /// Each file is parsed only once for efficiency.
  ProjectAnalysisResult analyzeProject(List<DartFile> files) {
    final allFindings = <Finding>[];
    int totalClasses = 0;
    int totalWidgets = 0;
    int statelessCount = 0;
    int statefulCount = 0;

    for (final file in files) {
      // Parse the file ONCE
      final parseResult = parseString(content: file.content);
      final unit = parseResult.unit;

      // Run all rules on the parsed AST
      for (final rule in rules) {
        allFindings.addAll(rule.analyze(unit, file.path));
      }

      // Extract statistics from the same parsed AST
      final stats = _extractStatistics(unit);
      totalClasses += stats.classCount;
      totalWidgets += stats.widgetCount;
      statelessCount += stats.statelessCount;
      statefulCount += stats.statefulCount;
    }

    return ProjectAnalysisResult(
      findings: allFindings,
      totalClasses: totalClasses,
      totalWidgets: totalWidgets,
      statelessCount: statelessCount,
      statefulCount: statefulCount,
    );
  }

  /// Extract class/widget statistics from a parsed AST.
  _FileStats _extractStatistics(CompilationUnit unit) {
    int classCount = 0;
    int widgetCount = 0;
    int statelessCount = 0;
    int statefulCount = 0;

    for (final declaration in unit.declarations) {
      if (declaration is ClassDeclaration) {
        classCount++;

        final superclassBase = declaration.extendsClause?.superclass.name.lexeme;

        if (superclassBase == 'StatelessWidget') {
          widgetCount++;
          statelessCount++;
        } else if (superclassBase == 'StatefulWidget') {
          widgetCount++;
          statefulCount++;
        }
      }
    }

    return _FileStats(
      classCount: classCount,
      widgetCount: widgetCount,
      statelessCount: statelessCount,
      statefulCount: statefulCount,
    );
  }

  /// Analyze a single file (for backward compatibility).
  List<Finding> analyzeFile(DartFile file) {
    final parseResult = parseString(content: file.content);
    final unit = parseResult.unit;

    final findings = <Finding>[];
    for (final rule in rules) {
      findings.addAll(rule.analyze(unit, file.path));
    }

    return findings;
  }
}

/// Internal class for file statistics.
class _FileStats {
  final int classCount;
  final int widgetCount;
  final int statelessCount;
  final int statefulCount;

  const _FileStats({
    required this.classCount,
    required this.widgetCount,
    required this.statelessCount,
    required this.statefulCount,
  });
}