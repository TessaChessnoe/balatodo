import 'package:flutter/material.dart';

class StartScreen extends StatefulWidget {
  final void Function(int maxStakeIndex) onStart;

  const StartScreen({super.key, required this.onStart});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  int? _selectedIndex;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Choose your max stake for today',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Expanded(
              child: ListView.builder(
                itemCount: stakeLabels.length,
                itemBuilder: (context, index) {
                  final isSelected = _selectedIndex == index;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isSelected ? Colors.amber : Colors.grey[800],
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedIndex = index;
                        });
                      },
                      child: Text(
                        stakeLabels[index],
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed:
                  _selectedIndex != null
                      ? () => widget.onStart(_selectedIndex!)
                      : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
              ),
              child: const Text('Start', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
