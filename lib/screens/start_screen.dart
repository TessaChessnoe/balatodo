import 'package:flutter/material.dart';
import '/widgets/mute_button.dart';
// To access global musicPlayer
import '../main.dart';
// To access sound service
import '../core/sound_service.dart';
// Required to load stake variant images
import 'package:shared_preferences/shared_preferences.dart';
// Used for loading key from checkbox items json
import 'dart:convert';
//Shared access to stake data
import '../core/stake_data.dart';

/// StartScreen is the initial screen where users select their maximum stake level
/// before starting the game. It takes a callback function onStart that is called
/// with the selected stake index when the user presses the Start button.
class StartScreen extends StatefulWidget {
  final void Function(int maxStakeIndex) onStart;

  const StartScreen({super.key, required this.onStart});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  // Repsents selected maximum stake
  int _selectedIndex = 0;
  // Init start screen state with music
  @override
  void initState() {
    super.initState();
    // Display last used variant for each stake
    _loadVariantIndexes();
    musicPlayer.play(
      'music/start_theme.mp3',
      volume: 0.8,
      resume: true,
      loop: true,
    );
  }

  Future<void> _loadVariantIndexes() async {
    final prefs = await SharedPreferences.getInstance();
    final rawJson = prefs.getString('variant_indexes');
    if (rawJson == null) return;

    final List<dynamic> decoded = jsonDecode(rawJson);
    setState(() {
      variantIndexes =
          decoded.map<int>((json) {
            return json['imageIndex'] ?? 0;
          }).toList();
    });
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
    'assets/images/white-stake10X.png',
    'assets/images/red-stake10X.png',
    'assets/images/green-stake10X.png',
    'assets/images/black-stake10X.png',
    'assets/images/blue-stake10X.png',
    'assets/images/purple-stake10X.png',
    'assets/images/orange-stake10X.png',
    'assets/images/gold-stake10X.png',
  ];

  // Initialize variant list for loading
  List<int> variantIndexes = List.filled(8, 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Background image
          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.cover,
              child: Image.asset('assets/images/start_background.png'),
            ),
          ),

          // 2. Foreground UI (layout column)
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Spacer(flex: 2),

              // 3. Centered Text + Grid
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Select highest stake to create your to-do list.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 280,
                      width: MediaQuery.of(context).size.width * 0.85,
                      child: GridView.count(
                        crossAxisCount: 4,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        physics: const NeverScrollableScrollPhysics(),
                        children: List.generate(stakeImages.length, (index) {
                          final isSelected = index == _selectedIndex;
                          return GestureDetector(
                            onTap: () async {
                              await SoundService.play(
                                'assets/sounds/chip_click.wav',
                              );
                              setState(() => _selectedIndex = index);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border:
                                    isSelected
                                        ? Border.all(
                                          color: Colors.white,
                                          width: 3,
                                        )
                                        : null,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Image.asset(
                                  index < variantIndexes.length
                                      ? stakeTemplates[index]
                                          .imageVariants[variantIndexes[index]]
                                      : stakeImages[index], // fallback to default
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 1),

              // 4. Start + Mute Buttons
              Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        musicPlayer.pause();
                        widget.onStart(_selectedIndex);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 16,
                        ),
                      ),
                      child: const Icon(
                        Icons.start_rounded,
                        color: Colors.white,
                        size: 45,
                      ),
                    ),
                    const MuteButton(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
