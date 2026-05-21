import 'package:flutter/material.dart';

/// 屏幕类型枚举
enum DeviceType {
  /// 手机设备
  mobile,
  /// 平板设备
  tablet,
  /// 桌面设备
  desktop,
  /// 大屏桌面设备
  largeDesktop,
}

/// 屏幕类型工具类
///
/// 提供屏幕类型检测和响应式计算方法
class ScreenType {
  /// 屏幕类型断点定义
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;
  static const double largeDesktopBreakpoint = 1600;

  /// 判断是否为手机
  static bool isMobile(final BuildContext context) =>
      MediaQuery.of(context).size.shortestSide < mobileBreakpoint;

  /// 判断是否为平板
  static bool isTablet(final BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.shortestSide >= mobileBreakpoint &&
        size.shortestSide < tabletBreakpoint;
  }

  /// 判断是否为桌面设备
  static bool isDesktop(final BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.shortestSide >= desktopBreakpoint &&
        size.shortestSide < largeDesktopBreakpoint;
  }

  /// 判断是否为大屏桌面设备
  static bool isLargeDesktop(final BuildContext context) =>
      MediaQuery.of(context).size.shortestSide >= largeDesktopBreakpoint;

  /// 判断是否为大屏幕（平板及以上）
  static bool isLargeScreen(final BuildContext context) =>
      MediaQuery.of(context).size.shortestSide >= tabletBreakpoint;

  /// 判断是否为竖屏
  static bool isPortrait(final BuildContext context) {
    final size = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;

    if (size.shortestSide < mobileBreakpoint) {
      return orientation == Orientation.portrait;
    }

    return size.height > size.width;
  }

  /// 判断是否为横屏
  static bool isLandscape(final BuildContext context) => !isPortrait(context);

  /// 获取设备类型
  static DeviceType getDeviceType(final BuildContext context) {
    if (isLargeDesktop(context)) return DeviceType.largeDesktop;
    if (isDesktop(context)) return DeviceType.desktop;
    if (isTablet(context)) return DeviceType.tablet;
    return DeviceType.mobile;
  }

  /// 获取屏幕类型字符串
  static String getScreenType(final BuildContext context) {
    if (isLargeDesktop(context)) return 'large_desktop';
    if (isDesktop(context)) return 'desktop';
    if (isTablet(context)) return 'tablet';
    return 'mobile';
  }

  /// 获取响应式缩放因子
  static double getScaleFactor(final BuildContext context) {
    if (isLargeDesktop(context)) return 1.4;
    if (isDesktop(context)) return 1.2;
    if (isTablet(context)) return 1.1;
    return 1.0;
  }

  /// 获取响应式字体大小
  static double getResponsiveFontSize(
      final BuildContext context, final double baseSize) => baseSize * getScaleFactor(context);

  /// 获取响应式间距
  static double getResponsiveSpacing(
      final BuildContext context, final double baseSpacing) => baseSpacing * getScaleFactor(context);

  /// 获取响应式宽度
  static double getResponsiveWidth(
      final BuildContext context, final double baseWidth) => baseWidth * getScaleFactor(context);

  /// 获取响应式高度
  static double getResponsiveHeight(
      final BuildContext context, final double baseHeight) => baseHeight * getScaleFactor(context);

  /// 获取响应式圆角
  static double getResponsiveBorderRadius(
      final BuildContext context, final double baseRadius) => baseRadius * getScaleFactor(context);

  /// 获取响应式图标大小
  static double getResponsiveIconSize(
      final BuildContext context, final double baseSize) => baseSize * getScaleFactor(context);

  /// 获取屏幕宽度
  static double getScreenWidth(final BuildContext context) =>
      MediaQuery.of(context).size.width;

  /// 获取屏幕高度
  static double getScreenHeight(final BuildContext context) =>
      MediaQuery.of(context).size.height;

  /// 获取屏幕安全区域
  static EdgeInsets getSafeArea(final BuildContext context) =>
      MediaQuery.of(context).padding;

  /// 获取屏幕可用宽度（减去安全区域）
  static double getAvailableWidth(final BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    return size.width - padding.left - padding.right;
  }

  /// 获取屏幕可用高度（减去安全区域）
  static double getAvailableHeight(final BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    return size.height - padding.top - padding.bottom;
  }

  /// 获取屏幕尺寸
  static Size getScreenSize(final BuildContext context) =>
      MediaQuery.of(context).size;

  /// 获取屏幕方向
  static Orientation getOrientation(final BuildContext context) =>
      MediaQuery.of(context).orientation;
}

