
class FFLibraryValues {
  static FFLibraryValues _instance = FFLibraryValues._internal();

  factory FFLibraryValues() {
    return _instance;
  }

  FFLibraryValues._internal();

  static void reset() {
    _instance = FFLibraryValues._internal();
  }

  String? Gemma3n2BDownload = '';
  String? Gemma3n4BDownload = '';
  String? Gemma2BDownload = '';
}
