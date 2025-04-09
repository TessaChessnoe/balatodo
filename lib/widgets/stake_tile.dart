import 'package:flutter/material.dart';
import '../models/checkbox_item.dart';
import '../models/pixel_art_config.dart';
// Required to create stake clipping mask
import 'dart:math';

/// Clips a circular image, removing a sector that represents the completed subtasks.
class StakeClipper extends CustomClipper<Path> {
  final double completionRatio; // Value between 0.0 and 1.0

  StakeClipper(this.completionRatio);

  @override
  Path getClip(Size size) {
    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final edge_padding = 20;
    final radius = (size.width / 2) + edge_padding;

    // Draw the full circle
    path.addOval(Rect.fromCircle(center: center, radius: radius));

    // Build a wedge path representing the completed portion
    final wedge =
        Path()
          ..moveTo(center.dx, center.dy)
          // Create arc
          ..arcTo(
            Rect.fromCircle(center: center, radius: radius),
            // Start from top of circle
            -pi / 2,
            // Cutout section angle as ratio to full rotation
            2 * pi * completionRatio,
            // No need to move position since wedge angle is cumulative
            false,
          )
          ..close();

    // Subtract the wedge from the full circle to form the clipping mask
    if (completionRatio != 1) {
      return Path.combine(PathOperation.difference, path, wedge);
      // If all subtasks complete, cut out 2pi radians (entire sprite)
    } else {
      return Path.combine(PathOperation.difference, wedge, path);
    }
  }

  @override
  bool shouldReclip(covariant StakeClipper oldClipper) {
    return oldClipper.completionRatio != completionRatio;
  }
}

// This builds context for the stake tile for each checklist row
class StakeTile extends StatelessWidget {
  final CheckboxItem item;
  final int index;
  final Color backgroundWhite;
  final VoidCallback onResetSubtasks;
  final ValueChanged<bool?>? onToggle;
  final Widget subtaskList;
  final bool canRemoveStake;

  // Call back to parent widget for access to SoundServices
  final VoidCallback onRemoveStake;
  // Option parameter for stakes with variants
  final VoidCallback? onVariantChange;

  const StakeTile({
    super.key,
    required this.item,
    required this.index,
    required this.backgroundWhite,
    required this.onResetSubtasks,
    required this.onToggle,
    required this.subtaskList,
    required this.onRemoveStake,
    required this.canRemoveStake,
    this.onVariantChange,
  });

  @override
  Widget build(BuildContext context) {
    final scale = item.customScale ?? PixelArtConfig.globalScale;
    final displaySize = PixelArtConfig.basePixelSize * scale;

    // Must declare outside of widget tree
    final completed = item.subtasks.where((s) => s.isCompleted).length;
    final total = item.subtasks.length;
    final ratio = (total == 0) ? 0.0 : completed / total;
    bool isTotalZero = (total == 0);

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
              mainAxisSize: MainAxisSize.min,
              children: [
                // GD and onTap are needed for interactions with non-button elems
                // No visual feedback by default (good for now)
                GestureDetector(
                  // Cycle through stake variants when tapping on gold stake
                  onTap: () {
                    item.imageIndex =
                        (item.imageIndex + 1) % item.imageVariants.length;
                    (context as Element).markNeedsBuild(); // Force rebuild
                    onVariantChange?.call(); // Trigger var change sound
                  },
                  child: ClipPath(
                    clipper: StakeClipper(ratio),
                    child: SizedBox(
                      width: displaySize,
                      height: displaySize,
                      child: Image.asset(
                        item.imageVariants[item.imageIndex],
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(item.label, style: const TextStyle(fontSize: 18)),
                ),
                IconButton(
                  icon: Icon(
                    Icons.remove_circle_outline,
                    color: canRemoveStake ? Colors.orange : Colors.grey,
                  ),
                  // Only enable remove stake button for last stake
                  onPressed: canRemoveStake ? onRemoveStake : null,
                ),
                IconButton(
                  icon: Icon(
                    Icons.restart_alt,
                    color: isTotalZero ? Colors.grey : Colors.blue,
                  ),
                  // Disable reset button when there are no tasks to reset
                  onPressed:
                      (isTotalZero || total < 0) ? null : onResetSubtasks,
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
