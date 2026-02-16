import 'dart:io';

import 'package:args/command_runner.dart';
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

      if (verbose) {
        print('📄 Files found:');
        for (var file in projectInfo.files) {
          print('   - ${file.name} (${file.linesOfCode} lines)');
        }
        print('');
      }

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

      return 0;
    } catch (e) {
      stderr.writeln('Error: $e');
      return 1;
    }
  }
}
