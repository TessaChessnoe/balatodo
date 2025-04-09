import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/sound_service.dart';
import '../models/subtask.dart';

// This builds the context for the subtask list in each stake row
class SubtaskList extends StatelessWidget {
  final List<Subtask> subtasks;
  final void Function(int) onDelete;
  final void Function(int) onToggle;
  final VoidCallback onAdd;

  const SubtaskList({
    super.key,
    required this.subtasks,
    required this.onDelete,
    required this.onToggle,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    // Constraint for subtask count
    final bool isDisabled = subtasks.length >= 20;
    return Column(
      children: [
        ...subtasks.asMap().entries.map((entry) {
          final i = entry.key;
          final subtask = entry.value;

          return GestureDetector(
            onDoubleTap: () async {
              await SoundService.play('assets/sounds/subtask_copy.wav');
              await Clipboard.setData(ClipboardData(text: subtask.text));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Copied "${subtask.text}" to clipboard'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            child: ListTile(
              title: Text(
                subtask.text,
                style: TextStyle(
                  fontSize: 16,
                  decoration:
                      subtask.isCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => onDelete(i),
              ),
              onTap: () => onToggle(i),
            ),
          );
        }),
        TextButton(
          onPressed: isDisabled ? null : onAdd,
          child: Text(
            '+ Add Task',
            style: TextStyle(color: isDisabled ? Colors.grey : Colors.blue),
          ),
        ),
      ],
    );
  }
}
