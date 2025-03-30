import 'subtask.dart';

class CheckboxItem {
  String label;
  bool isChecked;
  final String soundPath;
  final String imagePath;
  final double? customScale;
  List<Subtask> subtasks;
  DateTime lastUpdated;

  CheckboxItem({
    required this.label,
    required this.soundPath,
    required this.imagePath,
    this.customScale,
    this.isChecked = false,
    List<Subtask>? subtasks,
    DateTime? lastUpdated,
  }) : subtasks = subtasks ?? [],
       lastUpdated = lastUpdated ?? DateTime.now();
}
