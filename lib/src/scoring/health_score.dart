import 'package:flutter_doctor_ai/src/models/finding.dart';
import 'package:flutter_doctor_ai/src/utils/helpers.dart';

class HealthScorer {
  final int totalFiles;
  final int totalLines;
  final List<Finding> findings;

  HealthScorer({
    required this.totalFiles,
    required this.totalLines,
    required this.findings,
  });

  HealthScore calculate() {
    int errors = 0;
    int warnings = 0;
    int infos = 0;

    // Count by severity
    for (var finding in findings) {
      switch (finding.severity) {
        case Severity.error:
          errors++;
          break;
        case Severity.warning:
          warnings++;
          break;
        case Severity.info:
          infos++;
          break;
      }
    }

    // Calculate weighted issues (errors count more)
    double weightedIssues = (errors * 3) + (warnings * 1) + (infos * 0.25);

    // Issues per 1000 lines of code (KLOC)
    double kloc = totalLines / 1000;
    double issuesPerKLOC = kloc > 0 ? weightedIssues / kloc : weightedIssues;

    // Score: 100 for 0 issues/KLOC, decreases as issues increase
    // 4 issues/KLOC = 90, 8 issues/KLOC = 80, etc.
    double score = 100 - (issuesPerKLOC * 2.5);

    // Clamp score between 0 and 100
    score = score.clamp(0, 100);

    return HealthScore(
      score: score.round(),
      grade: _calculateGrade(score),
      errors: errors,
      warnings: warnings,
      infos: infos,
      totalFindings: findings.length,
      issuesPerKLOC: issuesPerKLOC,
    );
  }

  String _calculateGrade(double score) {
    if (score >= 90) return 'A';
    if (score >= 80) return 'B';
    if (score >= 70) return 'C';
    if (score >= 60) return 'D';
    return 'F';
  }
}

class HealthScore {
  final int score;
  final String grade;
  final int errors;
  final int warnings;
  final int infos;
  final int totalFindings;
  final double issuesPerKLOC;

  const HealthScore({
    required this.score,
    required this.grade,
    required this.errors,
    required this.warnings,
    required this.infos,
    required this.totalFindings,
    required this.issuesPerKLOC,
  });

  String get emoji {
    if (score >= 90) return '🌟';
    if (score >= 80) return '✅';
    if (score >= 70) return '👍';
    if (score >= 60) return '⚠️';
    return '❌';
  }

  String get message {
    if (score >= 90) return 'Excellent! Your code is in great shape.';
    if (score >= 80) return 'Good job! Minor improvements needed.';
    if (score >= 70) return 'Fair. Some issues should be addressed.';
    if (score >= 60) return 'Needs work. Several issues found.';
    return 'Critical! Major issues require attention.';
  }
}
