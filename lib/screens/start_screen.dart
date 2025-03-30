import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

// To access global musicPlayer
import '../main.dart';

/// StartScreen is the initial screen where users select their maximum stake level
/// before starting the game. It takes a callback function [onStart] that is called
/// with the selected stake index when the user presses the Start button.
class StartScreen extends StatefulWidget {
  final void Function(int maxStakeIndex) onStart;

  const StartScreen({super.key, required this.onStart});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  // Declare Audio player obj for tap sound effects
  final AudioPlayer _audioPlayer = AudioPlayer();
  int _selectedIndex = 0;

  // Init start screen state with music
  @override
  void initState() {
    super.initState();
    musicPlayer.play('music/start_theme.mp3', volume: 0.8, resume: true);
  }

  // Labels for each stake level (available for future use if needed)
  final List<String> stakeLabels = [
    'White Stake',
    'Red Stake',
    'Green Stake',
    'Black Stake',
    'Blue Stake',
    'Purple Stake',
    'Orange Stake',
    'Gold Stake',
  ];

  // Image paths for each stake level's visual representation
  final List<String> stakeImages = [
    'assets/images/white-stake.png',
    'assets/images/red-stake.png',
    'assets/images/green-stake.png',
    'assets/images/black-stake.png',
    'assets/images/blue-stake.png',
    'assets/images/purple-stake.png',
    'assets/images/orange-stake.png',
    'assets/images/gold-stake.png',
  ];

  Future<void> _playSelectStakeSound() async {
    await _audioPlayer.play(AssetSource('sounds/chip_click.wav'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark background for better contrast
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Title text explaining what the user should do
            const Text(
              'Choose your max stake for today',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30), // Spacer between title and stake grid
            // The main content - a grid of stake options
            Expanded(
              child: GridView.count(
                crossAxisCount: 4, // Creates a grid with 4 columns
                crossAxisSpacing: 16, // Horizontal space between items
                mainAxisSpacing: 16, // Vertical space between items
                children: List.generate(stakeImages.length, (index) {
                  // Determine if this stake is currently selected
                  final isSelected = index == _selectedIndex;

                  return GestureDetector(
                    onTap: () {
                      _playSelectStakeSound();
                      setState(() {
                        _selectedIndex = index; // Update selection when tapped
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        // Add white border for selected stake only
                        border:
                            isSelected
                                ? Border.all(color: Colors.white, width: 3)
                                : null,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        // Show stake image in full color with no filters
                        child: Image.asset(
                          stakeImages[index],
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 20), // Spacer between grid and button
            // Start button - always enabled since we have a default selection
            ElevatedButton(
              onPressed: () {
                musicPlayer.pause();
                widget.onStart(_selectedIndex);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.green, // Green color for the action button
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
              ),
              child: const Text('Start', style: TextStyle(fontSize: 18)),
            ),
          ], // Children
        ),
      ),
    );
  }
}
