import 'package:collection/collection.dart';

enum PreferredBackend {
  cpu,
  gpuFloat16,
  gpuMixed,
  gpuFull,
  tpu,
  unknown,
  gpu,
  npu,
}

enum ModelType {
  general,
  functionGemma,
  qwen,
  deepSeek,
  gemmaIt,
}

extension FFEnumExtensions<T extends Enum> on T {
  String serialize() => name;
}

extension FFEnumListExtensions<T extends Enum> on Iterable<T> {
  T? deserialize(String? value) =>
      firstWhereOrNull((e) => e.serialize() == value);
}

T? deserializeEnum<T>(String? value) {
  switch (T) {
    case (PreferredBackend):
      return PreferredBackend.values.deserialize(value) as T?;
    case (ModelType):
      return ModelType.values.deserialize(value) as T?;
    default:
      return null;
  }
}
