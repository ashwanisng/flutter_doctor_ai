import 'dart:convert';
import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:flutter_doctor_ai/flutter_doctor_ai.dart';
import 'package:flutter_doctor_ai/src/cli/ai_prompt.dart';
import 'package:flutter_doctor_ai/src/utils/helpers.dart';
import 'package:path/path.dart' as p;

class AnalyzeCommand extends Command<int> {
  AnalyzeCommand() {
    argParser.addFlag(
      'verbose',
      abbr: 'v',
      defaultsTo: false,
      help: 'Show detailed analysis output',
    );

    argParser.addFlag(
      'json',
      abbr: 'j',
      defaultsTo: false,
      help: 'Output results in JSON format',
    );

    argParser.addFlag(
      'ai',
      defaultsTo: false,
      help: 'Get AI-powered fix suggestions',
    );
    argParser.addOption(
      'provider',
      abbr: 'p',
      defaultsTo: 'groq',
      allowed: ['groq', 'gemini', 'openai', 'anthropic'],
      help: 'AI provider to use',
    );
    argParser.addOption('api-key', help: 'API key for the AI provider');
    argParser.addOption('model', abbr: 'm', help: 'AI model to use (optional)');
  }

  @override
  String get name => 'analyze';

  @override
  String get description => 'Analyze a Flutter project for issues';

  @override
  Future<int> run() async {
    String projectPath =
        argResults!.rest.isEmpty ? '.' : argResults!.rest.first;
    bool verbose = argResults!['verbose'] as bool;
    bool useAI = argResults!['ai'] as bool;
    String provider = argResults!['provider'] as String;
    String? apiKey = argResults!['api-key'] as String?;
    bool jsonOutput = argResults!['json'] as bool;

    if (!jsonOutput) {
      print('🔍 Analyzing Flutter project...\n');
    }

    try {
      final projectInfo = await ProjectScanner().scan(projectPath);

      // Run analysis
      final engine = AnalysisEngine();
      final analysisResult = engine.analyzeProject(projectInfo.files);

      final findings = analysisResult.findings;
      final totalClasses = analysisResult.totalClasses;
      final totalWidgets = analysisResult.totalWidgets;
      final statelessCount = analysisResult.statelessCount;
      final statefulCount = analysisResult.statefulCount;

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

      final sortedFiles = projectInfo.files
          .where((f) => f.linesOfCode > 0)
          .toList()
        ..sort((a, b) => b.linesOfCode.compareTo(a.linesOfCode));
      final largestFiles = sortedFiles.take(5);

      final scorer = HealthScorer(
        totalFiles: projectInfo.totalFiles,
        totalLines: projectInfo.totalLinesOfCode,
        findings: findings,
      );
      final healthScore = scorer.calculate();

      if (jsonOutput) {
        _printJsonOutput(
          projectInfo: projectInfo,
          findings: findings,
          totalClasses: totalClasses,
          totalWidgets: totalWidgets,
          statelessCount: statelessCount,
          statefulCount: statefulCount,
          healthScore: healthScore,
        );
      } else {
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
        print(
          '  Lines of code:  ${formatNumber(projectInfo.totalLinesOfCode)}',
        );
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
          if (verbose) {
            print('');
            print('  📋 Analysis Details:');
            print('     • Scanned ${projectInfo.totalFiles} files');
            print(
                '     • Analyzed ${formatNumber(projectInfo.totalLinesOfCode)} lines of code');
            print(
                '     • Checked $totalClasses classes and $totalWidgets widgets');
            print('');
            print('  ✅ Rules checked:');
            for (final rule in engine.rules) {
              print('     • ${rule.name}: No issues');
            }
          }
        } else {
          print('  Found ${findings.length} issue(s)');
          print('');

          // Count by severity
          int errors =
              findings.where((f) => f.severity == Severity.error).length;
          int warnings =
              findings.where((f) => f.severity == Severity.warning).length;
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
            final ruleName = entry.key.padRight(25);
            final issueCount = entry.value.length;
            final fileCount = entry.value.map((i) => i.filePath).toSet().length;

            final issueText = issueCount == 1 ? 'issue' : 'issues';
            final fileText = fileCount == 1 ? 'file' : 'files';

            print(
              '    • $ruleName $issueCount $issueText ($fileCount $fileText)',
            );
          }
          print('');
          // Top offenders (only for large_build_method)
          final largeBuildFindings = findingsByRule['large_build_method'] ?? [];
          if (largeBuildFindings.isNotEmpty) {
            print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
            print('🚨  TOP OFFENDERS (Large Build Methods)');
            print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

            final sortedLargeBuild = [...largeBuildFindings]..sort((a, b) {
                final aLines = extractLineCount(a.message);
                final bLines = extractLineCount(b.message);
                return bLines.compareTo(aLines);
              });

            final topOffenders = sortedLargeBuild.take(5);
            for (var finding in topOffenders) {
              final fileName = p.basename(finding.filePath);
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

                final fileName = p.basename(finding.filePath);
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

          // AI suggestions

          if (useAI) {
            AIConfig? aiConfig;

            // If API key provided via flag, use it directly
            if (apiKey != null) {
              aiConfig = AIConfig(
                provider: provider,
                model: argResults!['model'] as String? ??
                    getDefaultModel(provider),
                apiKey: apiKey,
              );
            } else {
              // Interactive mode
              aiConfig = await AiPrompt.configure();
            }

            if (aiConfig == null) {
              print('AI configuration cancelled.');
              return 0;
            }

            print('');
            print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
            print('🤖  AI SUGGESTIONS');
            print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
            print('');
            print('  Using ${aiConfig.provider} with ${aiConfig.model}');
            print('');

            try {
              final aiProvider = AIFactory.create(
                aiConfig.provider,
                aiConfig.apiKey,
              );

              final sortedFindings = [...findings]..sort((a, b) {
                  return severityPriority(a.severity)
                      .compareTo(severityPriority(b.severity));
                });

              final topIssues = sortedFindings.take(3).toList();

              for (var i = 0; i < topIssues.length; i++) {
                final finding = topIssues[i];
                final fileName = p.basename(finding.filePath);

                print(
                  '  [${i + 1}/${topIssues.length}] $fileName:${finding.lineNumber}',
                );
                print('  Issue: ${finding.message}');
                print('');

                final codeSnippet = _getCodeSnippet(
                  finding.filePath,
                  finding.lineNumber,
                );

                final suggestion = await aiProvider.getSuggestion(
                  issue: finding.message,
                  code: codeSnippet,
                  filePath: finding.filePath,
                  model: aiConfig.model,
                );

                print('  💡 AI Suggestion:');
                for (var line in suggestion.split('\n')) {
                  print('     $line');
                }
                print('');
                print('  ─────────────────────────────────');
                print('');
              }

              if (findings.length > 3) {
                print('  ℹ️  Showing suggestions for top 3 issues only.');
                print('     Total issues: ${findings.length}');
              }
            } catch (e) {
              stderr.writeln('  ❌ AI Error: $e');
            }
          }
        }

        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('💯  HEALTH SCORE');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('');
        print(
          '       ${healthScore.emoji}  ${healthScore.score}/100 (Grade: ${healthScore.grade})',
        );
        print('');
        print('  ${healthScore.message}');
        print(
          '  Issues per 1K lines: ${healthScore.issuesPerKLOC.toStringAsFixed(1)}',
        );
        print('');
      }

      return 0;
    } catch (e) {
      stderr.writeln('Error: $e');
      return 1;
    }
  }

