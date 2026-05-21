/// 数独单元格具体类（表示数独棋盘中的单个单元格，包含位置、值、状态等信息）
class Cell {  /// 单元格颜色索引（用于标记不同区域或状态）

  /// 构造单元格模型
  const Cell({
    required this.row,
    required this.col,
    this.value,
    this.isFixed = false,
    this.isError = false,
    final Set<int>? candidates,
    this.isSelected = false,
    this.isHighlighted = false,
    this.colorIndex,
  }) : candidates = candidates ?? const <int>{};

  /// 从JSON创建单元格实例
  factory Cell.fromJson(final Map<String, dynamic> json) => Cell(
      row: json['row'] as int,
      col: json['col'] as int,
      value: json['value'] as int?,
      isFixed: json['isFixed'] as bool? ?? false,
      isError: json['isError'] as bool? ?? false,
      candidates: json['candidates'] != null 
          ? Set<int>.from((json['candidates'] as List).cast<int>()) 
          : null,
      isSelected: json['isSelected'] as bool? ?? false,
      isHighlighted: json['isHighlighted'] as bool? ?? false,
      colorIndex: json['colorIndex'] as int?,
    );

  final int row;  /// 行索引（0-based）
  final int col;  /// 列索引（0-based） 
  final int? value;  /// 当前填入的数字（null表示未填）
  final bool isFixed;  /// 是否固定数字（游戏开始时存在的不可修改数字）
  final bool isError;  /// 是否数字冲突（违反数独规则） 
  final Set<int> candidates;  /// 候选数字集合（用于提示模式）
  final bool isSelected;  /// 是否被选中
  final bool isHighlighted;  /// 是否高亮显示（同行/同列/同区域高亮）
  final int? colorIndex;

  /// 生成新单元格副本，允许覆盖指定属性，返回新的单元格实例
  Cell copyWith({
    int? value,
    bool clearValue = false,
    bool? isFixed,
    bool? isError,
    Set<int>? candidates,
    bool? isSelected,
    bool? isHighlighted,
    int? colorIndex,
  }) => createInstance(
      row: row,
      col: col,
      value: clearValue ? null : (value ?? this.value),
      isFixed: isFixed ?? this.isFixed,
      isError: isError ?? this.isError,
      candidates: candidates ?? this.candidates,
      isSelected: isSelected ?? this.isSelected,
      isHighlighted: isHighlighted ?? this.isHighlighted,
      colorIndex: colorIndex ?? this.colorIndex,
    );

  /// 创建单元格实例
  Cell createInstance({
    required int row,
    required int col,
    int? value,
    bool isFixed = false,
    bool isError = false,
    Set<int>? candidates,
    bool isSelected = false,
    bool isHighlighted = false,
    int? colorIndex,
  }) => Cell(
      row: row,
      col: col,
      value: value,
      isFixed: isFixed,
      isError: isError,
      candidates: candidates,
      isSelected: isSelected,
      isHighlighted: isHighlighted,
      colorIndex: colorIndex,
    );

  /// 转换为JSON格式，用于持久化存储，返回：包含单元格数据的Map
  Map<String, dynamic> toJson() => {
      'row': row,
      'col': col,
      'value': value,
      'isFixed': isFixed,
      'isError': isError,
      'candidates': candidates.toList(),
      'isSelected': isSelected,
      'isHighlighted': isHighlighted,
      'colorIndex': colorIndex,
    };

  /// 检查单元格是否为空（未填数字）
  bool get isEmpty => value == null;

  /// 检查单元格是否可编辑（非固定单元格）
  bool get isEditable => !isFixed;

  /// 重置单元格状态（清除错误、选中、高亮状态）
  Cell resetState() => copyWith(
      isError: false,
      isSelected: false,
      isHighlighted: false,
    );

  /// 清除单元格内容（保留固定状态）
  Cell clear() {
    if (isFixed) return this;
    return copyWith(
      clearValue: true,
      candidates: <int>{},
      isError: false,
    );
  }

  /// 添加候选数字
  Cell addCandidate(final int number) {
    if (number < 1) {
      final errorMsg = '候选数字必须为正数: $number';
      throw ArgumentError(errorMsg);
    }
    final newCandidates = Set<int>.from(candidates)..add(number);
    return copyWith(candidates: newCandidates);
  }

  /// 移除候选数字
  Cell removeCandidate(final int number) {
    final newCandidates = Set<int>.from(candidates)..remove(number);
    return copyWith(candidates: newCandidates);
  }

  /// 切换候选数字
  Cell toggleCandidate(final int number) {
    if (number < 1) {
      final errorMsg = '候选数字必须为正数: $number';
      throw ArgumentError(errorMsg);
    }
    final newCandidates = Set<int>.from(candidates);
    if (newCandidates.contains(number)) {
      newCandidates.remove(number);
    } else {
      newCandidates.add(number);
    }
    return copyWith(candidates: newCandidates);
  }

  /// 清除所有候选数字
  Cell clearCandidates() => copyWith(candidates: <int>{});

  /// 设置单元格值，并清除候选数字
  Cell setValue(final int? newValue) {
    if (newValue != null && newValue < 1) {
      final errorMsg = '数字值必须为正数: $newValue';
      throw ArgumentError(errorMsg);
    }
    return createInstance(
      row: row,
      col: col,
      value: newValue,
      isFixed: isFixed,
      candidates: <int>{},
      isSelected: isSelected,
      isHighlighted: isHighlighted,
      colorIndex: colorIndex,
    );
  }

  /// 检查单元格是否包含指定候选数字
  bool hasCandidate(final int number) => candidates.contains(number);

  /// 获取显示值（用于UI显示）
  String get displayValue => value?.toString() ?? '';

  /// 获取候选数字的字符串表示（用于UI显示）
  String getCandidatesDisplay({final String separator = ', '}) {
    if (candidates.isEmpty) return '';
    final sortedCandidates = candidates.toList()..sort();
    return sortedCandidates.join(separator);
  }

  /// 检查单元格是否等于另一个对象
  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) return true;
    return other is Cell &&
        other.row == row &&
        other.col == col &&
        other.value == value &&
        other.isFixed == isFixed &&
        other.isError == isError &&
        other.isSelected == isSelected &&
        other.isHighlighted == isHighlighted &&
        other.colorIndex == colorIndex;
  }

  /// 获取哈希码，用于在集合中快速查找
  @override
  int get hashCode => Object.hash(
      row,
      col,
      value,
      isFixed,
      isError,
      isSelected,
      isHighlighted,
      colorIndex,
    );

  /// 获取用于调试的字符串表示（不依赖国际化），返回调试用的字符串表示
  String toDebugString() =>
     'Cell(row: $row, col: $col, value: $value, isFixed: $isFixed, '
        'isError: $isError, isSelected: $isSelected, isHighlighted: $isHighlighted, colorIndex: $colorIndex)';

  @override
  String toString() => toDebugString();
}
