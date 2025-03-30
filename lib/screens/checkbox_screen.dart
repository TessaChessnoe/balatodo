import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// To access global musicPlayer
import '../main.dart';
import '../core/storage_service.dart';

// Required to navigate to other screens
import 'win_screen.dart';
import 'start_screen.dart';

// Import every required model ONCE, do not aggregate with ../models/
import '../models/checkbox_item.dart';
import '../models/subtask.dart';
import '../models/pixel_art_config.dart';

class CheckboxScreen extends StatefulWidget {
  final int maxStakeIndex;
  const CheckboxScreen({super.key, required this.maxStakeIndex});

  @override
  _CheckboxScreenState createState() => _CheckboxScreenState();
}

class _CheckboxScreenState extends State<CheckboxScreen> {
  // Flag to enable reset for debugging

  static const bool debugMode = true; // Set to false for testers
  final AudioPlayer _audioPlayer = AudioPlayer();
  // Removed lazy loading to prevent invalid vals before set state
  List<CheckboxItem> items = [];

  @override
  void initState() {
    super.initState();
    // Replace loading saved subtasks w/ loading entire checkbox item's state
    _initializeCheckboxItems();
    // Resume when it was the last track played
    if (musicPlayer.currentTrack == 'music/main_theme.mp3') {
      musicPlayer.resume();
    } else {
      musicPlayer.play(
        'music/main_theme.mp3',
        volume: 0.8,
        resume: true,
        loop: true,
      );
    }
  }

  Future<void> _initializeCheckboxItems() async {
    final loaded = await StorageService.loadCheckboxItems();
    // Create set of stakes with empty subtasks if other list exists
    final fallback = allItems.sublist(0, widget.maxStakeIndex + 1);
    setState(() {
      if (loaded.isNotEmpty) {
        items = loaded;
      } else {
        // Load checkbox items if there are any
        items = loaded.isEmpty ? fallback : loaded;
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  // Reset method for debugging
  Future<void> _resetApp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear all saved data
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder:
              (context) => StartScreen(
                onStart: (index) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => CheckboxScreen(maxStakeIndex: index),
                    ),
                  );
                },
              ),
        ),
        (route) => false, // Remove all previous routes
      );
    }
  }

  Future<void> _resetSubtasksForStake(int stakeIndex) async {
    setState(() {
      items[stakeIndex].subtasks.clear();
      items[stakeIndex].isChecked = false;
    });
    await StorageService.saveCheckboxItems(items);
  }

  // SUBTASK MANAGEMENT
  void _deleteSubtask(int stakeIndex, int subtaskIndex) async {
    setState(() {
      items[stakeIndex].subtasks.removeAt(subtaskIndex);
      // Uncheck stake if it was checked
      if (items[stakeIndex].isChecked) {
        items[stakeIndex].isChecked = false;
        _cascadeUncheck(stakeIndex);
      }
    });
    await _playRemoveSubtaskSound();
    await StorageService.saveCheckboxItems(items);
  }

  void _cascadeUncheck(int fromIndex) {
    setState(() {
      for (int i = fromIndex; i < items.length; i++) {
        items[i].isChecked = false;
      }
    });
  }

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

  Future<void> _playAddSubtaskSound() async {
    await _audioPlayer.play(AssetSource('sounds/subtask_add.wav'));
  }

  Future<void> _playRemoveSubtaskSound() async {
    await _audioPlayer.play(AssetSource('sounds/subtask_remove.wav'));
  }

  void _checkWinCondition() async {
    final allChecked = items.every((item) => item.isChecked);
    if (allChecked && mounted) {
      await musicPlayer.pause(); // Ensure clean transition
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const WinScreen()),
      );
    }
  }

  void _playSound(String path) async {
    final relativePath = path.replaceFirst('assets/', '');
    await _audioPlayer.play(AssetSource(relativePath));
  }

  void _toggleCheckbox(int index) async {
    if (!_canCheckStake(index)) return;
    setState(() {
      // If unchecking, cascade uncheck all higher stakes
      if (items[index].isChecked) {
        _cascadeUncheck(index);
      } else {
        items[index].isChecked = true;
      }
    });
    // Only play sound if item is being checked
    if (items[index].isChecked) {
      _playSound(items[index].soundPath);
      _checkWinCondition();
    } else {
      await HapticFeedback.selectionClick();
    } // Gentle vibration on uncheck
    await StorageService.saveCheckboxItems(items);
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
    return items[index].subtasks.isEmpty ||
        items[index].subtasks.every((subtask) => subtask.isCompleted);
  }

  // Add these new methods for subtasks
  void _toggleSubtask(int stakeIndex, int subtaskIndex) async {
    setState(() {
      items[stakeIndex].subtasks[subtaskIndex].isCompleted =
          !items[stakeIndex].subtasks[subtaskIndex].isCompleted;
    });
    await StorageService.saveCheckboxItems(items);
    _playSound('assets/sounds/subtask_done.wav');
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
                onPressed: () async {
                  if (controller.text.trim().isNotEmpty) {
                    _addSubtask(stakeIndex, controller.text);
                    await _playAddSubtaskSound();
                  }
                  if (mounted) {
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }

  void _addSubtask(int stakeIndex, String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      items[stakeIndex].subtasks.add(Subtask(text));
    });
    await _playAddSubtaskSound();
    await StorageService.saveCheckboxItems(items);
  }

  // Update build method to show subtasks
  @override
  Widget build(BuildContext context) {
    final whiteWithOpacity = Colors.white.withAlpha(
      204,
    ); // ~80% opacity (255 * 0.8)

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

          // Main content column
          Column(
            children: [
              // Stake list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 16,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return _buildStakeRow(index, whiteWithOpacity);
                  },
                ),
              ),

              // Debug reset button (bottom center)
              if (debugMode)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Center(
                    child: ElevatedButton(
                      onPressed: _resetApp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        'RESET TO STAKE SELECT',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStakeRow(int index, Color backgroundWhite) {
    final item = items[index];
    final scale = item.customScale ?? PixelArtConfig.globalScale;
    final displaySize = PixelArtConfig.basePixelSize * scale;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundWhite,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Stake header row
            Row(
              children: [
                // Stake image
                ClipRect(
                  child: SizedBox(
                    width: displaySize,
                    height: displaySize,
                    child: Image.asset(item.imagePath, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 12),

                // Stake label
                Expanded(
                  child: Text(item.label, style: const TextStyle(fontSize: 18)),
                ),

                // Reset subtasks button for this stake
                IconButton(
                  icon: const Icon(Icons.restart_alt, color: Colors.blue),
                  onPressed: () => _resetSubtasksForStake(index),
                ),

                // Main checkbox
                Checkbox(
                  value: item.isChecked,
                  onChanged:
                      _canCheckStake(index)
                          ? (_) => _toggleCheckbox(index)
                          : null,
                ),
              ],
            ),

            // Subtasks list
            Column(
              children: [
                ...item.subtasks.map(
                  (subtask) => ListTile(
                    title: Text(
                      subtask.text,
                      style: TextStyle(
                        fontSize: 16,
                        decoration:
                            subtask.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed:
                          () => _deleteSubtask(
                            index,
                            item.subtasks.indexOf(subtask),
                          ),
                    ),
                    onTap:
                        () => _toggleSubtask(
                          index,
                          item.subtasks.indexOf(subtask),
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
  }
}
