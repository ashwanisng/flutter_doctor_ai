import 'package:flutter_doctor_ai/src/models/finding.dart';
import 'package:flutter_doctor_ai/src/utils/helpers.dart';

/// Calculates and holds the health score for a project.
///
/// The score is calculated based on the number and severity
/// of issues found, normalized by project size.
class HealthScorer {

  /// Total lines of code in the project
  final int totalLines;

  /// List of all findings from analysis
  final List<Finding> findings;

  const HealthScorer({
    required this.totalLines,
    required this.findings,
  });

  /// Calculate the health score based on findings and project size.
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

/// Represents the calculated health score for a project.
///
/// Includes the numeric score (0-100), letter grade,
/// and breakdown of issues by severity.
class HealthScore {
  /// Numeric score from 0 to 100
  final int score;

  /// Letter grade (A, B, C, D, F)
  final String grade;

  /// Number of error-level findings
  final int errors;

  /// Number of warning-level findings
  final int warnings;

  /// Number of info-level findings
  final int infos;

  /// Total number of findings
  final int totalFindings;

  /// Issues per 1000 lines of code (KLOC)
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

  /// Emoji representing the health score
  String get emoji {
    if (score >= 90) return '🌟';
    if (score >= 80) return '✅';
    if (score >= 70) return '👍';
    if (score >= 60) return '⚠️';
    return '❌';
  }

  /// Human-readable message about the score
  String get message {
    if (score >= 90) return 'Excellent! Your code is in great shape.';
    if (score >= 80) return 'Good job! Minor improvements possible.';
    if (score >= 70) return 'Fair. Consider addressing some issues.';
    if (score >= 60) return 'Needs attention. Several issues found.';
    return 'Critical! Major issues require attention.';
  }
}
