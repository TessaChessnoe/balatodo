import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MusicPlayer {
  // Final and _instance ensure only one singleton is created
  static final MusicPlayer _instance = MusicPlayer._internal();
  // Singleton factory
  factory MusicPlayer() => _instance;
  MusicPlayer._internal(); // Private named constructor

  final AudioPlayer _player = AudioPlayer();
  String? _currentTrack;
  double _volume = 1.0;

  /// Plays a music track from assets at a given [volume].
  /// Set [resume] to true to continue from where it left off last time.
  Future<void> play(
    String assetPath, {
    double volume = 1.0,
    bool resume = false,
  }) async {
    _currentTrack = assetPath;
    // Copy state to public variable for later reuse
    _volume = volume;
    await _player.setVolume(volume);

    int startMillis = 0;
    if (resume) {
      final prefs = await SharedPreferences.getInstance();
      // Set new start time in ms if resuming music
      startMillis = prefs.getInt(_resumeKey(assetPath)) ?? 0;
    }

    await _player.play(
      AssetSource(assetPath),
      position: Duration(milliseconds: startMillis),
    );
  }

  // Stops track and saves timestamp
  Future<void> pause() async {
    await _player.pause();
    if (_currentTrack != null) {
      final position = await _player.getCurrentPosition();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        _resumeKey(_currentTrack!),
        position?.inMilliseconds ?? 0,
      );
    }
  }

  // Resumes from key stored in pause
  Future<void> resume() async {
    if (_currentTrack != null) {
      await _player.resume();
    }
  }

  /// Stops playback w/o storing timestamp
  Future<void> stop() async {
    await _player.stop();
  }

  /// Clean up resources
  void dispose() {
    _player.dispose();
  }

  // Creates unique key to resume each track
  String _resumeKey(String path) => 'music_resume_${path.hashCode}';
}
