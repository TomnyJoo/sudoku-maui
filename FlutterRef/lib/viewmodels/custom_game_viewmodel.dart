import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sudoku/models/board.dart';
import 'package:sudoku/models/cell.dart';

/// 自定义游戏 ViewModel
///
/// 管理自定义游戏的创建、验证和启动
class CustomGameViewModel extends ChangeNotifier {
  CustomGameViewModel();

  /// 当前棋盘
  Board? _board;
  Board? get board => _board;

  /// 是否正在验证
  bool _isValidating = false;
  bool get isValidating => _isValidating;

  /// 验证结果消息
  String? _validationMessage;
  String? get validationMessage => _validationMessage;

  /// 验证是否通过
  bool _isValid = false;
  bool get isValid => _isValid;

  /// 初始化空棋盘
  void initBoard(Board Function() createEmpty) {
    _board = createEmpty();
    _validationMessage = null;
    _isValid = false;
    notifyListeners();
  }

  /// 设置单元格值
  void setCellValue(int row, int col, int? value) {
    if (_board == null) return;
    _board!.getCell(row, col); // 验证坐标合法
    final newCell = Cell(
      row: row,
      col: col,
      value: value,
      isFixed: value != null,
    );
    _board = _board!.setCell(row, col, newCell);
    notifyListeners();
  }

  /// 清除棋盘
  void clearBoard() {
    if (_board == null) return;
    _board = _board!.reset();
    _validationMessage = null;
    _isValid = false;
    notifyListeners();
  }

  /// 验证棋盘
  Future<bool> validateBoard(bool Function(Board) validator) async {
    if (_board == null) return false;
    _isValidating = true;
    _validationMessage = null;
    notifyListeners();

    try {
      _isValid = validator(_board!);
      _validationMessage = _isValid ? '验证通过' : '棋盘不满足规则';
    } catch (e) {
      _isValid = false;
      _validationMessage = '验证出错: $e';
    } finally {
      _isValidating = false;
      notifyListeners();
    }
    return _isValid;
  }

  /// 保存自定义游戏
  Future<void> saveGame(String gameType) async {
    if (_board == null) return;
    final prefs = await SharedPreferences.getInstance();
    final boardJson = jsonEncode(_board!.toJson());
    await prefs.setString('${gameType}_custom_board', boardJson);
  }
}
