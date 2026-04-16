// lib/services/app_data.dart
import 'package:flutter/material.dart';

class ChecklistItem {
  int? id; // Database ID
  String text;
  bool checked;
  ChecklistItem({this.id, required this.text, this.checked = false});
}

class ChecklistModel {
  int? id; // Database ID
  String title;
  String category;
  List<ChecklistItem> items;
  bool expanded;
  
  ChecklistModel({
    this.id,
    required this.title,
    required this.category,
    List<ChecklistItem>? items,
    this.expanded = false,
  }) : items = items ?? [];
}


class ReminderModel {
  String title;
  String? checklistTitle;
  DateTime? date;
  TimeOfDay? time;
  String repeat;
  bool active;
  bool notificationSent;

  ReminderModel({
    required this.title,
    this.checklistTitle,
    this.date,
    this.time,
    this.repeat = 'Never',
    this.active = true,
    this.notificationSent = false,
  });
}

class AlertModel {
  int id;
  String title;
  String checklistTitle;
  String reminderTitle;
  DateTime timestamp;
  String severity;
  bool isRead;
  String timeAgo;

  AlertModel({
    required this.id,
    required this.title,
    required this.checklistTitle,
    required this.reminderTitle,
    required this.timestamp,
    required this.severity,
    required this.isRead,
    required this.timeAgo,
  });
}

class AppData {
  AppData._private();
  static final AppData instance = AppData._private();

  final List<ChecklistModel> checklists = [];
  final List<ReminderModel> reminders = [];
  final List<AlertModel> alerts = [];
  final List<String> categories = ['Work', 'School', 'Travel', 'Business', 'Parent', 'Fitness'];
  bool notificationsPermissionGranted = false;
  String selectedTheme = 'Monochromatic Blue';
  String userName = 'Angel';

  void seedIfEmpty() {
    if (checklists.isEmpty) {
      checklists.addAll([
        ChecklistModel(
          title: 'Student Essentials',
          category: 'School',
          items: [
            ChecklistItem(text: 'Textbooks'),
            ChecklistItem(text: 'Laptop'),
            ChecklistItem(text: 'Notebook'),
          ],
        ),
        ChecklistModel(
          title: 'Morning Checklist',
          category: 'School',
          items: [
            ChecklistItem(text: 'Brush Teeth'),
            ChecklistItem(text: 'Make Bed'),
          ],
        ),
      ]);
    }
  }

  void addChecklist(ChecklistModel list) => checklists.insert(0, list);
  void deleteChecklistAt(int index) => checklists.removeAt(index);

  void addReminder(ReminderModel r) => reminders.insert(0, r);
  void deleteReminderAt(int index) => reminders.removeAt(index);

  void addAlert(AlertModel alert) => alerts.insert(0, alert);
  void deleteAlertAt(int index) => alerts.removeAt(index);

  void addCategory(String category) {
    if (!categories.contains(category)) {
      categories.add(category);
    }
  }
}