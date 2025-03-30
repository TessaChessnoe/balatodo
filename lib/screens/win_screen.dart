import 'package:flutter/material.dart';
import '../main.dart';

class WinScreen extends StatefulWidget {
  const WinScreen({super.key});

  @override
  State<WinScreen> createState() => _WinScreenState();
}

class _WinScreenState extends State<WinScreen> {
  @override
  void initState() {
    super.initState();
    musicPlayer.play('music/win_theme.wav', volume: 1.0);
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
        // <-- This is the key change - using Stack instead of direct children
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
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () async {
                      // Stop playing win theme
                      await musicPlayer.stop();
                      // Play main theme upon returning to checklist
                      await musicPlayer.play(
                        'music/main_theme.mp3',
                        volume: 0.8,
                        resume: true, // resume from previous point if available
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
                    child: const Text('Back to Checklist'),
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
