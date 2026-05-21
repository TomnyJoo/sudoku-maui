import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sudoku/constants/app_constants.dart';
import 'package:sudoku/models/index.dart';
import 'package:sudoku/utils/app_logger.dart';
/// 游戏配置管理类，负责从配置文件加载游戏规则
class GameConfig {
  
  /// 工厂构造函数
  factory GameConfig() => _instance;
  
  /// 私有构造函数
  GameConfig._internal();
  /// 单例实例
  static final GameConfig _instance = GameConfig._internal();
  
  /// 游戏配置数据
  Map<String, dynamic>? _configData;
  
  /// 难度配置数据
  Map<String, dynamic>? _difficultyConfigData;
  
  /// 是否已初始化
  bool _initialized = false;
  
  /// 初始化游戏配置
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // 加载游戏类型配置文件
      final gameTypeContent = await rootBundle.loadString(AppConstants.gameTypesConfigPath);
      final decoded = json.decode(gameTypeContent);
      if (decoded is Map<String, dynamic>) {
        _configData = decoded;
      } else {
        AppLogger.warning('game_types.json 格式异常，使用默认配置');
        _configData = _getDefaultConfig();
      }

      try {
        // 加载难度配置文件
        final difficultyContent = await rootBundle.loadString(AppConstants.difficultyConfigPath);
        final diffDecoded = json.decode(difficultyContent);
        if (diffDecoded is Map<String, dynamic>) {
          // 标准格式: {"difficultyLevels": [...]}
          _difficultyConfigData = diffDecoded;
        } else if (diffDecoded is List) {
          // 兼容格式: 直接是数组 [...]
          _difficultyConfigData = {'difficultyLevels': diffDecoded};
        } else {
          AppLogger.warning('difficulty_config.json 格式异常，使用默认值');
          _difficultyConfigData = {'difficultyLevels': []};
        }
      } catch (e) {
        AppLogger.error('加载难度配置失败', e);
        // 难度配置加载失败时，使用空的默认值
        _difficultyConfigData = {'difficultyLevels': []};
      }
      
