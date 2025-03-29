import 'package:flutter/material.dart';
import 'start_screen.dart';
import 'checkbox_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // For date formatting

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

class PixelArtConfig {
  static const double globalScale = 2.0; // Default scale for pixel art
  static const double basePixelSize = 27.0;
}

// Data model for a checkbox item
class CheckboxItem {
  String label;
  bool isChecked;
  final String soundPath;
  final String imagePath;
  final double? customScale;
  List<Subtask> subtasks;
  DateTime lastUpdated;

  CheckboxItem({
    required this.label,
    required this.soundPath,
    required this.imagePath,
    this.customScale,
    this.isChecked = false,
    List<Subtask>? subtasks,
    DateTime? lastUpdated,
  }) : subtasks = subtasks ?? [],
       lastUpdated = lastUpdated ?? DateTime.now();
}

class Subtask {
  String text;
  bool isCompleted;

  Subtask(this.text, {this.isCompleted = false});
}

class RootApp extends StatefulWidget {
  const RootApp({super.key});

  @override
  State<RootApp> createState() => _RootAppState();
}

// Update _RootAppState
class _RootAppState extends State<RootApp> {
  int? _maxStakeIndex;
  late SharedPreferences _prefs;
  DateTime? _lastResetDate;

  @override
  void initState() {
    super.initState();
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _checkDailyReset();
    _loadState();
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
