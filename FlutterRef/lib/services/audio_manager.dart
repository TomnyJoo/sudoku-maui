import 'package:audioplayers/audioplayers.dart';
import 'package:sudoku/utils/app_logger.dart';

/// 音频类型
enum AudioType { music, start, complete }

/// 音频路径类
class AudioPaths {
  static const String backgroundMusic = 'music/background.mp3'; /// 背景音乐
  static const String startSound = 'music/start_sound.mp3'; /// 开始音效
  static const String completeSound = 'music/complete_sound.mp3'; /// 完成音效

  /// 获取音频路径
  static String getPath(final AudioType type) {
    switch (type) {
      case AudioType.music:
        return backgroundMusic;
      case AudioType.start:
        return startSound;
      case AudioType.complete:
        return completeSound;
    }
  }
}

/// 音频管理器
class AudioManager {
  factory AudioManager() => _instance;
  AudioManager._internal();
  static final AudioManager _instance = AudioManager._internal();

  // ========== 变量 ==========
  AudioPlayer? _musicPlayer;
  double _musicVolume = 1;
  final List<AudioPlayer> _soundEffectPlayers = [];
  static const int _maxSoundEffectPlayers = 3;
  double _soundEffectVolume = 1;
  bool _musicEnabled = true;
  bool _soundEffectEnabled = true;
  bool _isInitialized = false;

  // ========== 属性 ==========
  bool get isMusicPlaying => _musicPlayer?.state == PlayerState.playing;
  bool get isMusicEnabled => _musicEnabled;
  bool get isSoundEffectEnabled => _soundEffectEnabled;

  // ========== 方法 ==========
  
  /// 确保音频管理器已初始化
  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;

    await initialize();
    _isInitialized = true;
  }

  Future<void> initialize() async {
    try {
      _musicPlayer = AudioPlayer();
      await _musicPlayer?.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer?.setVolume(_musicVolume);

      _isInitialized = true;
    } catch (e, stackTrace) {
      AppLogger.error('初始化音频管理器失败', e, stackTrace);
      rethrow;
    }
  }

  void setMusicEnabled(final bool enabled) {
    _musicEnabled = enabled;
    if (!enabled) {
      pauseMusic();
    }
  }

  set soundEffectEnabled(final bool enabled) {
    _soundEffectEnabled = enabled;
  }

  /// 设置音乐音量
  Future<void> setMusicVolume(final double volume) async {
    _musicVolume = volume.clamp(0.0, 1.0);
    await _musicPlayer?.setVolume(_musicVolume);
  }

  /// 设置音效音量
  Future<void> setSoundEffectVolume(final double volume) async {
    _soundEffectVolume = volume.clamp(0.0, 1.0);
    for (final player in _soundEffectPlayers) {
      await player.setVolume(_soundEffectVolume);
    }
  }

  /// 播放音乐
  Future<void> playMusic() async {
    if (!_musicEnabled) {
      return;
    }

    await _ensureInitialized();

    try {
      final player = _musicPlayer;
      if (player == null) {
        return;
      }

      final currentState = player.state;

      if (currentState == PlayerState.playing) {
        return;
      }

      if (currentState == PlayerState.paused) {
        await player.resume();
        return;
      }

      final path = AudioPaths.getPath(AudioType.music);
      await player.play(AssetSource(path), volume: _musicVolume);
    } catch (e, stackTrace) {
      AppLogger.error('播放音乐失败', e, stackTrace);
    }
  }

  /// 暂停音乐
  Future<void> pauseMusic() async {
    await _ensureInitialized();

    try {
      final player = _musicPlayer;
      if (player == null) {
        return;
      }

      final currentState = player.state;

      if (currentState != PlayerState.playing) {
        return;
      }

      await player.pause();
    } catch (e, stackTrace) {
      AppLogger.error('暂停音乐失败', e, stackTrace);
    }
  }

  /// 恢复音乐
  Future<void> resumeMusic() async {
    if (!_musicEnabled) {
      return;
    }

    await _ensureInitialized();

    try {
      final player = _musicPlayer;
      if (player == null) {
        return;
      }

      final currentState = player.state;

      if (currentState == PlayerState.paused) {
        await player.resume();
      } else if (currentState == PlayerState.stopped ||
          currentState == PlayerState.completed) {
        await playMusic();
      }
    } catch (e, stackTrace) {
      AppLogger.error('恢复音乐失败', e, stackTrace);
      await playMusic();
    }
  }

  /// 停止音乐
  Future<void> stopMusic() async {
    try {
      final player = _musicPlayer;
      if (player == null) {
        return;
      }

      await player.stop();
    } catch (e, stackTrace) {
      AppLogger.error('停止音乐失败', e, stackTrace);
    }
  }

  /// 播放音效
  Future<void> playSoundEffect(final AudioType type) async {
    if (!_soundEffectEnabled) {
      return;
    }

    await _ensureInitialized();

    try {
      final player = await _getAvailableSoundEffectPlayer();
      if (player == null) {
        return;
      }

      await player.play(
        AssetSource(AudioPaths.getPath(type)),
        volume: _soundEffectVolume,
      );
    } catch (e, stackTrace) {
      AppLogger.error('播放音效失败', e, stackTrace);
    }
  }

  /// 获取可用的音效玩家
  Future<AudioPlayer?> _getAvailableSoundEffectPlayer() async {
    for (final player in _soundEffectPlayers) {
      if (player.state != PlayerState.playing) {
        return player;
      }
    }

    if (_soundEffectPlayers.length < _maxSoundEffectPlayers) {
      final player = AudioPlayer();
      await player.setVolume(_soundEffectVolume);
      _soundEffectPlayers.add(player);
      return player;
    }

    return null;
  }

  /// 播放开始音效
  Future<void> playStartSound() async {
    await playSoundEffect(AudioType.start);
  }

  /// 播放完成音效
  Future<void> playCompleteSound() async {
    await playSoundEffect(AudioType.complete);
  }

  /// 处置音频管理器
  Future<void> dispose() async {
    try {
      await stopMusic();
      await _musicPlayer?.dispose();
      _musicPlayer = null;

      for (final player in _soundEffectPlayers) {
        try {
          await player.dispose();
        } catch (e, stackTrace) {
          AppLogger.error('释放音效播放器失败', e, stackTrace);
        }
      }
      _soundEffectPlayers.clear();

      // 重置状态标志，防止 dispose 后继续使用
      _isInitialized = false;
      _musicEnabled = true;
      _soundEffectEnabled = true;
    } catch (e, stackTrace) {
      AppLogger.error('释放音频管理器失败', e, stackTrace);
    }
  }
}
