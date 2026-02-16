import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:flutter_doctor_ai/src/scanner/ast_parser.dart';
import 'package:flutter_doctor_ai/src/scanner/project_scanner.dart';

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
        print('');
        print('📄 Files found:');
        for (var file in projectInfo.files) {
          print('   - ${file.name} (${file.linesOfCode} lines)');
        }
      }

      final astParser = AstParser();
      int totalClasses = 0;
      int totalWidgets = 0;
      int statelessCount = 0;
      int statefulCount = 0;
      int avgLinesPerFile = projectInfo.totalFiles > 0
          ? (projectInfo.totalLinesOfCode / projectInfo.totalFiles).round()
          : 0;

      for (var file in projectInfo.files) {
        final astResult = astParser.parseFile(file);
        totalClasses += astResult.classes.length;
        totalWidgets += astResult.widgets.length;
      }

      for (var file in projectInfo.files) {
        final analysis = astParser.parseFile(file);
        for (var widget in analysis.widgets) {
          if (widget.type == 'StatelessWidget') statelessCount++;
          if (widget.type == 'StatefulWidget') statefulCount++;
        }
      }

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
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

      print(' Name: ${projectInfo.name}');
      print(' Version: v${projectInfo.version}');
      print(' Path: ${projectInfo.path}');
      print(' Flutter: ${projectInfo.isFlutterProject ? '✓ Yes' : 'x No'}\n');

      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📊  CODE STATISTICS');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

      print(' Files: ${projectInfo.totalFiles}');
      print(' Lines of code: ${projectInfo.totalLinesOfCode}');
      print(' Classes: $totalClasses');
      print(' Widgets: $totalWidgets\n');
      print('Widget Types:');
      print(' • StatelessWidget: $statelessCount ($statelessPercent%)');
      print(' • StatefulWidget: $statefulCount ($statefulPercent%)\n');
      
      print('  Avg lines/file: $avgLinesPerFile\n');


      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📂  LARGEST FILES');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

      for (var file in largestFiles) {
        print('   • ${file.name} (${file.linesOfCode} lines)');
      }

      print('');


      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
      
      print('⏱️  Scan completed in ${projectInfo.scanTime.inMilliseconds}ms');

      return 0;
    } catch (e) {
      stderr.writeln('Error: $e');
      return 1;
    }
  }
}
