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
import '../widgets/mute_button.dart';

// Used for importing tasks from text file
import 'package:file_picker/file_picker.dart';
import 'dart:io';

// Required to export tasks to file
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

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

  // Import/Export Tasks
  Future<void> _resetSubtasksForStake(int stakeIndex) async {
    setState(() {
      items[stakeIndex].subtasks.clear();
      items[stakeIndex].isChecked = false;
    });
    await StorageService.saveCheckboxItems(items);
  }

  Future<List<CheckboxItem>> _parseTasksFromText(
    String rawText,
    List<CheckboxItem> items,
  ) async {
    final lines = rawText.split('\n');
    int? currentStakeIndex;

    // DEBUG CODE: verify parse func is running
    print("📥 Parsing text with ${lines.length} lines");

    for (final line in lines) {
      final trimmed = line.trim();

      // Parse stake headers like <1> [x] or <2>
      if (trimmed.startsWith('<') && trimmed.contains('>')) {
        final angleBracketContent = trimmed.substring(1, trimmed.indexOf('>'));
        final index = int.tryParse(angleBracketContent);
        final isChecked = trimmed.contains('[x]');

        if (index != null && index > 0 && index <= items.length) {
          print("➡️ Found stake header: $trimmed");
          currentStakeIndex = index - 1;
          items[currentStakeIndex].isChecked = isChecked;
        } else {
          currentStakeIndex = null;
        }

        // Parse subtasks like "Take out trash [x]"
      } else if (trimmed.isNotEmpty && currentStakeIndex != null) {
        print("📝 Found subtask: $trimmed");
        final isDone = trimmed.endsWith('[x]');
        final cleanText = trimmed.replaceAll(RegExp(r'\s*\[.\]$'), '').trim();

        items[currentStakeIndex].subtasks.add(
          Subtask(cleanText, isCompleted: isDone),
        );
      }
    }
    return items;
  }

  Future<void> importTasksFromFile(
    BuildContext context,
    List<CheckboxItem> items,
    void Function(List<CheckboxItem>) updateItemsCallback,
  ) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        print("📄 Selected file path: $path");

        final content = await File(path).readAsString();
        // DEBUG CODE
        print("📄 File content:\n$content");

        // Clear all existing subtasks
        _clearAllSubtasks();

        // Parse new subtasks from text
        final updatedItems = await _parseTasksFromText(content, items);

        // Update app state
        updateItemsCallback(updatedItems);
        await StorageService.saveCheckboxItems(updatedItems);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Tasks imported successfully')),
          );
        }
      } else {
        print("⚠️ No file selected or path was null.");
      }
    } catch (e) {
      print("❌ Import failed: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Failed to import tasks: $e')));
      }
    }
  }

  // Generates summary of checklist data when sharing using supported apps
  String _generateExportMetadata(List<CheckboxItem> items) {
    final now = DateTime.now();
    final completedStakes = items.where((i) => i.isChecked).length;
    final totalStakes = items.length;
    String _twoDigits(int n) => n.toString().padLeft(2, '0');

    int completedTasks = 0;
    int totalTasks = 0;
    for (final item in items) {
      for (final subtask in item.subtasks) {
        totalTasks++;
        if (subtask.isCompleted) completedTasks++;
      }
    }

    final timestamp =
        "${_twoDigits(now.month)}/${_twoDigits(now.day)}/${now.year} @ "
        "${_twoDigits(now.hour)}:${_twoDigits(now.minute)}";

    return '''
  Checklist Export – $timestamp
  ✔️ $completedStakes of $totalStakes stakes completed
  📋 $totalTasks subtasks total
  ✅ $completedTasks subtasks completed
  '''.trim();
  }

  Future<void> exportTasksToFile(List<CheckboxItem> items) async {
    final buffer = StringBuffer();
    for (int index = 0; index < items.length; index++) {
      final item = items[index];
      // Write index in angle brackets with [x] if stake is checked
      buffer.writeln('<${index + 1}> ${item.isChecked ? "[x]" : "[ ]"}');
      for (final subtask in item.subtasks) {
        // Write task text with [x] for checked subtasks
        buffer.writeln(
          '${subtask.text} ${subtask.isCompleted ? "[x]" : "[ ]"}',
        );
      }
    }
    final exportText = buffer.toString();

    try {
      // Get app-safe directory
      final dir = await getApplicationDocumentsDirectory();

      final now = DateTime.now();
      // Helper method for date formatting
      String _twoDigits(int n) => n.toString().padLeft(2, '0');
      final timestamp =
          '${now.year}-${_twoDigits(now.month)}-${_twoDigits(now.day)}_${_twoDigits(now.hour)}-${_twoDigits(now.minute)}';

      // Include date & time in exported filename
      final filename = 'checklist_export_$timestamp.txt';
      final path = '${dir.path}/$filename';
      final file = File(path);

      // Write to internal storage
      await file.writeAsString(exportText);
      print("✅ Tasks exported to: $path");

      final summary = _generateExportMetadata(items);
      // Share if on Android
      if (defaultTargetPlatform == TargetPlatform.android) {
        // Open Android's 'share to' menu
        await Share.shareXFiles([XFile(path)], text: summary);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('✅ Tasks exported to: $path')));
        }
      }
    } catch (e) {
      print("❌ Export failed: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Export failed: $e')));
      }
    }
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

  Future<void> _clearAllSubtasks() async {
    setState(() {
      // Clear and uncheck all items
      for (var item in items) {
        item.subtasks.clear();
        item.isChecked = false;
      }
    });
    // Save empty items list in shared prefs
    await StorageService.saveCheckboxItems(items);
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

              // Button Tray for: Delete tasks, Import & Export
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // DELETE ALL button
                    ElevatedButton(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: const Text('DELETE ALL TASKS'),
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
                                    child: const Text('DELETE'),
                                  ),
                                ],
                              ),
                        );
                        // Only runs if 'DELETE' is pressed
                        if (confirm == true) {
                          _clearAllSubtasks();
                          await _resetApp();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          // For somewhat rounded square
                          borderRadius: BorderRadius.circular(4),
                        ),
                        backgroundColor: Colors.red,
                        // Tighten padding since labels have been removed
                        padding: const EdgeInsets.all(20),
                      ),
                      child: const Icon(
                        Icons.delete_forever_sharp,
                        color: Colors.white,
                        size: 45,
                      ),
                    ),

                    // Import task from file button
                    ElevatedButton(
                      onPressed: () async {
                        print("📁 Import button pressed");
                        await importTasksFromFile(context, items, (updated) {
                          setState(() => items = updated);
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.all(20),
                      ),
                      child: const Icon(
                        Icons.upload_file,
                        color: Colors.white,
                        size: 45,
                      ),
                    ),
                    // Export tasks button
                    ElevatedButton(
                      onPressed: () {
                        print("📁 Export button pressed");
                        exportTasksToFile(items);
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          // For somewhat rounded square
                          borderRadius: BorderRadius.circular(4),
                        ),
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.all(20),
                      ),
                      child: const Icon(
                        Icons.download,
                        color: Colors.white,
                        size: 45,
                      ),
                    ),
                    const MuteButton(alignEnd: true),
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
        final confirmed = await showDialog<bool>(
          // Use context from stakeTile to build dialog overlay
          context: context,
          // Pass builder by reference
          // we dont want dialog widget to be built at runtime
          builder:
              (context) => AlertDialog(
                title: const Text('Reset Subtasks for Stake'),
                content: const Text(
                  'Are you sure you want to reset all subtasks for this stake?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text("RESET Tasks for Stake"),
                  ),
                ],
              ),
        );
        if (confirmed == true) {
          _resetSubtasksForStake(index);
          SoundService.play('assets/sounds/subtask_reset_LOUD.wav');
        }
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
