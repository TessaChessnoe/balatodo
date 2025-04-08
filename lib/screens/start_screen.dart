import 'package:flutter/material.dart';
import 'package:temp/widgets/mute_button.dart';
// To access global musicPlayer
import '../main.dart';
// To access sound service
import '../core/sound_service.dart';

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
  // Repsents selected maximum stake
  int _selectedIndex = 0;
  // Init start screen state with music
  @override
  void initState() {
    super.initState();
    musicPlayer.play(
      'music/start_theme.mp3',
      volume: 0.8,
      resume: true,
      loop: true,
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //       backgroundColor: Colors.black, // Dark background for better contrast
      //       body:
      //         Center(
      //           mainAxisSize: MainAxisSize.min, // ⬅️ Only take up what's needed
      //           mainAxisAlignment: MainAxisAlignment.center,
      //           child: Column(
      //             crossAxisAlignment: CrossAxisAlignment.center,
      //             children: [
      //               // Title text explaining what the user should do
      //               const Text(
      //                 'Select highest stake for your list.',
      //                 style: TextStyle(
      //                   color: Colors.white,
      //                   fontSize: 24,
      //                   fontWeight: FontWeight.bold,
      //                 ),
      //                 textAlign: TextAlign.center,
      //               ),
      //               const SizedBox(height: 30), // Spacer between title and stake grid
      //               // The main content - a grid of stake options
      //               Expanded(
      //                 child: GridView.count(
      //                   crossAxisCount: 4, // Creates a grid with 4 columns
      //                   crossAxisSpacing: 16, // Horizontal space between items
      //                   mainAxisSpacing: 16, // Vertical space between items
      //                   children: List.generate(stakeImages.length, (index) {
      //                     // Determine if this stake is currently selected
      //                     final isSelected = index == _selectedIndex;

      //                     return GestureDetector(
      //                       onTap: () async {
      //                         await SoundService.play('assets/sounds/chip_click.wav');
      //                         setState(() {
      //                           _selectedIndex = index; // Update selection when tapped
      //                         });
      //                       },
      //                       child: Container(
      //                         decoration: BoxDecoration(
      //                           shape: BoxShape.circle,
      //                           // Add white border for selected stake only
      //                           border:
      //                               isSelected
      //                                   ? Border.all(color: Colors.white, width: 3)
      //                                   : null,
      //                         ),
      //                         child: Padding(
      //                           padding: const EdgeInsets.all(8.0),
      //                           // Show stake image in full color with no filters
      //                           child: Image.asset(
      //                             stakeImages[index],
      //                             fit: BoxFit.contain,
      //                           ),
      //                         ),
      //                       ),
      //                     );
      //                   }),
      //                 ),
      //               ),
      //             ],
      //           ),
      //         ),
      //             Row(
      //               // Space start and music toggle buttons evenly
      //               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      //               crossAxisAlignment: CrossAxisAlignment.center,
      //               children: [
      //                 const SizedBox(height: 20), // Spacer between grid and button
      //                 // Start button - always enabled since we have a default selection
      //                 ElevatedButton(
      //                   onPressed: () {
      //                     musicPlayer.pause();
      //                     widget.onStart(_selectedIndex);
      //                   },
      //                   style: ElevatedButton.styleFrom(
      //                     backgroundColor:
      //                         Colors.green, // Green color for the action button
      //                     padding: const EdgeInsets.symmetric(
      //                       horizontal: 40,
      //                       vertical: 16,
      //                     ),
      //                   ),
      //                   child: const Icon(
      //                     Icons.start_rounded,
      //                     color: Colors.white,
      //                     size: 45,
      //                   ),
      //                 ),
      //                 MuteButton(),
      //               ],
      //             ),
      //           ],
      //         ),
      //       ),
      //     );
      //   }
      // }
      body: Stack(
        children: [
          // 1. Background image
          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.cover,
              child: Image.asset('assets/images/background.jpg'),
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
                      'Select highest stake for your list.',
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
                                  stakeImages[index],
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
