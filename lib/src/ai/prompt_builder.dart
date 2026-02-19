class PromptBuilder {
  /// Prompt for getting fix suggestions
  static String fixSuggestion({
    required String issue,
    required String code,
    required String filePath,
  }) {
    return '''
You are a Flutter/Dart expert. Analyze this code issue and provide a fix.

**File:** $filePath

**Issue:** $issue

**Code:**
```dart
$code
```

**Provide:**
1. Brief explanation of the problem
2. How to fix it
3. Corrected code snippet

Keep your response concise and actionable.
''';
  }

  /// Prompt for explaining an issue
  static String explainIssue({required String issue, required String rule}) {
    return '''
You are a Flutter/Dart expert. Explain this code issue in simple terms.

**Rule:** $rule
**Issue:** $issue

**Provide:**
1. What this issue means
2. Why it's a problem
3. How to prevent it in the future

Keep your response beginner-friendly.
''';
  }

  /// Prompt for code review
  static String codeReview({required String code, required String filePath}) {
    return '''
You are a Flutter/Dart expert. Review this code and suggest improvements.

**File:** $filePath

**Code:**
```dart
$code
```

**Provide:**
1. Code quality assessment
2. Potential issues
3. Improvement suggestions

Be concise and actionable.
''';
  }

  /// Prompt for refactoring large build methods
  static String refactorBuildMethod({
    required String code,
    required String filePath,
    required int lineCount,
  }) {
    return '''
You are a Flutter/Dart expert. This build method is $lineCount lines long and needs refactoring.

**File:** $filePath

**Code:**
```dart
$code
```

**Provide:**
1. How to break this into smaller widgets
2. Suggested widget extraction
3. Refactored code example

Keep widgets focused and reusable.
''';
  }
}