  String _getCodeSnippet(String filePath, int lineNumber) {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        return '// Could not read file';
      }

      final lines = file.readAsLinesSync();

      const int contextLines = 5;

      final targetIndex = lineNumber - 1;

      final start = (targetIndex - contextLines).clamp(0, lines.length);
      final end = (targetIndex + contextLines + 1).clamp(0, lines.length);

      final snippet = <String>[];
      for (var i = start; i < end; i++) {
        final displayLine = i + 1; // Convert back to 1-indexed for display
        final marker = (displayLine == lineNumber) ? '>>> ' : '    ';
        snippet.add('$marker$displayLine: ${lines[i]}');
      }

      return snippet.join('\n');
    } catch (e) {
      return '// Error reading file: $e';
    }
  }

  void _printJsonOutput({
    required ProjectInfo projectInfo,
    required List<Finding> findings,
    required int totalClasses,
    required int totalWidgets,
    required int statelessCount,
    required int statefulCount,
    required HealthScore healthScore,
  }) {
    final output = {
      'project': {
        'name': projectInfo.name,
        'version': projectInfo.version,
        'path': projectInfo.path,
        'isFlutterProject': projectInfo.isFlutterProject,
      },
      'statistics': {
        'totalFiles': projectInfo.totalFiles,
        'totalLinesOfCode': projectInfo.totalLinesOfCode,
        'totalClasses': totalClasses,
        'totalWidgets': totalWidgets,
        'statelessWidgets': statelessCount,
        'statefulWidgets': statefulCount,
      },
      'summary': {
        'total': findings.length,
        'errors': findings.where((f) => f.severity == Severity.error).length,
        'warnings':
            findings.where((f) => f.severity == Severity.warning).length,
        'info': findings.where((f) => f.severity == Severity.info).length,
      },
      'healthScore': {
        'score': healthScore.score,
        'grade': healthScore.grade,
        'issuesPerKLOC': double.parse(
          healthScore.issuesPerKLOC.toStringAsFixed(2),
        ),
      },
      'findings': findings
          .map(
            (f) => {
              'rule': f.rule,
              'message': f.message,
              'filePath': f.filePath,
              'lineNumber': f.lineNumber,
              'severity': f.severity.toString().split('.').last,
              if (f.suggestion != null) 'suggestion': f.suggestion!,
            },
          )
          .toList(),
    };

    print(jsonEncode(output));
  }
}
