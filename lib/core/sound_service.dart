import 'package:audioplayers/audioplayers.dart';
import 'dart:math';

class SoundService {
  // Give sfx player unique ID so AudioContext is not shared with global mus player
  static final AudioPlayer _player = AudioPlayer(playerId: 'sfx')
    ..setAudioContext(
      AudioContext(
        android: AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: false,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.none,
        ),
      ),
    );

  /// Plays a short sound effect (like taps, chips, etc.).
  /// Defaults to 60% volume unless overridden.
  static Future<void> play(String soundPath, {double volume = 0.7}) async {
    final path = soundPath.replaceFirst('assets/', '');
    await _player.setVolume(volume);
    await _player.play(AssetSource(path));
  }

  static Future<void> playRandom(
    List<String> soundPaths, {
    double volume = 0.7,
  }) async {
    final random = Random();
    int n = random.nextInt(soundPaths.length);
    final soundPath = soundPaths[n];
    final path = soundPath.replaceFirst('assets/', '');
    await _player.setVolume(volume);
    await _player.play(AssetSource(path));
  }
}
