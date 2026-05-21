import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sudoku/constants/app_constants.dart';

class GameLayout {
  GameLayout({
    required this.boardCellSize,
    required this.keypadCellSize,
    required this.isHorizontalLayout,
    required this.boardSize,
    required this.keypadWidth,
    required this.keypadHeight,
    required this.totalWidth,
    required this.totalHeight,
    required this.utilizationRatio,
  });

  final double boardCellSize;
  final double keypadCellSize;
  final bool isHorizontalLayout;
  final double boardSize;
  final double keypadWidth;
  final double keypadHeight;
  final double totalWidth;
  final double totalHeight;
  final double utilizationRatio;

  @override
  String toString() => 'GameLayout{布局: ${isHorizontalLayout ? '左右' : '上下'}, '
        '棋盘单元格: ${boardCellSize.toStringAsFixed(1)}, '
        '棋盘尺寸: ${boardSize.toStringAsFixed(1)}, '
        '键盘区: ${keypadWidth.toStringAsFixed(1)}×${keypadHeight.toStringAsFixed(1)}, '
        '利用率: ${(utilizationRatio * 100).toStringAsFixed(1)}%}';
}

class LayoutCalculator {
  /// 布局间距（引用 AppConstants）
  static const double spacing = AppConstants.spacingMedium;

  /// 最小棋盘单元格尺寸（与 AppConstants 统一）
  static const double minBoardCellSize = AppConstants.minCellSize;

  /// 最小键盘单元格尺寸
  static const double minKeypadCellSize = AppConstants.minKeypadCellSize;

  /// 键盘容器内边距
  static const double keypadContainerPadding = AppConstants.keyboardPadding;

  /// 键盘网格间距
  static const double keypadGridSpacing = AppConstants.keyboardButtonSpacing;

  /// 键盘底部外边距
  static const double keypadBottomMargin = AppConstants.keypadBottomMargin;

  static GameLayout calculateOptimalLayout(
    final Size gameAreaSize, {
    int boardSize = 9,
  }) {
    final gameAreaWidth = gameAreaSize.width;
    final gameAreaHeight = gameAreaSize.height;

    final isHorizontalLayout = gameAreaWidth >= gameAreaHeight;

    GameLayout layout;
    if (isHorizontalLayout) {
      layout = _calculateHorizontalLayout(gameAreaWidth, gameAreaHeight, boardSize);
    } else {
      layout = _calculateVerticalLayout(gameAreaWidth, gameAreaHeight, boardSize);
    }

    return layout;
  }

  static GameLayout _calculateVerticalLayout(final double width, final double height, final int boardSize) {
    var boardPixelSize = (height - spacing - keypadBottomMargin) / 1.5;
    
    if (boardPixelSize > width) {
      boardPixelSize = width;
    }
    
    if (boardPixelSize / boardSize < minBoardCellSize) {
      boardPixelSize = minBoardCellSize * boardSize;
    }

    final keypadWidth = boardPixelSize;
    final keypadHeight = boardPixelSize * 0.5;

    final boardCellSize = boardPixelSize / boardSize;

    final eachKeypadWidth = keypadWidth / 2;
    final eachKeypadHeight = keypadHeight;
    
    final keypadCellSizeByWidth = (eachKeypadWidth - keypadContainerPadding * 2 - keypadGridSpacing * 2) / 3;
    final keypadCellSizeByHeight = (eachKeypadHeight - keypadContainerPadding * 2 - keypadGridSpacing * 2) / 3;
    
    double keypadCellSize = min(keypadCellSizeByWidth, keypadCellSizeByHeight);
    
    if (keypadCellSize < minKeypadCellSize) {
      keypadCellSize = minKeypadCellSize;
    }

    final totalHeight = boardPixelSize + spacing + keypadHeight + keypadBottomMargin;
    final totalWidth = boardPixelSize;
    final utilizationRatio = (boardPixelSize * boardPixelSize + keypadWidth * keypadHeight) / (width * height);

    return GameLayout(
      boardCellSize: boardCellSize,
      keypadCellSize: keypadCellSize,
      isHorizontalLayout: false,
      boardSize: boardPixelSize,
      keypadWidth: keypadWidth,
      keypadHeight: keypadHeight,
      totalWidth: totalWidth,
      totalHeight: totalHeight,
      utilizationRatio: utilizationRatio,
    );
  }

  static GameLayout _calculateHorizontalLayout(final double width, final double height, final int boardSize) {
    var boardPixelSize = (width - spacing) / 1.5;
    
    if (boardPixelSize > height) {
      boardPixelSize = height;
    }
    
    if (boardPixelSize / boardSize < minBoardCellSize) {
      boardPixelSize = minBoardCellSize * boardSize;
    }

    final keypadHeight = boardPixelSize;
    final keypadWidth = boardPixelSize * 0.5;

    final boardCellSize = boardPixelSize / boardSize;

    final eachKeypadWidth = keypadWidth;
    final eachKeypadHeight = keypadHeight / 2;
    
    final keypadCellSizeByWidth = (eachKeypadWidth - keypadContainerPadding * 2 - keypadGridSpacing * 2) / 3;
    final keypadCellSizeByHeight = (eachKeypadHeight - keypadContainerPadding * 2 - keypadGridSpacing * 2) / 3;
    
    double keypadCellSize = min(keypadCellSizeByWidth, keypadCellSizeByHeight);
    
    if (keypadCellSize < minKeypadCellSize) {
      keypadCellSize = minKeypadCellSize;
    }

    final totalWidth = boardPixelSize + spacing + keypadWidth;
    final totalHeight = boardPixelSize;
    final utilizationRatio = (boardPixelSize * boardPixelSize + keypadWidth * keypadHeight) / (width * height);

    return GameLayout(
      boardCellSize: boardCellSize,
      keypadCellSize: keypadCellSize,
      isHorizontalLayout: true,
      boardSize: boardPixelSize,
      keypadWidth: keypadWidth,
      keypadHeight: keypadHeight,
      totalWidth: totalWidth,
      totalHeight: totalHeight,
      utilizationRatio: utilizationRatio,
    );
  }

  static GameLayout calculateStandardLayout(final Size availableSize) =>
    calculateOptimalLayout(availableSize);
}
