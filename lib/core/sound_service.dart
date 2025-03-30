import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static final AudioPlayer _player = AudioPlayer();

  /// Plays a short sound effect (like taps, chips, etc.).
  /// Defaults to 60% volume unless overridden.
  static Future<void> play(String assetPath, {double volume = 0.7}) async {
    final path = assetPath.replaceFirst('assets/', '');
    await _player.setVolume(volume);
    await _player.play(AssetSource(path));
  }
}
