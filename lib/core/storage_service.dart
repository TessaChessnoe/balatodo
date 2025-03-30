import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/checkbox_item.dart';
import '../models/subtask.dart';

// Saving and loading tasks (and eventually stake completion) goes here
class StorageService {
  // Define key for saved subtasks
  static const String _key = 'subtasks';

  static Future<void> saveSubtasks(List<CheckboxItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    // Store state of subtasks in json for later loading
    final subtasksJson =
        items.map((item) {
          return item.subtasks
              .map((s) => {'text': s.text, 'isCompleted': s.isCompleted})
              .toList();
        }).toList();

    await prefs.setString(_key, jsonEncode(subtasksJson));
  }

  static Future<List<List<Subtask>>> loadSubtasks() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('subtasks');
    // Do not load encoded subtask data if empty
    if (saved == null) {
      return [];
    }
    final decoded = jsonDecode(saved!) as List;
    return decoded.map<List<Subtask>>((stakeSubtasks) {
      return (stakeSubtasks as List).map((s) {
        return Subtask(s['text'], isCompleted: s['isCompleted']);
      }).toList();
    }).toList();
  }
}
