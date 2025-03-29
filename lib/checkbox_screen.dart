import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'win_screen.dart';
import 'models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // For JSON handling

class CheckboxScreen extends StatefulWidget {
  final int maxStakeIndex;
  const CheckboxScreen({super.key, required this.maxStakeIndex});

  @override
  _CheckboxScreenState createState() => _CheckboxScreenState();
}

class _CheckboxScreenState extends State<CheckboxScreen> {
  final List<CheckboxItem> allItems = [
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
  late final List<CheckboxItem> items;

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    items = allItems.sublist(0, widget.maxStakeIndex + 1);
    _loadSubtasks(); // Load saved subtasks
  }

  Future<void> _loadSubtasks() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSubtasks = prefs.getString('subtasks');
    if (savedSubtasks != null) {
      final decoded = jsonDecode(savedSubtasks) as List;
      setState(() {
        for (int i = 0; i < items.length; i++) {
          if (i < decoded.length) {
            items[i].subtasks =
                (decoded[i] as List)
                    .map(
                      (s) => Subtask(s['text'], isCompleted: s['isCompleted']),
                    )
                    .toList();
          }
        }
      });
    }
  }

  Future<void> _saveSubtasks() async {
    final prefs = await SharedPreferences.getInstance();
    final subtasksJson =
        items
            .map(
              (item) =>
                  item.subtasks
                      .map(
                        (s) => {'text': s.text, 'isCompleted': s.isCompleted},
                      )
                      .toList(),
            )
            .toList();
    await prefs.setString('subtasks', jsonEncode(subtasksJson));
  }

  void _checkWinCondition() {
    final allChecked = items.every((item) => item.isChecked);
    if (allChecked) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const WinScreen()),
      );
      //_playSound('assets/sounds/final-mult.wav'); // Or your win sound
    }
  }

  void _playSound(String path) async {
    final relativePath = path.replaceFirst('assets/', '');
    await _audioPlayer.play(AssetSource(relativePath));
  }

  void _toggleCheckbox(int index) async {
    if (!_canCheckStake(index)) return;
    setState(() {
      items[index].isChecked = !items[index].isChecked;
    });
    // Only play sound if item is being checked
    if (items[index].isChecked) {
      _playSound(items[index].soundPath);
      _checkWinCondition();
    } else {
      await HapticFeedback.selectionClick();
    } // Gentle vibration on uncheck
    await _saveSubtasks();
    final completed = items.where((item) => item.isChecked).length;
    // Vary vibration based on how many items are checked
    if (completed >= 6) {
      await HapticFeedback.heavyImpact(); // Strong feedback
    } else if (completed >= 3) {
      await HapticFeedback.mediumImpact(); // Medium feedback
    } else {
      await HapticFeedback.lightImpact(); // Light feedback
    }
  }

  bool _canCheckStake(int index) {
    // Check previous stakes
    for (int i = 0; i < index; i++) {
      if (!items[i].isChecked) return false;
    }
    // Check subtasks
    return items[index].subtasks.every((subtask) => subtask.isCompleted);
  }

  // Add these new methods for subtasks
  void _toggleSubtask(int stakeIndex, int subtaskIndex) async {
    setState(() {
      items[stakeIndex].subtasks[subtaskIndex].isCompleted =
          !items[stakeIndex].subtasks[subtaskIndex].isCompleted;
    });
    await _saveSubtasks();
    _playSound('assets/sounds/subtask_done.wav');
  }

  void _addSubtask(int stakeIndex, String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      items[stakeIndex].subtasks.add(Subtask(text));
    });
    _saveSubtasks();
  }

  // Update build method to show subtasks
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.cover,
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
                  color: Colors.white.withValues(),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      // Stake row
                      Row(
                        children: [
                          ClipRect(
                            child: SizedBox(
                              width: displaySize,
                              height: displaySize,
                              child: Image.asset(
                                item.imagePath,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.label,
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                          Checkbox(
                            value: item.isChecked,
                            onChanged:
                                _canCheckStake(index)
                                    ? (_) => _toggleCheckbox(index)
                                    : null,
                          ),
                        ],
                      ),

                      // Subtasks
                      Column(
                        children: [
                          ...item.subtasks.map(
                            (subtask) => GestureDetector(
                              onTap:
                                  () => _toggleSubtask(
                                    index,
                                    item.subtasks.indexOf(subtask),
                                  ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Text(
                                  subtask.text,
                                  style: TextStyle(
                                    fontSize: 16,
                                    decoration:
                                        subtask.isCompleted
                                            ? TextDecoration.lineThrough
                                            : null,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Add subtask button
                          TextButton(
                            onPressed: () => _showAddSubtaskDialog(index),
                            child: const Text('+ Add Subtask'),
                          ),
                        ],
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

  void _showAddSubtaskDialog(int stakeIndex) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Subtask'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'Enter subtask'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  _addSubtask(stakeIndex, controller.text);
                  Navigator.pop(context);
                },
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }
}
  // @override
  // void dispose() {
  //   _audioPlayer.dispose();
  //   super.dispose();
