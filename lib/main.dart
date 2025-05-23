import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/start_screen.dart';
import 'screens/checkbox_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/storage_service.dart';

// Required to declare musicPlayer singleton
import 'core/music_player.dart';

final MusicPlayer musicPlayer = MusicPlayer(); // global instance

void main() async {
  // Must initialize to use SystemChrome
  WidgetsFlutterBinding.ensureInitialized();
  await musicPlayer.init();
  // Lock app orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(
    Center(
      child: SizedBox(
        width: 412, // Simulates a large Android phone
        height: 915,
        child: RootApp(),
      ),
    ),
  );
}

// App state controller pushes different screens
// Observer allows minimizing and closing app to be tracked
class _RootAppState extends State<RootApp> with WidgetsBindingObserver {
  int? _maxStakeIndex;
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    // Create observer to check if app closed/minimized
    WidgetsBinding.instance.addObserver(this);
    _initPrefs();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    musicPlayer.dispose();

    super.dispose();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();

    final returnToStart = _prefs.getBool('returnToStart') ?? false;
    if (returnToStart) {
      await _prefs.setBool('returnToStart', false);
      setState(() => _maxStakeIndex = null);
      return;
    }

    final savedIndex = _prefs.getInt('maxStakeIndex');
    final items = await StorageService.loadCheckboxItems();

    // Prevent showing an empty stake list on first run
    if (savedIndex != null && items.isEmpty) {
      // Force return to start screen
      setState(() => _maxStakeIndex = null);
    } else if (savedIndex != null) {
      setState(() {
        _maxStakeIndex = savedIndex;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Pause music if exiting to tray or lock screen
      musicPlayer.pause();
    } else if (state == AppLifecycleState.resumed) {
      // Resume music after re-entering app
      musicPlayer.resume();
    }
  }

  void _saveState(int index) {
    _prefs.setInt('maxStakeIndex', index);
    // Clear return flag
    _prefs.setBool('returnToStart', false);
  }

  // I DONT UNDERSTAND YET
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stake Tracker',
      theme: ThemeData(primarySwatch: Colors.blue),
      home:
          _maxStakeIndex == null
              ? StartScreen(
                onStart: (index) {
                  _saveState(index);
                  setState(() {
                    _maxStakeIndex = index;
                  });
                },
              )
              : CheckboxScreen(maxStakeIndex: _maxStakeIndex!),
    );
  }
}

class RootApp extends StatefulWidget {
  const RootApp({super.key});

  @override
  State<RootApp> createState() => _RootAppState();
}