/// 增强的响应式布局工具类
///
/// 整合了屏幕类型检测、响应式布局计算和主题工具功能
class ResponsiveLayout {
  // 缓存布局计算结果
  static final Map<String, dynamic> _layoutCache = {};

  /// 最大缓存条目数，防止内存无限增长
  static const int _maxCacheSize = 128;

  /// 清除布局缓存
  static void clearCache() {
    _layoutCache.clear();
  }

  /// 添加缓存条目，超过最大限制时清除最早的条目
  static void _addToCache(String key, dynamic value) {
    if (_layoutCache.length >= _maxCacheSize) {
      _layoutCache.clear();
    }
    _layoutCache[key] = value;
  }

  /// 获取响应式边距（基于屏幕类型和方向）
  static double getResponsivePadding(final BuildContext context) {
    final cacheKey =
        'padding_${ScreenType.getScreenType(context)}_${ScreenType.isPortrait(context)}';

    if (_layoutCache.containsKey(cacheKey)) {
      return _layoutCache[cacheKey];
    }

    final screenType = ScreenType.getScreenType(context);
    final isPortrait = ScreenType.isPortrait(context);

    double padding;
    switch (screenType) {
      case 'desktop':
        padding = 48;
        break;
      case 'tablet':
        padding = isPortrait ? 32.0 : 24.0;
        break;
      default: // mobile
        padding = isPortrait ? 20.0 : 16.0;
        break;
    }

    _addToCache(cacheKey, padding);
    return padding;
  }

  /// 获取响应式间距（组件间间距）
  static double getResponsiveSpacing(final BuildContext context) {
    final cacheKey =
        'spacing_${ScreenType.getScreenType(context)}_${ScreenType.isPortrait(context)}';

    if (_layoutCache.containsKey(cacheKey)) {
      return _layoutCache[cacheKey];
    }

    final screenType = ScreenType.getScreenType(context);
    final isPortrait = ScreenType.isPortrait(context);

    double spacing;
    switch (screenType) {
      case 'desktop':
        spacing = 32;
        break;
      case 'tablet':
        spacing = isPortrait ? 24.0 : 20.0;
        break;
      default: // mobile
        spacing = isPortrait ? 16.0 : 12.0;
        break;
    }

    _addToCache(cacheKey, spacing);
    return spacing;
  }

  /// 获取响应式字体大小（考虑屏幕方向和密度）
  static double getResponsiveFontSize(
    final double baseSize,
    final BuildContext context,
  ) {
    final cacheKey =
        'font_${ScreenType.getScreenType(context)}_${ScreenType.isPortrait(context)}_${MediaQuery.of(context).devicePixelRatio}_$baseSize';

    if (_layoutCache.containsKey(cacheKey)) {
      return _layoutCache[cacheKey];
    }

    final screenType = ScreenType.getScreenType(context);
    final isPortrait = ScreenType.isPortrait(context);
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;

    var scaleFactor = 1.0;

    switch (screenType) {
      case 'desktop':
        scaleFactor = 1.4;
        break;
      case 'tablet':
        scaleFactor = isPortrait ? 1.2 : 1.1;
        break;
      default: // mobile
        scaleFactor = isPortrait ? 1.0 : 0.95;
        break;
    }

    // 考虑像素密度
    if (pixelRatio > 2.5) {
      scaleFactor *= 0.9; // 高密度屏幕适当减小字体
    }

    final fontSize = (baseSize * scaleFactor).clamp(
      baseSize * 0.8,
      baseSize * 1.5,
    );
    _addToCache(cacheKey, fontSize);
    return fontSize;
  }

  /// 获取响应式按钮尺寸
  static Size getResponsiveButtonSize(final BuildContext context) {
    final cacheKey =
        'button_${ScreenType.getScreenType(context)}_${ScreenType.isPortrait(context)}_${MediaQuery.of(context).size.width}';

    if (_layoutCache.containsKey(cacheKey)) {
      return _layoutCache[cacheKey];
    }

    final screenType = ScreenType.getScreenType(context);
    final isPortrait = ScreenType.isPortrait(context);
    final screenWidth = MediaQuery.of(context).size.width;

    double buttonWidth;
    double buttonHeight;

    switch (screenType) {
      case 'desktop':
        buttonWidth = isPortrait ? screenWidth * 0.4 : screenWidth * 0.3;
        buttonHeight = isPortrait ? 80.0 : 70.0;
        break;
      case 'tablet':
        buttonWidth = isPortrait ? screenWidth * 0.5 : screenWidth * 0.35;
        buttonHeight = isPortrait ? 75.0 : 65.0;
        break;
      default: // mobile
        buttonWidth = isPortrait ? screenWidth * 0.7 : screenWidth * 0.5;
        buttonHeight = isPortrait ? 65.0 : 55.0;
        break;
    }

    // 设置最小和最大宽度限制
    var minWidth = 200.0;
    var maxWidth = 400.0;

    switch (screenType) {
      case 'desktop':
        minWidth = 250.0;
        maxWidth = 500.0;
        break;
      case 'tablet':
        minWidth = 220.0;
        maxWidth = 450.0;
        break;
    }

    buttonWidth = buttonWidth.clamp(minWidth, maxWidth);

    final size = Size(buttonWidth, buttonHeight);
    _addToCache(cacheKey, size);
    return size;
  }

