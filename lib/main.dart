import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(MyApp());
}

// Data model for a checkbox item
class CheckboxItem {
  String label; // Text label to display
  bool isChecked; // Current checked state
  String soundPath; // Filepath for 'check' sound
  String imagePath; // Image for task set
  CheckboxItem({
    required this.label,
    required this.soundPath,
    required this.imagePath,
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
      imagePath: 'black-stake.png',
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
          return CheckboxListTile(
            // Each checkbox shows an image + label
            title: Row(
              children: [
                Image.asset(
                  'assets/my_image.png', // Replace with your image
                  width: 32,
                  height: 32,
                ),
                SizedBox(width: 10),
                Expanded(child: Text(items[index].label)),
              ],
            ),
            value: items[index].isChecked, // Current checked state
            onChanged: (_) => _toggleCheckbox(index), // Toggle on tap
          );
        },
      ),
    );
  }
}
