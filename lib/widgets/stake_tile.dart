import 'package:flutter/material.dart';
import '../models/checkbox_item.dart';
import '../models/pixel_art_config.dart';

// This builds context for the stake tile for each checklist row
class StakeTile extends StatelessWidget {
  final CheckboxItem item;
  final int index;
  final Color backgroundWhite;
  final VoidCallback onResetSubtasks;
  final ValueChanged<bool?>? onToggle;
  final Widget subtaskList;

  const StakeTile({
    super.key,
    required this.item,
    required this.index,
    required this.backgroundWhite,
    required this.onResetSubtasks,
    required this.onToggle,
    required this.subtaskList,
  });

  @override
  Widget build(BuildContext context) {
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
            Row(
              children: [
                ClipRect(
                  child: SizedBox(
                    width: displaySize,
                    height: displaySize,
                    child: Image.asset(item.imagePath, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(item.label, style: const TextStyle(fontSize: 18)),
                ),
                IconButton(
                  icon: const Icon(Icons.restart_alt, color: Colors.blue),
                  onPressed: onResetSubtasks,
                ),
                Checkbox(value: item.isChecked, onChanged: onToggle),
              ],
            ),
            subtaskList,
          ],
        ),
      ),
    );
  }
}
