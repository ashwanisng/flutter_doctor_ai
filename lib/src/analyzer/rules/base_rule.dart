import 'package:analyzer/dart/ast/ast.dart';
import 'package:flutter_doctor_ai/src/models/finding.dart';
import 'package:flutter_doctor_ai/src/utils/helpers.dart';

abstract class BaseRule {
  String get name;

  String get description;

  Severity get severity;

  List<Finding> analyze(CompilationUnit unit, String filePath);
}
