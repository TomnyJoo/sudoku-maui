/// 二维列表扩展
extension MatrixExtension<T> on List<List<T>> {
  // 使用泛型 R 增加类型灵活性，允许转换为不同类型的二维列表
  List<List<R>> mapIndexed<R>(final List<R> Function(int rowIndex, List<T> row) f) => asMap().entries.map((final entry) => f(entry.key, entry.value)).toList();
}

/// 一维列表扩展
extension ListExtension<T> on List<T> {
  // 使用泛型 R 支持类型转换
  List<R> mapIndexed<R>(final R Function(int index, T element) f) => asMap().entries.map((final entry) => f(entry.key, entry.value)).toList();
}