  /// 计算棋盘尺寸（增强版）
  static double calculateBoardSize(
    final BoxConstraints constraints,
    final BuildContext context, {
    double maxWidthFactor = 0.9,
    double maxHeightFactor = 0.8,
  }) {
    final cacheKey =
        'board_${ScreenType.getScreenType(context)}_'
        '${ScreenType.isPortrait(context)}_${constraints.maxWidth}'
        '_${constraints.maxHeight}_${maxWidthFactor}_$maxHeightFactor';

    if (_layoutCache.containsKey(cacheKey)) {
      return _layoutCache[cacheKey];
    }

    final screenType = ScreenType.getScreenType(context);
    final isPortrait = ScreenType.isPortrait(context);

    final double availableWidth = constraints.maxWidth;
    final double availableHeight = constraints.maxHeight;

    // 根据设备类型调整因子
    double widthFactor = maxWidthFactor;
    double heightFactor = maxHeightFactor;

    switch (screenType) {
      case 'desktop':
        widthFactor = isPortrait ? 0.7 : 0.6;
        heightFactor = isPortrait ? 0.6 : 0.7;
        break;
      case 'tablet':
        widthFactor = isPortrait ? 0.8 : 0.7;
        heightFactor = isPortrait ? 0.7 : 0.8;
        break;
      default: // mobile
        widthFactor = isPortrait ? 0.9 : 0.8;
        heightFactor = isPortrait ? 0.8 : 0.9;
        break;
    }

    final widthBasedSize = availableWidth * widthFactor;
    final heightBasedSize = availableHeight * heightFactor;

    final double calculatedSize = widthBasedSize < heightBasedSize
        ? widthBasedSize
        : heightBasedSize;

    // 设置最小和最大尺寸限制
    var minSize = 200.0;
    var maxSize = 600.0;

    switch (screenType) {
      case 'desktop':
        minSize = 300.0;
        maxSize = 800.0;
        break;
      case 'tablet':
        minSize = 250.0;
        maxSize = 700.0;
        break;
    }

    final size = calculatedSize.clamp(minSize, maxSize);
    _addToCache(cacheKey, size);
    return size;
  }

  /// 获取响应式图标尺寸
  static double getResponsiveIconSize(final BuildContext context) {
    final cacheKey = 'icon_${ScreenType.getScreenType(context)}';

    if (_layoutCache.containsKey(cacheKey)) {
      return _layoutCache[cacheKey];
    }

    final screenType = ScreenType.getScreenType(context);

    double size;
    switch (screenType) {
      case 'desktop':
        size = 32;
        break;
      case 'tablet':
        size = 28;
        break;
      default: // mobile
        size = 24;
        break;
    }

    _addToCache(cacheKey, size);
    return size;
  }

  /// 获取响应式卡片圆角
  static double getResponsiveBorderRadius(final BuildContext context) {
    final cacheKey = 'radius_${ScreenType.getScreenType(context)}';

    if (_layoutCache.containsKey(cacheKey)) {
      return _layoutCache[cacheKey];
    }

    final screenType = ScreenType.getScreenType(context);

    double radius;
    switch (screenType) {
      case 'desktop':
        radius = 24;
        break;
      case 'tablet':
        radius = 20;
        break;
      default: // mobile
        radius = 16;
        break;
    }

    _addToCache(cacheKey, radius);
    return radius;
  }

  /// 获取响应式阴影模糊半径
  static double getResponsiveShadowBlur(final BuildContext context) {
    final cacheKey = 'shadow_${ScreenType.getScreenType(context)}';

    if (_layoutCache.containsKey(cacheKey)) {
      return _layoutCache[cacheKey];
    }

    final screenType = ScreenType.getScreenType(context);

    double blur;
    switch (screenType) {
      case 'desktop':
        blur = 16;
        break;
      case 'tablet':
        blur = 12;
        break;
      default: // mobile
        blur = 8;
        break;
    }

    _addToCache(cacheKey, blur);
    return blur;
  }

