import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:csv/csv.dart';
import 'package:synchronized/synchronized.dart';
import 'flutter_flow/flutter_flow_util.dart';

class FFAppState extends ChangeNotifier {
  static FFAppState _instance = FFAppState._internal();

  factory FFAppState() {
    return _instance;
  }

  FFAppState._internal();

  static void reset() {
    _instance = FFAppState._internal();
  }

  Future initializePersistedState() async {
    secureStorage = FlutterSecureStorage();
    await _safeInitAsync(() async {
      _hfToken = await secureStorage.getString('ff_hfToken') ?? _hfToken;
    });
  }

  void update(VoidCallback callback) {
    callback();
    notifyListeners();
  }

  late FlutterSecureStorage secureStorage;

  String _hfToken = '';
  String get hfToken => _hfToken;
  set hfToken(String value) {
    _hfToken = value;
    secureStorage.setString('ff_hfToken', value);
    notifyListeners();
  }

  void deleteHfToken() {
    secureStorage.delete(key: 'ff_hfToken');
  }

  String _downloadProgress = '';
  String get downloadProgress => _downloadProgress;
  set downloadProgress(String value) {
    _downloadProgress = value;
    notifyListeners();
  }

  double _downloadPercentage = 100.0;
  double get downloadPercentage => _downloadPercentage;
  set downloadPercentage(double value) {
    _downloadPercentage = value;
    notifyListeners();
  }

  String _fileName = '';
  String get fileName => _fileName;
  set fileName(String value) {
    _fileName = value;
    notifyListeners();
  }

  bool _isDownloading = false;
  bool get isDownloading => _isDownloading;
  set isDownloading(bool value) {
    _isDownloading = value;
    notifyListeners();
  }

  bool _isInitializing = false;
  bool get isInitializing => _isInitializing;
  set isInitializing(bool value) {
    _isInitializing = value;
    notifyListeners();
  }

  bool _modelSupportsVision = false;
  bool get modelSupportsVision => _modelSupportsVision;
  set modelSupportsVision(bool value) {
    _modelSupportsVision = value;
    notifyListeners();
  }

  bool _isModelInitialized = false;
  bool get isModelInitialized => _isModelInitialized;
  set isModelInitialized(bool value) {
    _isModelInitialized = value;
    notifyListeners();
  }
}

void _safeInit(Function() initializeField) {
  try {
    initializeField();
  } catch (_) {}
}

Future _safeInitAsync(Function() initializeField) async {
  try {
    await initializeField();
  } catch (_) {}
}

extension FlutterSecureStorageExtensions on FlutterSecureStorage {
  static final _lock = Lock();

  Future<void> writeSync({required String key, String? value}) async =>
      await _lock.synchronized(() async {
        await write(key: key, value: value);
      });

  void remove(String key) => delete(key: key);

  Future<String?> getString(String key) async => await read(key: key);
  Future<void> setString(String key, String value) async =>
      await writeSync(key: key, value: value);

  Future<bool?> getBool(String key) async => (await read(key: key)) == 'true';
  Future<void> setBool(String key, bool value) async =>
      await writeSync(key: key, value: value.toString());

  Future<int?> getInt(String key) async =>
      int.tryParse(await read(key: key) ?? '');
  Future<void> setInt(String key, int value) async =>
      await writeSync(key: key, value: value.toString());

  Future<double?> getDouble(String key) async =>
      double.tryParse(await read(key: key) ?? '');
  Future<void> setDouble(String key, double value) async =>
      await writeSync(key: key, value: value.toString());

  Future<List<String>?> getStringList(String key) async =>
      await read(key: key).then((result) {
        if (result == null || result.isEmpty) {
          return null;
        }
        return CsvToListConverter()
            .convert(result)
            .first
            .map((e) => e.toString())
            .toList();
      });
  Future<void> setStringList(String key, List<String> value) async =>
      await writeSync(key: key, value: ListToCsvConverter().convert([value]));
}
