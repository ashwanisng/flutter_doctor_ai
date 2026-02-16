import 'dart:io';

import 'package:flutter_doctor_ai/src/models/project_info.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

class ProjectScanner {
  Future<ProjectInfo> scan(String projectPath) async {
    final stopwatch = Stopwatch()..start();

    final dir = Directory(projectPath);
    if (!dir.existsSync()) {
      throw Exception("Directory '$projectPath' does not exist.");
    }

    final pubspecFile = File(p.join(projectPath, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) {
      throw Exception('Not a Dart project: pubspec.yaml not found');
    }

    final pubspecContent = pubspecFile.readAsStringSync();
    final pubspec = loadYaml(pubspecContent);

    String name = pubspec['name'] ?? 'unknown';
    String version = pubspec['version'] ?? '0.0.0';
    bool isFlutter = pubspec['dependencies']?['flutter'] != null;

    List<DartFile> files = [];
    final libDir = Directory('${dir.path}/lib');

    if (libDir.existsSync()) {
      final entities = libDir.listSync(recursive: true);

      for (var entity in entities) {
        if (entity.path.contains('.dart_tool')) continue;
        if (entity.path.contains('/build/')) continue;
        if (entity.path.contains('.git')) continue;

        if (entity is File && p.extension(entity.path) == '.dart') {
          final content = entity.readAsStringSync();
          final linesOfCode = content.split('\n').length;
          files.add(
            DartFile(
              path: entity.path,
              name: p.basename(entity.path),
              content: content,
              linesOfCode: linesOfCode,
            ),
          );
        }
      }
    }

    stopwatch.stop();

    return ProjectInfo(
      name: name,
      path: dir.absolute.path,
      version: version,
      files: files,
      isFlutterProject: isFlutter,
      scanTime: stopwatch.elapsed,
    );
  }
}
