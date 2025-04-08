import 'subtask.dart';

class CheckboxItem {
  String label;
  bool isChecked;
  final String soundPath;
  final List<String> imageVariants;
  // Tracks current stake variant
  int imageIndex;
  final double? customScale;
  List<Subtask> subtasks;
  DateTime lastUpdated;

  CheckboxItem({
    required this.label,
    required this.soundPath,
    required this.imageVariants,
    this.customScale,
    this.isChecked = false,
    this.imageIndex = 0,
    List<Subtask>? subtasks,
    DateTime? lastUpdated,
  }) : subtasks = subtasks ?? [],
       lastUpdated = lastUpdated ?? DateTime.now();
}
