import 'dart:io';
import 'package:flutter_doctor_ai/src/cli/runner.dart';

void main(List<String> arguments) async {
  try {
    final exitCode = await FlutterDoctorRunner().run(arguments);
    exit(exitCode ?? 0);
  } catch (e) {
    stderr.writeln('Error: $e');
    exit(1);
  }
}
