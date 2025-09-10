
class FFLibraryValues {
  static FFLibraryValues _instance = FFLibraryValues._internal();

  factory FFLibraryValues() {
    return _instance;
  }

  FFLibraryValues._internal();

  static void reset() {
    _instance = FFLibraryValues._internal();
  }

  late String modelDownloadUrl = '';
  String? huggingFaceToken = '';
  late String modelFileName = '';
}
