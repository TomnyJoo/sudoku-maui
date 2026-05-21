import 'package:flutter/material.dart';

/// 应用文本样式集合
class AppTextStyles {
  // ==================== 字体大小常量 ====================
  /// 超大字体 - 用于主标题
  static const double fontSizeDisplay = 42;
  /// 大字体 - 用于页面大标题
  static const double fontSizeTitle = 28;
  /// 中大字体 - 用于卡片标题
  static const double fontSizeCardTitle = 24;
  /// 中等字体 - 用于次级标题
  static const double fontSizeSubtitle = 20;
  /// 中大字体 - 用于按钮文字
  static const double fontSizeButton = 18;
  /// 正文标准字体
  static const double fontSizeBody = 16;
  /// 小字体 - 用于标签
  static const double fontSizeLabel = 14;
  /// 超小字体 - 用于辅助文字
  static const double fontSizeCaption = 12;
  /// 极小字体 - 用于候选数字
  static const double fontSizeTiny = 10;

  // ==================== 单元格字体大小 ====================
  /// 数独单元格数字字体大小
  static const double fontSizeCellNumber = 22;
  /// 数独单元格候选数字字体大小
  static const double fontSizeCellCandidate = 12;
  /// 杀手数独笼子和值字体大小
  static const double fontSizeCageSum = 14;

  // ==================== 预定义文本样式 ====================
  /// 页面大标题样式
  static const title = TextStyle(fontSize: fontSizeTitle, fontWeight: FontWeight.bold);
  /// 次级标题样式
  static const subtitle = TextStyle(fontSize: fontSizeSubtitle, fontWeight: FontWeight.w600);
  /// 正文内容样式
  static const body = TextStyle(fontSize: fontSizeBody);
  /// 按钮文字样式
  static const button = TextStyle(fontSize: fontSizeButton, fontWeight: FontWeight.w600);
  /// 固定数字单元格文字样式
  static const cellFixed = TextStyle(fontSize: fontSizeCellNumber, fontWeight: FontWeight.bold);
  /// 用户输入数字样式
  static const cellUser = TextStyle(fontSize: fontSizeCellNumber, fontWeight: FontWeight.w500);
  /// 候选数字样式
  static const candidate = TextStyle(fontSize: fontSizeCellCandidate, fontWeight: FontWeight.w400);
  /// 杀手数独笼子和值样式
  static const cageSum = TextStyle(fontSize: fontSizeCageSum, fontWeight: FontWeight.bold);
  /// 标签文字样式
  static const label = TextStyle(fontSize: fontSizeLabel, fontWeight: FontWeight.w500);
  /// 辅助文字样式
  static const caption = TextStyle(fontSize: fontSizeCaption, fontWeight: FontWeight.w400);
  /// 卡片标题样式
  static const cardTitle = TextStyle(fontSize: fontSizeCardTitle, fontWeight: FontWeight.bold);
  /// 显示文字样式（超大）
  static const display = TextStyle(fontSize: fontSizeDisplay, fontWeight: FontWeight.bold);
}
