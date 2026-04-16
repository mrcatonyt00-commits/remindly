import 'package:http/http.dart' as http;
import 'dart:convert';

class ReminderModel {
  int? id;
  String title;
  String? description;
  int? checklistId;
  String reminderDate;
  String reminderTime;
  String repeatType;
  bool active;
  DateTime? createdAt;

  ReminderModel({
    this.id,
    required this.title,
    this.description,
    this.checklistId,
    required this.reminderDate,
    required this.reminderTime,
    this.repeatType = 'Never',
    this.active = true,
    this.createdAt,
  });
}

class AlertModel {
  int? id;
  int? reminderId;
  String alertTitle;
  String alertDate;
  String alertTime;
  String alertType;
  bool isRead;
  DateTime? createdAt;

  AlertModel({
    this.id,
    this.reminderId,
    required this.alertTitle,
    required this.alertDate,
    required this.alertTime,
    required this.alertType,
    this.isRead = false,
    this.createdAt,
  });
}

class ReminderService {
  static const String baseUrl = 'http://192.168.100.42/remindly_api/api/reminder';
  static const String alertBaseUrl = 'http://192.168.100.42/remindly_api/api/alert';

  // Create reminder (automatically creates 3 alerts)
  static Future<int> createReminder({
    required int userId,
    required String title,
    String? description,
    required String reminderDate,
    required String reminderTime,
    String repeatType = 'Never',
    int? checklistId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/create_reminder.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'title': title,
          'description': description,
          'reminder_date': reminderDate,
          'reminder_time': reminderTime,
          'repeat_type': repeatType,
          'checklist_id': checklistId,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['reminder_id'];
        }
      }
      throw Exception('Failed to create reminder');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Get all reminders for user
  static Future<List<ReminderModel>> getUserReminders(int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/get_reminders.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final reminders = <ReminderModel>[];
          for (var reminder in data['data']) {
            reminders.add(ReminderModel(
              id: reminder['id'],
              title: reminder['title'],
              description: reminder['description'],
              checklistId: reminder['checklist_id'],
              reminderDate: reminder['reminder_date'],
              reminderTime: reminder['reminder_time'],
              repeatType: reminder['repeat_type'],
              active: reminder['active'],
              createdAt: DateTime.tryParse(reminder['created_at'] ?? ''),
            ));
          }
          return reminders;
        }
      }
      return [];
    } catch (e) {
      print('Error in getUserReminders: $e');
      return [];
    }
  }

  // Update reminder
  static Future<bool> updateReminder({
    required int reminderId,
    required String title,
    String? description,
    required String reminderDate,
    required String reminderTime,
    String repeatType = 'Never',
    bool active = true,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/update_reminder.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'reminder_id': reminderId,
          'title': title,
          'description': description,
          'reminder_date': reminderDate,
          'reminder_time': reminderTime,
          'repeat_type': repeatType,
          'active': active ? 1 : 0,
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

  // Delete reminder
  static Future<bool> deleteReminder(int reminderId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/delete_reminder.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'reminder_id': reminderId}),
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

  // Get all alerts for user
  static Future<List<AlertModel>> getUserAlerts(int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$alertBaseUrl/get_alerts.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final alerts = <AlertModel>[];
          for (var alert in data['data']) {
            alerts.add(AlertModel(
              id: alert['id'],
              reminderId: alert['reminder_id'],
              alertTitle: alert['alert_title'],
              alertDate: alert['alert_date'],
              alertTime: alert['alert_time'],
              alertType: alert['alert_type'],
              isRead: alert['is_read'],
              createdAt: DateTime.tryParse(alert['created_at'] ?? ''),
            ));
          }
          return alerts;
        }
      }
      return [];
    } catch (e) {
      print('Error in getUserAlerts: $e');
      return [];
    }
  }

  // Mark alert as read
  static Future<bool> markAlertRead(int alertId) async {
    try {
      final response = await http.post(
        Uri.parse('$alertBaseUrl/mark_alert_read.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'alert_id': alertId}),
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

  // Delete alert
  static Future<bool> deleteAlert(int alertId) async {
    try {
      final response = await http.post(
        Uri.parse('$alertBaseUrl/delete_alert.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'alert_id': alertId}),
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