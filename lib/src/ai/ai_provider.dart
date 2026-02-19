abstract class AIProvider {
  String get name;
  List<String> get availableModels;
  String get defaultModel;


  Future<String> getSuggestion({
    required String issue,
    required String code,
    required String filePath,
    String? model,
  });
}
