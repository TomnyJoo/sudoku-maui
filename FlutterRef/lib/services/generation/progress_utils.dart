import 'package:flutter/material.dart';
import 'package:sudoku/l10n/localization_utils.dart';
import 'package:sudoku/models/difficulty.dart';
import 'package:sudoku/models/generation_contracts.dart';

/// 游戏工具类
class GameUtils {
  /// 获取生成阶段的进度文本，返回对应阶段的进度文本
  static String? getProgressText(BuildContext context, dynamic generationStage) {
    if (generationStage is GenerationStage) {
      final loc = LocalizationUtils.app(context);
      return loc.getProgressText(generationStage.name);
    }
    return null;
  }

  /// 从标识符获取难度，返回对应的难度枚举
  static Difficulty? getDifficultyFromIdentifier(String identifier) =>
      DifficultyExtension.fromIdentifier(identifier);

  /// 格式化时间（秒）为分:秒格式
  static String formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// 获取本地化的难度名称
  static String getLocalizedDifficultyName(
    BuildContext context,
    dynamic difficulty,
  ) {
    Difficulty? difficultyEnum;

    if (difficulty is Difficulty) {
      difficultyEnum = difficulty;
    } else if (difficulty is String) {
      difficultyEnum = getDifficultyFromIdentifier(difficulty);
    }

    if (difficultyEnum == null) {
      return difficulty.toString();
    }

    final loc = LocalizationUtils.app(context);
    return difficultyEnum.config.getLocalizedDifficultyName(loc);
  }
  
  /// 计算游戏完成百分比
  static int calculateCompletionPercentage(int filledCells, int totalCells) {
    if (totalCells == 0) return 0;
    return (filledCells / totalCells * 100).round();
  }
  
  /// 生成游戏难度描述，返回难度描述文本
  static String getDifficultyDescription(BuildContext context, Difficulty difficulty) {
    final loc = LocalizationUtils.app(context);
    return difficulty.config.getLocalizedDifficultyName(loc);
  }
}
