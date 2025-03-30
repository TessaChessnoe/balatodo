import 'package:flutter/material.dart';
import 'screens/start_screen.dart';
import 'screens/checkbox_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // For date formatting

// Required to declare musicPlayer singleton
import 'core/music_player.dart';

final MusicPlayer musicPlayer = MusicPlayer(); // global instance

void main() {
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

class RootApp extends StatefulWidget {
  const RootApp({super.key});

  @override
  State<RootApp> createState() => _RootAppState();
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
    musicPlayer.dispose(); // optional
    super.dispose();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _checkDailyReset();
    _loadState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      musicPlayer.pause(); // App goes to tray or lock screen
    } else if (state == AppLifecycleState.resumed) {
      musicPlayer.resume(); // App comes back
    }
  }

  void _checkDailyReset() {
    final now = DateTime.now();
    final lastReset = _prefs.getString('lastResetDate');
    final today = DateFormat('yyyy-MM-dd').format(now);

    if (lastReset != today) {
      _prefs.clear();
      _prefs.setString('lastResetDate', today);
      setState(() {
        _maxStakeIndex = null;
      });
    }
  }

  void _loadState() {
    final savedIndex = _prefs.getInt('maxStakeIndex');
    if (savedIndex != null) {
      setState(() {
        _maxStakeIndex = savedIndex;
      });
    }
  }

  void _saveState(int index) {
    _prefs.setInt('maxStakeIndex', index);
  }

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