  /// 判断是否为平板竖屏模式（特殊处理）
  static bool isTabletPortrait(final BuildContext context) =>
      ScreenType.isTablet(context) && ScreenType.isPortrait(context);

  /// 判断是否为平板横屏模式（特殊处理）
  static bool isTabletLandscape(final BuildContext context) =>
      ScreenType.isTablet(context) && ScreenType.isLandscape(context);

  /// 获取屏幕安全区域边距
  static EdgeInsets getSafeAreaInsets(final BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return EdgeInsets.only(
      top: mediaQuery.padding.top,
      bottom: mediaQuery.padding.bottom,
      left: mediaQuery.padding.left,
      right: mediaQuery.padding.right,
    );
  }

  /// 获取键盘高度（考虑安全区域）
  static double getKeyboardHeight(
    final BuildContext context, {
    final double baseHeight = 200,
  }) {
    final cacheKey =
        'keyboard_${ScreenType.getScreenType(context)}_${ScreenType.isPortrait(context)}_$baseHeight';

    if (_layoutCache.containsKey(cacheKey)) {
      return _layoutCache[cacheKey];
    }

    final screenType = ScreenType.getScreenType(context);
    final isPortrait = ScreenType.isPortrait(context);

    double height;
    switch (screenType) {
      case 'desktop':
        height = baseHeight * 1.2;
        break;
      case 'tablet':
        height = isPortrait ? baseHeight * 1.1 : baseHeight * 0.9;
        break;
      default: // mobile
        height = isPortrait ? baseHeight : baseHeight * 0.8;
        break;
    }

    _addToCache(cacheKey, height);
    return height;
  }

  // ==================== 从 ResponsiveThemeUtils 合并的功能 ====================

  /// 根据屏幕尺寸获取响应式文本样式
  static TextStyle getResponsiveTextStyle(
    BuildContext context,
    TextStyle baseStyle,
  ) {
    final fontSize = getResponsiveFontSize(baseStyle.fontSize ?? 14, context);
    return baseStyle.copyWith(fontSize: fontSize);
  }

  /// 根据屏幕尺寸获取响应式标题样式
  static TextStyle getResponsiveTitleStyle(
    BuildContext context,
    TextStyle baseStyle,
  ) {
    final fontSize = getResponsiveFontSize(baseStyle.fontSize ?? 20, context);
    return baseStyle.copyWith(fontSize: fontSize);
  }

  /// 根据设备类型获取布局列数
  static int getGridColumns(BuildContext context) {
    if (ScreenType.isLargeDesktop(context)) return 4;
    if (ScreenType.isDesktop(context)) return 3;
    if (ScreenType.isTablet(context)) return 2;
    return 1;
  }

  /// 根据设备类型获取列表项高度
  static double getListItemHeight(BuildContext context, double baseHeight) =>
      ScreenType.getResponsiveHeight(context, baseHeight);

  /// 根据设备类型获取内容最大宽度
  static double getMaxContentWidth(BuildContext context) {
    if (ScreenType.isLargeDesktop(context)) return 1400;
    if (ScreenType.isDesktop(context)) return 1200;
    if (ScreenType.isTablet(context)) return 900;
    return ScreenType.getScreenWidth(context);
  }

  /// 根据设备类型获取侧边栏宽度
  static double getSidebarWidth(BuildContext context) {
    if (ScreenType.isLargeDesktop(context)) return 320;
    if (ScreenType.isDesktop(context)) return 280;
    if (ScreenType.isTablet(context)) return 240;
    return 0;
  }

  /// 根据屏幕尺寸计算响应式边距
  static double getMargin(BuildContext context, double baseMargin) {
    final cacheKey = 'margin_${ScreenType.getDeviceType(context).index}_$baseMargin';

    if (_layoutCache.containsKey(cacheKey)) {
      return _layoutCache[cacheKey];
    }

    final result = ScreenType.getResponsiveSpacing(context, baseMargin);
    _addToCache(cacheKey, result);
    return result;
  }

  /// 获取响应式边距 EdgeInsets
  static EdgeInsets getResponsivePaddingInsets(
    BuildContext context, {
    double horizontal = 16,
    double vertical = 16,
  }) => EdgeInsets.symmetric(
    horizontal: getMargin(context, horizontal),
    vertical: getMargin(context, vertical),
  );

  /// 根据屏幕尺寸计算响应式卡片大小
  static Size getCardSize(
    BuildContext context,
    double baseWidth,
    double baseHeight,
  ) => Size(
    ScreenType.getResponsiveWidth(context, baseWidth),
    ScreenType.getResponsiveHeight(context, baseHeight),
  );
}
