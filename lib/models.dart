class PixelArtConfig {
  static const double globalScale = 2.0; // Default scale for pixel art
  static const double basePixelSize = 27.0;
}

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

class Subtask {
  String text;
  bool isCompleted;

  Subtask(this.text, {this.isCompleted = false});
}
