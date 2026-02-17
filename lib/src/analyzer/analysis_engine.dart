import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:flutter_doctor_ai/src/analyzer/rules/base_rule.dart';
import 'package:flutter_doctor_ai/src/analyzer/rules/empty_state_rule.dart';
import 'package:flutter_doctor_ai/src/analyzer/rules/large_build_rule.dart';
import 'package:flutter_doctor_ai/src/analyzer/rules/print_statement_rule.dart';
import 'package:flutter_doctor_ai/src/models/finding.dart';
import 'package:flutter_doctor_ai/src/models/project_info.dart';

class AnalysisEngine {
  final List<BaseRule> rules;

  AnalysisEngine({List<BaseRule>? rules}) : rules = rules ?? _defaultRules();

  static List<BaseRule> _defaultRules() {
    return [LargeBuildRule(), EmptySetStateRule(), PrintStatementRule()];
  }

  List<Finding> analyzeFile(DartFile file) {
    final parseResult = parseString(content: file.content);
    final unit = parseResult.unit;

    List<Finding> findings = [];

    for (final rule in rules) {
      findings.addAll(rule.analyze(unit, file.path));
    }

    return findings;
  }

  List<Finding> analyzeProject(List<DartFile> files) {
    List<Finding> findings = [];

    for (final file in files) {
      findings.addAll(analyzeFile(file));
    }

    return findings;
  }
}
