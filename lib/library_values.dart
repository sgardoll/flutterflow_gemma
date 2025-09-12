
class FFLibraryValues {
  static FFLibraryValues _instance = FFLibraryValues._internal();

  factory FFLibraryValues() {
    return _instance;
  }

  FFLibraryValues._internal();

  static void reset() {
    _instance = FFLibraryValues._internal();
  }

  String modelDownloadUrl =
      'https://huggingface.co/litert-community/gemma-3-270m-it/resolve/main/gemma3-270m-it-q8.task';
  String? huggingFaceToken = '';
}
