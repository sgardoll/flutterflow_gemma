
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
      'https://gemma.connectio.com.au/models/gemma-2b-it-gpu-int4.bin';
  String? huggingFaceToken = '';
}
