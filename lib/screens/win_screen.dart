import 'package:flutter/material.dart';
import '../main.dart';
// Allows us to set preferred screen when app is reopened
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/mute_button.dart';

class WinScreen extends StatefulWidget {
  const WinScreen({super.key});

  @override
  State<WinScreen> createState() => _WinScreenState();
}

class _WinScreenState extends State<WinScreen> {
  @override
  void initState() {
    super.initState();
    musicPlayer.play('music/win_theme.mp3', volume: 0.8, loop: false);
  }

  @override
  void dispose() async {
    // Allows user to skip fanfare by hitting 'back to stakes'
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background image (same as main screen)
          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.cover,
              child: Image.asset('assets/images/background.jpg'),
            ),
          ),
          // Congratulations message after winning!
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Congratulations!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'You finished everything!',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Return to checklist button
                      ElevatedButton(
                        onPressed: () async {
                          // Stop playing win theme
                          await musicPlayer.stop();
                          // When app is reopened, go to start screen
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('returnToStart', true);
                          // Play main theme upon returning to checklist
                          await musicPlayer.play(
                            'music/main_theme.mp3',
                            volume: 0.8,
                            resume: true,
                            loop: true,
                          );
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 16,
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 45,
                        ),
                      ),
                      // Mute button
                      const MuteButton(alignEnd: true),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
