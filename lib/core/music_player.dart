import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

const bool debugAudio = true;

class MusicPlayer {
  // Final and _instance ensure only one singleton is created
  static final MusicPlayer _instance = MusicPlayer._internal();
  // Singleton factory
  factory MusicPlayer() => _instance;
  MusicPlayer._internal(); // Private named constructor

  // Give music player unique ID so AudioContext is not shared with sfx
  final AudioPlayer _player = AudioPlayer(playerId: 'music')..setAudioContext(
    AudioContext(
      android: AudioContextAndroid(
        isSpeakerphoneOn: false,
        stayAwake: true,
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.media,
        audioFocus: AndroidAudioFocus.gain,
      ),
    ),
  );

  String? _currentTrack;
  String? get currentTrack => _currentTrack;
  double _volume = 0.8;
  bool isMuted = false;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    // Load mute button state from shared prefs
    isMuted = prefs.getBool('musicMuted') ?? false;
    // Setting volume also applies mute state
    await setVolume(_volume);
  }

  // Expose setVolume to other files thru new method
  Future<void> setVolume(double volume) async {
    _volume = volume;
    await _player.setVolume(isMuted ? 0.0 : volume);
    if (debugAudio) {
      print(
        '🔊 setVolume called: effective volume = ${isMuted ? 0.0 : volume}',
      );
    }
  }

  Future<void> updateMute(bool mute) async {
    // Pass in mute state from arg
    isMuted = mute;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('musicMuted', mute);
    await _player.setVolume(isMuted ? 0.0 : _volume);
  }

  /// Plays a music track from assets at a given volume.
  /// Set resume to true to continue from where it left off last time.
  Future<void> play(
    String assetPath, {
    double volume = 1.0,
    bool resume = false,
    bool loop = false,
  }) async {
    if (debugAudio) {
      print('🎵 play() called for: $assetPath (resume: $resume, loop: $loop)');
    }
    if (_currentTrack == assetPath && _player.state == PlayerState.playing) {
      if (debugAudio) print('🔁 Already playing $assetPath');
      return;
    }

    _currentTrack = assetPath;
    await setVolume(volume);
    // Set loop mode based on passed loop argument
    await _player.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.stop);

    int startMillis = 0;
    if (resume) {
      final prefs = await SharedPreferences.getInstance();
      startMillis = prefs.getInt(_resumeKey(assetPath)) ?? 0;
      if (debugAudio) print('⏩ Resuming from $startMillis ms');
    }

    await _player.play(
      AssetSource(assetPath),
      position: Duration(milliseconds: startMillis),
    );
  }

  // Stops track and saves timestamp
  Future<void> pause() async {
    //DEBUG CODE
    if (debugAudio) print('⏸️ Pausing track: $_currentTrack');

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
    double volume = _volume;
    if (_currentTrack != null) {
      // Re-apply the last known volume
      await setVolume(volume);
      await _player.resume();
    }
  }

  /// Stops playback w/o storing timestamp
  Future<void> stop() async {
    // DEBUG CODE
    if (debugAudio) print('⏹️ Stopping track: $_currentTrack');
    await _player.stop();
    // Clears name of currentTrack
    _currentTrack = null;
  }

  /// Clean up resources
  void dispose() {
    _player.dispose();
  }

  // Creates unique key to resume each track
  String _resumeKey(String path) => 'music_resume_${path.hashCode}';
}
