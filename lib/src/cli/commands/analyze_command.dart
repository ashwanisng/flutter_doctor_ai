import 'dart:io';

import 'package:args/command_runner.dart';
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
    String projectPath = argResults!.rest.isEmpty ? '.' : argResults!.rest.first;
    bool verbose = argResults!['verbose'] as bool;

    print('🔍 Analyzing Flutter project...\n');

    try {
      final projectInfo = await ProjectScanner().scan(projectPath);

      print('📦  Project: ${projectInfo.name} v${projectInfo.version}');
      print('📍  Path: ${projectInfo.path}');
      print('📁  Files: ${projectInfo.totalFiles}');
      print('📝  Lines of code: ${projectInfo.totalLinesOfCode}');
      print('🎯  Flutter project: ${projectInfo.isFlutterProject}');
      print('⏱️  Scan time: ${projectInfo.scanTime.inMilliseconds}ms');

      if (verbose) {
        print('');
        print('📄 Files found:');
        for (var file in projectInfo.files) {
          print('   - ${file.name} (${file.linesOfCode} lines)');
        }
      }

      return 0;
    } catch (e) {
      stderr.writeln('Error: $e');
      return 1;
    }
  }
}