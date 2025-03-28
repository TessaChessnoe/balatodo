import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(
    Center(
      child: SizedBox(
        width: 412, // Simulates a large Android phone
        height: 915,
        child: MyApp(),
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Custom Checkbox App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: CheckboxScreen(),
    );
  }
}

class CheckboxScreen extends StatefulWidget {
  const CheckboxScreen({super.key});

  @override
  _CheckboxScreenState createState() => _CheckboxScreenState();
}

class _CheckboxScreenState extends State<CheckboxScreen> {
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

  final AudioPlayer _audioPlayer = AudioPlayer();

  void _playSound(String path) async {
    final relativePath = path.replaceFirst('assets/', '');
    await _audioPlayer.play(AssetSource(relativePath));
  }

  void _toggleCheckbox(int index) async {
    setState(() {
      items[index].isChecked = !items[index].isChecked;
    });
    // Only play sound if item is being checked
    if (items[index].isChecked) {
      _playSound(items[index].soundPath);

      final completed = items.where((item) => item.isChecked).length;
      // Vary vibration based on how many items are checked
      if (completed >= 6) {
        await HapticFeedback.heavyImpact(); // Strong feedback
      } else if (completed >= 3) {
        await HapticFeedback.mediumImpact(); // Medium feedback
      } else {
        await HapticFeedback.lightImpact(); // Light feedback
      }
    } else {
      await HapticFeedback.selectionClick(); // Gentle vibration on uncheck
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.cover,
              alignment: Alignment.center,
              child: Image.asset('assets/images/background.jpg'),
            ),
          ),
          ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final scale = item.customScale ?? PixelArtConfig.globalScale;
              final displaySize = PixelArtConfig.basePixelSize * scale;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ClipRect(
                        child: SizedBox(
                          width: displaySize,
                          height: displaySize,
                          child: Image.asset(
                            item.imagePath,
                            fit: BoxFit.cover, // crop to fill space
                            filterQuality: FilterQuality.none,
                            isAntiAlias: false,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.label,
                          style: TextStyle(fontSize: 18, color: Colors.black),
                        ),
                      ),
                      SizedBox(width: 12),
                      Checkbox(
                        value: item.isChecked,
                        onChanged: (_) => _toggleCheckbox(index),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
