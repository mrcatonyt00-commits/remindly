import 'package:http/http.dart' as http;
import 'dart:convert';
import 'app_data.dart';

class ChecklistService {
  static const String baseUrl = 'http://192.168.100.42/remindly_api/api/checklist';

  // Get all checklists for user
  static Future<List<ChecklistModel>> getUserChecklists(int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/get_checklists.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final checklists = <ChecklistModel>[];
          for (var checklist in data['data']) {
            final items = <ChecklistItem>[];
            for (var item in checklist['items'] ?? []) {
              items.add(ChecklistItem(
                text: item['text'],
                checked: item['checked'],
              ));
            }
            checklists.add(ChecklistModel(
              title: checklist['title'],
              category: checklist['category'],
              items: items,
            ));
          }
          return checklists;
        }
      }
      return [];
    } catch (e) {
      throw Exception('Failed to get checklists: $e');
    }
  }

  // Create new checklist
  static Future<int> createChecklist({
    required int userId,
    required String title,
    required String category,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/create_checklist.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'title': title,
          'category': category,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['checklist_id'];
        }
      }
      throw Exception('Failed to create checklist');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Add item to checklist
  static Future<int> addChecklistItem({
    required int checklistId,
    required String text,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/add_checklist_item.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'checklist_id': checklistId,
          'text': text,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['item_id'];
        }
      }
      throw Exception('Failed to add item');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Update item status
  static Future<bool> updateItemStatus({
    required int itemId,
    required bool checked,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/update_item_status.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'item_id': itemId,
          'checked': checked,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Delete checklist
  static Future<bool> deleteChecklist(int checklistId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/delete_checklist.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'checklist_id': checklistId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Delete item
  static Future<bool> deleteItem(int itemId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/delete_item.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'item_id': itemId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}