import 'package:args/command_runner.dart';
import 'package:flutter_doctor_ai/src/cli/commands/analyze_command.dart';

class FlutterDoctorRunner extends CommandRunner<int> {
  FlutterDoctorRunner()
    : super('flutter_doctor', '🩺 AI-powered Flutter code analysis tool') {
    addCommand(AnalyzeCommand());
  }
}
