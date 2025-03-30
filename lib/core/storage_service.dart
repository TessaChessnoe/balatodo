import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/checkbox_item.dart';
import '../models/subtask.dart';

// Saving and loading tasks (and eventually stake completion) goes here
class StorageService {
  // Define key for saved checkbox items
  static const String _checkboxKey = 'checkbox_items';

  static Future<void> saveCheckboxItems(List<CheckboxItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData =
        items.map((item) {
          return {
            'label': item.label,
            'isChecked': item.isChecked,
            'soundPath': item.soundPath,
            'imagePath': item.imagePath,
            'customScale': item.customScale,
            'lastUpdated': item.lastUpdated.toIso8601String(),
            'subtasks':
                item.subtasks
                    .map((s) => {'text': s.text, 'isCompleted': s.isCompleted})
                    .toList(),
          };
        }).toList();
    await prefs.setString(_checkboxKey, jsonEncode(jsonData));
  }

  static Future<List<CheckboxItem>> loadCheckboxItems() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_checkboxKey);
    if (raw == null) return [];

    final List decoded = jsonDecode(raw);
    return decoded.map<CheckboxItem>((json) {
      return CheckboxItem(
        label: json['label'],
        isChecked: json['isChecked'],
        soundPath: json['soundPath'],
        imagePath: json['imagePath'],
        customScale: json['customScale'],
        lastUpdated:
            DateTime.tryParse(json['lastUpdated'] ?? '') ?? DateTime.now(),
        subtasks:
            (json['subtasks'] as List).map<Subtask>((s) {
              return Subtask(s['text'], isCompleted: s['isCompleted']);
            }).toList(),
      );
    }).toList();
  }
}
