import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/reminder_service.dart';
import '../services/theme_service.dart';
import 'dashboard_page.dart';
import 'checklist_page.dart';
import 'alert_page.dart';
import 'profile_page.dart';

class ReminderPage extends StatefulWidget {
  const ReminderPage({super.key});

  @override
  _ReminderPageState createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> {
  List<ReminderModel> _reminders = [];
  bool _isLoading = false;
  final AuthService _authService = AuthService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _selectedRepeat = 'Never';

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadReminders() async {
    final userId = _authService.currentUserId;
    if (userId == null) return;

    try {
      setState(() => _isLoading = true);
      final reminders = await ReminderService.getUserReminders(int.parse(userId));
      setState(() {
        _reminders = reminders;
      });
    } catch (e) {
      _showSnackBar('Failed to load reminders: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showCreateReminderDialog() {
    _titleController.clear();
    _descriptionController.clear();
    _selectedDate = null;
    _selectedTime = null;
    _selectedRepeat = 'Never';

    final theme = ThemeService().currentTheme;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Create Reminder'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title field
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Reminder Title',
                        hintText: 'e.g., Doctor Appointment',
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Description field
                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description (optional)',
                        hintText: 'Add details...',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),

                    // Date picker
                    Row(
                      children: [
                        Icon(Icons.calendar_today, color: theme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (date != null) {
                                setStateDialog(() => _selectedDate = date);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _selectedDate != null
                                    ? '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}'
                                    : 'Select Date',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Time picker
                    Row(
                      children: [
                        Icon(Icons.access_time, color: theme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                              if (time != null) {
                                setStateDialog(() => _selectedTime = time);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _selectedTime != null
                                    ? _selectedTime!.format(context)
                                    : 'Select Time',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Repeat dropdown
                    const Text('Repeat', style: TextStyle(fontWeight: FontWeight.w600)),
                    DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedRepeat,
                      items: ['Never', 'Daily', 'Weekly', 'Monthly']
                          .map((repeat) => DropdownMenuItem<String>(
                                value: repeat,
                                child: Text(repeat),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setStateDialog(() => _selectedRepeat = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: theme.primary),
                  onPressed: () async {
                    await _createReminder();
                    Navigator.pop(context);
                  },
                  child: const Text('Create', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _createReminder() async {
    final userId = _authService.currentUserId;
    if (userId == null) {
      _showSnackBar('User not logged in');
      return;
    }

    final title = _titleController.text.trim();
    if (title.isEmpty || _selectedDate == null || _selectedTime == null) {
      _showSnackBar('Please fill in all required fields');
      return;
    }

    try {
      setState(() => _isLoading = true);

      final dateStr = '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
      final timeStr = '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00';

      await ReminderService.createReminder(
        userId: int.parse(userId),
        title: title,
        description: _descriptionController.text.trim(),
        reminderDate: dateStr,
        reminderTime: timeStr,
        repeatType: _selectedRepeat,
      );

      await _loadReminders();
      _showSnackBar('Reminder created with 3 alerts!');
    } catch (e) {
      _showSnackBar('Failed to create reminder: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteReminder(int reminderId) async {
    try {
      setState(() => _isLoading = true);
      await ReminderService.deleteReminder(reminderId);
      await _loadReminders();
      _showSnackBar('Reminder deleted');
    } catch (e) {
      _showSnackBar('Failed to delete: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeService().currentTheme;

    if (_isLoading && _reminders.isEmpty) {
      return Scaffold(
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: Column(
        children: [
          _buildHeader(theme),
          Expanded(
            child: _buildBody(theme),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context, theme),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateReminderDialog,
        backgroundColor: theme.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader(AppTheme theme) {
    return Container(
      height: 84.0,
      decoration: BoxDecoration(
        color: theme.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(14),
          bottomRight: Radius.circular(14),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 3))
                ],
              ),
              child: Center(child: Icon(Icons.access_time, color: theme.primary)),
            ),
            const SizedBox(width: 12),
            const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Remindly', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                SizedBox(height: 2),
                Text('Never Forget', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AppTheme theme) {
    if (_reminders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.access_time, size: 64, color: Colors.black26),
            const SizedBox(height: 16),
            const Text('No reminders yet', style: TextStyle(fontSize: 18, color: Colors.black54)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _showCreateReminderDialog,
              style: ElevatedButton.styleFrom(backgroundColor: theme.primary),
              child: const Text('Create Reminder', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('My Reminders', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            ..._reminders.map((reminder) => _buildReminderCard(reminder, theme)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderCard(ReminderModel reminder, AppTheme theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(Icons.notifications_active, color: theme.primary),
        title: Text(reminder.title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${reminder.reminderDate} at ${reminder.reminderTime}'),
            if (reminder.repeatType != 'Never') Text('Repeat: ${reminder.repeatType}'),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _deleteReminder(reminder.id!),
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, AppTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: theme.primaryLighter,
        border: Border(top: BorderSide(color: Colors.black12.withOpacity(0.03))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(icon: Icons.home, label: 'Home', theme: theme, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DashboardPage()))),
          _navItem(icon: Icons.list_alt, label: 'Checklist', theme: theme, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChecklistPage()))),
          _navItem(icon: Icons.access_time, label: 'Reminder', active: true, theme: theme, onTap: () {}),
          _navItem(icon: Icons.notifications_none, label: 'Alert', theme: theme, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertPage()))),
          _navItem(icon: Icons.person_outline, label: 'Profile', theme: theme, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()))),
        ],
      ),
    );
  }

  Widget _navItem({required IconData icon, required String label, required AppTheme theme, bool active = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: active ? theme.primary : Colors.black54),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }
}