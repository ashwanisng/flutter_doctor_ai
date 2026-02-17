import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:flutter_doctor_ai/src/analyzer/analysis_engine.dart';
import 'package:flutter_doctor_ai/src/models/finding.dart';
import 'package:flutter_doctor_ai/src/scanner/ast_parser.dart';
import 'package:flutter_doctor_ai/src/scanner/project_scanner.dart';
import 'package:flutter_doctor_ai/src/utils/helpers.dart';

class AnalyzeCommand extends Command<int> {
  AnalyzeCommand() {
    argParser.addFlag(
      'verbose',
      abbr: 'v',
      defaultsTo: false,
      help: 'Show detailed analysis output',
    );
  }

  @override
  String get name => 'analyze';

  @override
  String get description => 'Analyze a Flutter project for issues';

  @override
  Future<int> run() async {
    String projectPath = argResults!.rest.isEmpty
        ? '.'
        : argResults!.rest.first;
    bool verbose = argResults!['verbose'] as bool;

    print('🔍 Analyzing Flutter project...\n');

    try {
      final projectInfo = await ProjectScanner().scan(projectPath);

      // Parse files
      final astParser = AstParser();
      int totalClasses = 0;
      int totalWidgets = 0;
      int statelessCount = 0;
      int statefulCount = 0;

      for (var file in projectInfo.files) {
        final analysis = astParser.parseFile(file);
        totalClasses += analysis.classes.length;
        totalWidgets += analysis.widgets.length;

        for (var widget in analysis.widgets) {
          if (widget.type == 'StatelessWidget') statelessCount++;
          if (widget.type == 'StatefulWidget') statefulCount++;
        }
      }

      // Run analysis
      final engine = AnalysisEngine();
      final findings = engine.analyzeProject(projectInfo.files);

      // Calculate stats
      int avgLinesPerFile = projectInfo.totalFiles > 0
          ? (projectInfo.totalLinesOfCode / projectInfo.totalFiles).round()
          : 0;

      final statelessPercent = totalWidgets > 0
          ? (statelessCount / totalWidgets * 100).toStringAsFixed(1)
          : '0';
      final statefulPercent = totalWidgets > 0
          ? (statefulCount / totalWidgets * 100).toStringAsFixed(1)
          : '0';

      final sortedFiles =
          projectInfo.files.where((f) => f.linesOfCode > 0).toList()
            ..sort((a, b) => b.linesOfCode.compareTo(a.linesOfCode));
      final largestFiles = sortedFiles.take(5);

      // Print results
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📦  PROJECT INFO');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('  Name:     ${projectInfo.name}');
      print('  Version:  v${projectInfo.version}');
      print('  Path:     ${projectInfo.path}');
      print('  Flutter:  ${projectInfo.isFlutterProject ? '✓ Yes' : '✗ No'}');
      print('');

      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📊  CODE STATISTICS');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('  Files:          ${projectInfo.totalFiles}');
      print('  Lines of code:  ${formatNumber(projectInfo.totalLinesOfCode)}');
      print('  Classes:        $totalClasses');
      print('  Widgets:        $totalWidgets');
      print('  Avg lines/file: $avgLinesPerFile');
      print('');
      print('  Widget Types:');
      print('    • StatelessWidget: $statelessCount ($statelessPercent%)');
      print('    • StatefulWidget:  $statefulCount ($statefulPercent%)');
      print('');

      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📂  LARGEST FILES');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      for (var file in largestFiles) {
        final name = file.name.padRight(35);
        print('  • $name ${formatNumber(file.linesOfCode)} lines');
      }
      print('');

      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('⏱️  Scan completed in ${formatDuration(projectInfo.scanTime)}');
      print('');

      // Issues section
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🔎  ISSUES FOUND');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      if (findings.isEmpty) {
        print('  ✨ No issues found! Great job!');
      } else {
        print('  Found ${findings.length} issue(s)');
        print('');

        // Count by severity
        int errors = findings.where((f) => f.severity == Severity.error).length;
        int warnings = findings
            .where((f) => f.severity == Severity.warning)
            .length;
        int infos = findings.where((f) => f.severity == Severity.info).length;

        print('  Summary:');
        print('    ❌ Errors:   $errors');
        print('    ⚠️  Warnings: $warnings');
        print('    ℹ️  Info:     $infos');
        print('');

        // Group findings by rule
        Map<String, List<Finding>> findingsByRule = {};
        for (var finding in findings) {
          findingsByRule.putIfAbsent(finding.rule, () => []).add(finding);
        }

        print('  By Rule:');
        for (var entry in findingsByRule.entries) {
          final ruleName = entry.key;
          final issues = entry.value;

          print('    • $ruleName (${issues.length} issues):');

          for (var issue in issues) {
            // Extract file name and path
            final fullPath = issue.filePath;
            final fileName = fullPath.split('/').last;
            print('        - $fileName');
          }
        }
        print('');
        // Top offenders (only for large_build_method)
        final largeBuildFindings = findingsByRule['large_build_method'] ?? [];
        if (largeBuildFindings.isNotEmpty) {
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          print('🚨  TOP OFFENDERS (Large Build Methods)');
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

          final sortedLargeBuild = [...largeBuildFindings]
            ..sort((a, b) {
              final aLines = extractLineCount(a.message);
              final bLines = extractLineCount(b.message);
              return bLines.compareTo(aLines);
            });

          final topOffenders = sortedLargeBuild.take(5);
          for (var finding in topOffenders) {
            final fileName = finding.filePath.split('/').last;
            final lines = extractLineCount(finding.message);
            print('  • $fileName — $lines lines');
          }
          print('');
        }

        // Verbose: show all issues grouped by rule
        if (verbose) {
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          print('📋  ALL ISSUES');
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

          for (var entry in findingsByRule.entries) {
            print('');
            print('  📌 ${entry.key} (${entry.value.length} issues)');
            print('  ─────────────────────────────────');

            for (var finding in entry.value) {
              String icon = finding.severity == Severity.error
                  ? '❌'
                  : finding.severity == Severity.warning
                  ? '⚠️'
                  : 'ℹ️';

              final fileName = finding.filePath.split('/').last;
              print('  $icon $fileName:${finding.lineNumber}');
              print('     ${finding.message}');
              if (finding.suggestion != null) {
                print('     💡 ${finding.suggestion}');
              }
            }
          }
        } else {
          print('  💡 Run with --verbose to see all issues');
        }
      }

      return 0;
    } catch (e) {
      stderr.writeln('Error: $e');
      return 1;
    }
  }
}
