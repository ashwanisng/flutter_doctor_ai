import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:flutter_doctor_ai/src/analyzer/rules/large_build_rule.dart';
import 'package:test/test.dart';

void main() {
  test('detects large build method', () {
    final code = '''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
${List.generate(60, (i) => "        Text('Item \$i'),").join('\n')}
      ],
    );
  }
}
''';

    final parseResult = parseString(content: code);
    final unit = parseResult.unit;

    final rule = LargeBuildRule();
    final findings = rule.analyze(unit, 'test.dart');

    expect(findings.isNotEmpty, true);
    expect(findings.first.rule, 'large_build_method');
  });

  test('does not report for small build method', () {
    final code = '''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Text('Hello');
  }
}
''';

    final parseResult = parseString(content: code);
    final unit = parseResult.unit;

    final rule = LargeBuildRule();
    final findings = rule.analyze(unit, 'test.dart');

    expect(findings.isEmpty, true);
  });
}
