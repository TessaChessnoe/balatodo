import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(MyApp());
}

class PixelArtConfig {
  static const double globalScale = 15.0; // Default scale for pixel art
  static const double basePixelSize = 27.0;
  static const double maxRenderSize = 64.0;
}

// Data model for a checkbox item
class CheckboxItem {
  String label; // Text label to display
  bool isChecked; // Current checked state
  final String soundPath; // Filepath for 'check' sound
  final String imagePath; // Image for checklist item
  final double? customScale; // Optional override
  CheckboxItem({
    required this.label,
    required this.soundPath,
    required this.imagePath,
    this.customScale,
    this.isChecked = false,
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Root widget of the app
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Custom Checkbox App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: CheckboxScreen(), // Loads the main screen
    );
  }
}

class CheckboxScreen extends StatefulWidget {
  const CheckboxScreen({super.key});

  @override
  _CheckboxScreenState createState() => _CheckboxScreenState();
}

class _CheckboxScreenState extends State<CheckboxScreen> {
  // Hardcoded list of checkbox items
  final List<CheckboxItem> items = [
    CheckboxItem(
      label: 'White Stake',
      soundPath: 'assets/sounds/mult1.wav',
      imagePath: 'assets/images/white-stake.png',
    ),
    CheckboxItem(
      label: 'Red Stake',
      soundPath: 'assets/sounds/mult2.wav',
      imagePath: 'assets/images/red-stake.png',
    ),
    CheckboxItem(
      label: 'Green Stake',
      soundPath: 'assets/sounds/mult3.wav',
      imagePath: 'assets/images/green-stake.png',
    ),
    CheckboxItem(
      label: 'Black Stake',
      soundPath: 'assets/sounds/xmult1.wav',
      imagePath: 'assets/images/black-stake.png',
    ),
    CheckboxItem(
      label: 'Blue Stake',
      soundPath: 'assets/sounds/xmult2.wav',
      imagePath: 'assets/images/blue-stake.png',
    ),
    CheckboxItem(
      label: 'Purple Stake',
      soundPath: 'assets/sounds/xmult3.wav',
      imagePath: 'assets/images/purple-stake.png',
    ),
    CheckboxItem(
      label: 'Orange Stake',
      soundPath: 'assets/sounds/xmult4.wav',
      imagePath: 'assets/images/orange-stake.png',
    ),
    CheckboxItem(
      label: 'Gold Stake',
      soundPath: 'assets/sounds/final-mult.wav',
      imagePath: 'assets/images/gold-stake.png',
    ),
  ];

  // AudioPlayer instance to handle sound playback
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Play sound when a checkbox is toggled
  void _playSound(String path) async {
    final relativePath = path.replaceFirst('assets/', '');
    await _audioPlayer.play(AssetSource(relativePath));
  }

  // Toggle the checkbox and play the sound
  void _toggleCheckbox(int index) {
    setState(() {
      items[index].isChecked = !items[index].isChecked;
    });
    _playSound(items[index].soundPath);
  }

  @override
  void dispose() {
    // Dispose of the audio player when the widget is destroyed
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Daily Checklist')),
      body: ListView.builder(
        itemCount: items.length, // Fixed number of checkboxes
        itemBuilder: (context, index) {
          // Prevents current checkbox item from being incorrectly reassigned
          final item = items[index];
          // Use customScale if set, otherwise, use global pixel scaling
          final double scale = item.customScale ?? PixelArtConfig.globalScale;
          final double displaySize = PixelArtConfig.basePixelSize * scale;

          // Must wrap checklist tile in fixed-size container
          // Otherwise tile grows out of proportion to larger pixel art
          return SizedBox(
            height: 72, // fixed tile height
            child: CheckboxListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 12),
              title: Row(
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: PixelArtConfig.maxRenderSize,
                      maxHeight: PixelArtConfig.maxRenderSize,
                    ),
                    child: SizedBox(
                      width: displaySize,
                      height: displaySize,
                      child: Image.asset(
                        item.imagePath,
                        filterQuality: FilterQuality.none,
                        isAntiAlias: false,
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(child: Text(item.label)),
                ],
              ),
              value: item.isChecked,
              onChanged: (_) => _toggleCheckbox(index),
            ),
          );
        },
      ),
    );
  }
}
