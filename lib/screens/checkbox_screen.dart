import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// To access global musicPlayer
import '../main.dart';
import '../core/storage_service.dart';
import '../core/sound_service.dart';

// Required to navigate to other screens
import 'win_screen.dart';
import 'start_screen.dart';

// Import every required model ONCE, do not aggregate with ../models/
import '../models/checkbox_item.dart';
import '../models/subtask.dart';

// Build context for row widgets
import '../widgets/stake_tile.dart';
import '../widgets/subtask_list.dart';

// Used for importing tasks from text file
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class CheckboxScreen extends StatefulWidget {
  final int maxStakeIndex;
  const CheckboxScreen({super.key, required this.maxStakeIndex});

  @override
  _CheckboxScreenState createState() => _CheckboxScreenState();
}

class _CheckboxScreenState extends State<CheckboxScreen> {
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
    super.dispose();
  }

  // Reset method for debugging
  Future<void> _resetApp() async {
    final prefs = await SharedPreferences.getInstance();
    // Return to start screen after resetting app state
    await prefs.setBool('returnToStart', true); // set flag BEFORE clearing
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

  Future<List<CheckboxItem>> importTasksFromText(
    String rawText,
    List<CheckboxItem> items,
  ) async {
    print("📥 Starting task import...");
    final lines = rawText.split('\n');
    int? currentStakeIndex;

    for (final line in lines) {
      final trimmed = line.trim();
      print("🔍 Processing line: '$trimmed'");

      // Detect stake markers like <1>, <2>, etc.
      if (trimmed.startsWith('<') && trimmed.endsWith('>')) {
        final numStr = trimmed.substring(1, trimmed.length - 1);
        final parsed = int.tryParse(numStr);

        if (parsed == null) {
          print("❌ Skipping invalid stake tag: <$numStr>");
          currentStakeIndex = null;
        } else if (parsed < 1 || parsed > items.length) {
          print("⚠️ Stake <$parsed> out of range. Ignoring.");
          currentStakeIndex = null;
        } else {
          currentStakeIndex = parsed - 1; // Adjust for 0-based indexing
          print(
            "✅ Switched to stake index $currentStakeIndex (${items[currentStakeIndex].label})",
          );
        }
      } else if (trimmed.isNotEmpty && currentStakeIndex != null) {
        // Add a subtask to the current stake
        items[currentStakeIndex].subtasks.add(Subtask(trimmed));
        print("➕ Added subtask to stake $currentStakeIndex: '$trimmed'");
      } else if (trimmed.isNotEmpty) {
        print("⚠️ Skipping orphan task (no active stake): '$trimmed'");
      }
    }

    print("✅ Finished importing tasks.");
    return items;
  }

  // SUBTASK MANAGEMENT
  void _addSubtask(int stakeIndex, String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      items[stakeIndex].subtasks.add(Subtask(text));
    });
    await SoundService.play('assets/sounds/subtask_add.wav');
    await StorageService.saveCheckboxItems(items);
  }

  void _deleteSubtask(int stakeIndex, int subtaskIndex) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Task'),
            content: const Text('Are you sure you want to delete this task?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('DELETE'),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    setState(() {
      items[stakeIndex].subtasks.removeAt(subtaskIndex);
      // Uncheck stake if a subtask is removed
      if (items[stakeIndex].isChecked) {
        items[stakeIndex].isChecked = false;
        _cascadeUncheck(stakeIndex);
      }
    });

    await SoundService.play('assets/sounds/subtask_remove.wav');
    await StorageService.saveCheckboxItems(items);
  }

  void _toggleSubtask(int stakeIndex, int subtaskIndex) async {
    final subtask = items[stakeIndex].subtasks[subtaskIndex];
    final wasCompleted = subtask.isCompleted;

    // Toggle subtask completion state
    setState(() {
      subtask.isCompleted = !subtask.isCompleted;
    });

    // Tracks all currently completed subtasks
    final allNowCompleted = items[stakeIndex].subtasks.every(
      (sub) => sub.isCompleted,
    );

    if (!wasCompleted && allNowCompleted) {
      // Play crumble sound for last subtask in stake
      await SoundService.play('assets/sounds/chip_crumble.wav');
      // Otherwise chip cut sounds play
    } else {
      // Concatenate absolute path so filenames can be used in pool
      final baseDir = 'assets/sounds/';
      List<String> soundPool = [
        'chip_cut1.wav',
        'chip_cut2.wav',
        'chip_cut3.wav',
        'chip_cut4.wav',
        'cut1.wav',
        'cut2.wav',
        'cut3.wav',
        'cut4.wav',
      ];
      soundPool = soundPool.map((filename) => "$baseDir$filename").toList();
      await SoundService.playRandom(soundPool);
    }

    await StorageService.saveCheckboxItems(items);
  }

  void _showAddSubtaskDialog(int stakeIndex) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Task'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'Enter task'),
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
                    await SoundService.play('assets/sounds/subtask_add.wav');
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

  // Checklist Logic
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
      await SoundService.play(items[index].soundPath);
      _checkWinCondition();
    }
    await StorageService.saveCheckboxItems(items);
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

  // Navigate to win screen
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

              // Return to stake widget
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: const Text('Reset App'),
                                content: const Text(
                                  'This will reset all progress and return to stake selection. Continue?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed:
                                        () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed:
                                        () => Navigator.pop(context, true),
                                    child: const Text('RESET'),
                                  ),
                                ],
                              ),
                        );
                        // Only runs if 'RESET' is pressed
                        if (confirm == true) {
                          await _resetApp();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        'RESET TASKS',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        print("📁 Import button pressed");
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['txt'],
                        );
                        // Read file contents
                        if (result != null &&
                            result.files.single.path != null) {
                          // Content must be declared in same scope as updatedItems
                          String content = '';
                          try {
                            final path = result.files.single.path!;
                            print("📄 Selected file path: $path");
                            final content = await File(path).readAsString();
                            // Clear existing subtasks before importing
                            for (var item in items) {
                              item.subtasks.clear();
                            }
                            // Update checklist items with contents from imported file
                            final updatedItems = await importTasksFromText(
                              content,
                              items,
                            );
                            // Update checklist with new tasks
                            setState(() => items = updatedItems);
                            // Save loaded tasks in persistent storage
                            await StorageService.saveCheckboxItems(items);
                            // Pop-up message for SUCCESSFUL import
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Tasks imported successfully.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            // Pop-up message for FAILED import
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to import tasks: $e'),
                                duration: const Duration(seconds: 15),
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        'IMPORT TASKS',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ], // Row children
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
    return StakeTile(
      item: item,
      index: index,
      backgroundWhite: backgroundWhite,
      onResetSubtasks: () async {
        await SoundService.play('assets/sounds/subtask_reset_LOUD.wav');
        _resetSubtasksForStake(index);
      },
      onToggle: _canCheckStake(index) ? (_) => _toggleCheckbox(index) : null,
      subtaskList: SubtaskList(
        subtasks: item.subtasks,
        onDelete: (subtaskIndex) => _deleteSubtask(index, subtaskIndex),
        onToggle: (subtaskIndex) => _toggleSubtask(index, subtaskIndex),
        onAdd: () => _showAddSubtaskDialog(index),
      ),
    );
  }
}