      _initialized = true;
    } catch (e) {
      AppLogger.error('加载游戏配置失败', e); 
      // 使用默认配置
      _configData = _getDefaultConfig();
      _difficultyConfigData = {'difficultyLevels': []};
      _initialized = true;
    }
  }
  
  /// 获取默认配置
  Map<String, dynamic> _getDefaultConfig() => {
      'gameTypes': {
        'standard': {
          'name': 'Standard Sudoku',
          'localization': {
            'nameKey': 'gameTypeStandardName',
            'descriptionKey': 'gameTypeStandardDescription',
            'rulesKey': 'gameTypeStandardRules'
          },
          'rules': {
            'size': 9,
            'regions': '3x3'
          },
          'validationRules': {
            'rowUnique': true,
            'columnUnique': true,
            'regionUnique': true
          },
          'generationParams': {
            'minClues': 30,
            'maxClues': 45,
            'symmetry': 'rotational'
          },
          'showCustomGame': true,
          'icon': 'grid_on',
          'color': '#4CAF50',
          'uiConfig': {
            'boardSize': 'medium',
            'cellPadding': 8,
            'fontSize': 18
          }
        },
        'diagonal': {
          'name': 'Diagonal Sudoku',
          'localization': {
            'nameKey': 'gameTypeDiagonalName',
            'descriptionKey': 'gameTypeDiagonalDescription',
            'rulesKey': 'gameTypeDiagonalRules'
          },
          'rules': {
            'size': 9,
            'regions': '3x3',
            'diagonals': true
          },
          'validationRules': {
            'rowUnique': true,
            'columnUnique': true,
            'regionUnique': true,
            'diagonalUnique': true
          },
          'generationParams': {
            'minClues': 30,
            'maxClues': 45,
            'symmetry': 'rotational'
          },
          'showCustomGame': true,
          'icon': 'control_camera',
          'color': '#2196F3',
          'uiConfig': {
            'boardSize': 'medium',
            'cellPadding': 8,
            'fontSize': 18
          }
        },
        'window': {
          'name': 'Window Sudoku',
          'localization': {
            'nameKey': 'gameTypeWindowName',
            'descriptionKey': 'gameTypeWindowDescription',
            'rulesKey': 'gameTypeWindowRules'
          },
          'rules': {
            'size': 9,
            'regions': '3x3',
            'windows': true
          },
          'validationRules': {
            'rowUnique': true,
            'columnUnique': true,
            'regionUnique': true,
            'windowUnique': true
          },
          'generationParams': {
            'minClues': 30,
            'maxClues': 45,
            'symmetry': 'rotational'
          },
          'showCustomGame': true,
          'customGameRoute': '/window_custom',
          'icon': 'window',
          'color': '#FF9800',
          'uiConfig': {
            'boardSize': 'medium',
            'cellPadding': 8,
            'fontSize': 18
          }
        },
        'jigsaw': {
          'name': 'Jigsaw Sudoku',
          'localization': {
            'nameKey': 'gameTypeJigsawName',
            'descriptionKey': 'gameTypeJigsawDescription',
            'rulesKey': 'gameTypeJigsawRules'
          },
          'rules': {
            'size': 9,
            'regions': 'irregular'
          },
          'validationRules': {
            'rowUnique': true,
            'columnUnique': true,
            'regionUnique': true
          },
          'generationParams': {
            'minClues': 30,
            'maxClues': 45,
            'symmetry': 'rotational'
          },
          'showCustomGame': true,
          'customGameRoute': '/jigsaw_custom',
          'icon': 'extension',
          'color': '#9C27B0',
          'uiConfig': {
            'boardSize': 'medium',
            'cellPadding': 8,
            'fontSize': 18
          }
        },
        'killer': {
          'name': 'Killer Sudoku',
          'localization': {
            'nameKey': 'gameTypeKillerName',
            'descriptionKey': 'gameTypeKillerDescription',
            'rulesKey': 'gameTypeKillerRules'
          },
          'rules': {
            'size': 9,
            'regions': '3x3',
            'cages': true
          },
          'validationRules': {
            'rowUnique': true,
            'columnUnique': true,
            'regionUnique': true,
            'cageSum': true
          },
          'generationParams': {
            'minClues': 0,
            'maxClues': 0,
            'symmetry': 'rotational'
          },
          'showCustomGame': false,
          'icon': 'calculate',
          'color': '#F44336',
          'uiConfig': {
            'boardSize': 'medium',
            'cellPadding': 8,
            'fontSize': 16
          }
        },
        'samurai': {
          'name': 'Samurai Sudoku',
          'localization': {
            'nameKey': 'gameTypeSamuraiName',
            'descriptionKey': 'gameTypeSamuraiDescription',
            'rulesKey': 'gameTypeSamuraiRules'
          },
          'rules': {
            'size': 21,
            'regions': '3x3',
            'multipleBoards': true
          },
          'validationRules': {
            'rowUnique': true,
            'columnUnique': true,
            'regionUnique': true
          },
          'generationParams': {
            'minClues': 120,
            'maxClues': 150,
            'symmetry': 'rotational'
          },
          'showCustomGame': false,
          'icon': 'supervisor_account',
          'color': '#795548',
          'uiConfig': {
            'boardSize': 'large',
            'cellPadding': 4,
            'fontSize': 12
          }
        }
      }
    };
  
  /// 获取游戏类型配置
  Map<String, dynamic>? getGameConfig(GameType gameType) {
    if (!_initialized) {
      AppLogger.warning('游戏配置未初始化，无法获取游戏类型配置');
      return null;
    }
    
    final gameTypes = _configData?['gameTypes'] as Map<String, dynamic>?;
    return gameTypes?[gameType.toString().split('.').last];
  }
  
  /// 获取所有游戏类型配置
  Map<String, dynamic>? getAllGameConfigs() {
    if (!_initialized) {
      AppLogger.warning('游戏配置未初始化，无法获取所有游戏类型配置');
      return null;
    }
    
    return _configData?['gameTypes'] as Map<String, dynamic>?;
  }
  
  /// 获取游戏难度级别
  List<String> getDifficultyLevels(GameType gameType) {
    // 从难度配置文件中获取难度级别
    final difficultyLevels = _difficultyConfigData?['difficultyLevels'] as List<dynamic>?;
    if (difficultyLevels != null) {
      return difficultyLevels
          .map((level) => level['level'] as String)
          .where((level) => level != 'custom') // 排除自定义难度
          .toList();
    }
    
    // 从游戏类型配置中获取（兼容旧配置）
    final config = getGameConfig(gameType);
    final levels = config?['difficultyLevels'] as List<dynamic>?;
    return levels?.cast<String>() ?? ['beginner', 'easy', 'medium', 'hard', 'expert', 'master'];
  }
  
  /// 获取游戏规则
  Map<String, dynamic>? getGameRules(GameType gameType) {
    final config = getGameConfig(gameType);
    return config?['rules'] as Map<String, dynamic>?;
  }
  
  /// 检查游戏类型是否支持指定规则
  bool supportsRule(GameType gameType, String rule) {
    final rules = getGameRules(gameType);
    return rules?[rule] == true;
  }
  
  /// 获取游戏图标
  IconData getGameIcon(GameType gameType) {
    final config = getGameConfig(gameType);
    final iconName = config?['icon'] as String?;
    return _getIconByName(iconName);
  }
  
  /// 获取游戏颜色
  Color getGameColor(GameType gameType) {
    final config = getGameConfig(gameType);
    final colorHex = config?['color'] as String?;
    return Color(int.parse(colorHex?.replaceAll('#', '0xFF') ?? '0xFF4CAF50'));
  }

  /// 是否显示自定义游戏
  bool showCustomGame(GameType gameType) {
    final config = getGameConfig(gameType);
    return config?['showCustomGame'] as bool? ?? false;
  }

  /// 获取自定义游戏路由
  String? getCustomGameRoute(GameType gameType) {
    final config = getGameConfig(gameType);
    return config?['customGameRoute'] as String?;
  }

  /// 获取游戏本地化配置
  Map<String, dynamic>? getGameLocalization(GameType gameType) {
    final config = getGameConfig(gameType);
    return config?['localization'] as Map<String, dynamic>?;
  }

  /// 获取游戏名称本地化键
  String? getGameNameLocalizationKey(GameType gameType) {
    final localization = getGameLocalization(gameType);
    return localization?['nameKey'] as String?;
  }

  /// 获取游戏描述本地化键
  String? getGameDescriptionLocalizationKey(GameType gameType) {
    final localization = getGameLocalization(gameType);
    return localization?['descriptionKey'] as String?;
  }

  /// 获取游戏规则本地化键
  String? getGameRulesLocalizationKey(GameType gameType) {
    final localization = getGameLocalization(gameType);
    return localization?['rulesKey'] as String?;
  }

  /// 获取游戏验证规则
  Map<String, dynamic>? getGameValidationRules(GameType gameType) {
    final config = getGameConfig(gameType);
    return config?['validationRules'] as Map<String, dynamic>?;
  }

  /// 获取游戏生成参数
  Map<String, dynamic>? getGameGenerationParams(GameType gameType) {
    final config = getGameConfig(gameType);
    return config?['generationParams'] as Map<String, dynamic>?;
  }

  /// 获取游戏难度参数
  Map<String, dynamic>? getGameDifficultyParams(GameType gameType) {
    // 从难度配置文件中获取
    final difficultyLevels = _difficultyConfigData?['difficultyLevels'] as List<dynamic>?;
    if (difficultyLevels != null) {
      final gameTypeStr = gameType.toString().split('.').last;
      final params = <String, dynamic>{};

      for (final level in difficultyLevels) {
        final levelName = level['level'] as String;
        // 新格式: level['gameTypeConfigs'] is Map
        final gameTypeConfigs = level['gameTypeConfigs'] as Map<String, dynamic>?;
        if (gameTypeConfigs != null && gameTypeConfigs.containsKey(gameTypeStr)) {
          params[levelName] = gameTypeConfigs[gameTypeStr];
        } else {
          // 旧格式: 扁平字段如 standardMinFilled
          final minKey = '${gameTypeStr}MinFilled';
          final maxKey = '${gameTypeStr}MaxFilled';
          if (level.containsKey(minKey) || level.containsKey(maxKey)) {
            params[levelName] = {
              'minFilledCells': level[minKey],
              'maxFilledCells': level[maxKey],
              'difficultyScore': level['difficultyScore'],
              'maxStrategyLevel': level['maxStrategyLevel'],
            };
          }
        }
      }

      return params.isNotEmpty ? params : null;
    }
    
    // 从游戏类型配置中获取（兼容旧配置）
    final config = getGameConfig(gameType);
    return config?['difficultyParams'] as Map<String, dynamic>?;
  }

  /// 获取特定难度的参数
  Map<String, dynamic>? getDifficultyParams(GameType gameType, String difficulty) {
    // 从难度配置文件中获取
    final difficultyLevels = _difficultyConfigData?['difficultyLevels'] as List<dynamic>?;
    if (difficultyLevels != null) {
      final gameTypeStr = gameType.toString().split('.').last;

      for (final level in difficultyLevels) {
        if (level['level'] == difficulty) {
          // 新格式: level['gameTypeConfigs'] is Map
          final gameTypeConfigs = level['gameTypeConfigs'] as Map<String, dynamic>?;
          if (gameTypeConfigs != null) {
            return gameTypeConfigs[gameTypeStr] as Map<String, dynamic>?;
          }
          // 旧格式: 扁平字段如 standardMinFilled, standardMaxFilled
          final minKey = '${gameTypeStr}MinFilled';
          final maxKey = '${gameTypeStr}MaxFilled';
          if (level.containsKey(minKey) || level.containsKey(maxKey)) {
            return {
              'minFilledCells': level[minKey],
              'maxFilledCells': level[maxKey],
              'difficultyScore': level['difficultyScore'],
              'maxStrategyLevel': level['maxStrategyLevel'],
            };
          }
          return null;
        }
      }
    }

    // 从游戏类型配置中获取（兼容旧配置）
    final difficultyParams = getGameDifficultyParams(gameType);
    return difficultyParams?[difficulty] as Map<String, dynamic>?;
  }

  /// 获取游戏UI配置
  Map<String, dynamic>? getGameUIConfig(GameType gameType) {
    final config = getGameConfig(gameType);
    return config?['uiConfig'] as Map<String, dynamic>?;
  }
  
  /// 重新加载配置
  Future<void> reloadConfig() async {
    _initialized = false;
    await initialize();
  }
  
  /// 获取配置加载状态
  bool get isInitialized => _initialized;
  
  /// 根据图标名称获取图标
  IconData _getIconByName(String? iconName) {
    switch (iconName) {
      case 'grid_on':
        return Icons.grid_on;
      case 'extension':
        return Icons.extension;
      case 'control_camera':
        return Icons.control_camera;
      case 'calculate':
        return Icons.calculate;
      case 'window':
        return Icons.window;
      case 'supervisor_account':
        return Icons.supervisor_account;
      default:
        return Icons.grid_on;
    }
  }
}
