import 'package:flutter/material.dart';
import '../services/app_data.dart';
import '../services/theme_service.dart';
import '../services/reminder_service.dart';
import '../services/auth_service.dart';
import 'checklist_page.dart';
import 'reminder_page.dart';
import 'alert_page.dart';
import 'profile_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final AuthService _authService = AuthService();
  late List<dynamic> _reminders;
  late List<dynamic> _alerts;
  bool _isLoading = false;

  // convenience getter to read current app data
  List<ChecklistModel> get _allChecklists => AppData.instance.checklists;

  // Get frequently forgotten items (items that are unchecked across checklists)
  List<ChecklistItem> get _frequentlyForgottenItems {
    final allItems = <ChecklistItem>[];
    for (var checklist in _allChecklists) {
      allItems.addAll(checklist.items.where((item) => !item.checked));
    }
    return allItems;
  }

  @override
  void initState() {
    super.initState();
    _reminders = [];
    _alerts = [];
    AppData.instance.seedIfEmpty();
    ThemeService().setTheme(AppData.instance.selectedTheme);
    
    // Load reminders and alerts from database
    _loadRemindersAndAlerts();
  }

  Future<void> _loadRemindersAndAlerts() async {
    final userId = _authService.currentUserId;
    if (userId == null) return;

    try {
      setState(() => _isLoading = true);
      
      // Load reminders from database
      final reminders = await ReminderService.getUserReminders(int.parse(userId));
      
      // Load alerts from database
      final alerts = await ReminderService.getUserAlerts(int.parse(userId));
      
      setState(() {
        _reminders = reminders;
        _alerts = alerts;
      });
      
      print('Loaded ${_reminders.length} reminders and ${_alerts.length} alerts');
    } catch (e) {
      print('Error loading reminders and alerts: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _openChecklistForReminder(ChecklistModel checklist) {
    final newItemController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (modalContext, setModalState) {
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.6,
            minChildSize: 0.3,
            maxChildSize: 0.95,
            builder: (_, controller) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 14,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(checklist.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
                          IconButton(onPressed: () => Navigator.of(ctx).pop(), icon: const Icon(Icons.close)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.separated(
                          controller: controller,
                          itemCount: checklist.items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final item = checklist.items[i];
                            return Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF6FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListTile(
                                leading: Checkbox(
                                  value: item.checked,
                                  onChanged: (v) {
                                    setModalState(() {
                                      item.checked = v ?? false;
                                    });
                                  },
                                ),
                                title: Opacity(
                                  opacity: item.checked ? 0.6 : 1.0,
                                  child: Text(
                                    item.text,
                                    style: TextStyle(
                                      decoration: item.checked ? TextDecoration.lineThrough : TextDecoration.none,
                                    ),
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.black54),
                                  onPressed: () {
                                    setModalState(() {
                                      checklist.items.removeAt(i);
                                    });
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: TextField(
                                controller: newItemController,
                                decoration: const InputDecoration(
                                  hintText: 'Add new item',
                                  border: InputBorder.none,
                                ),
                                onSubmitted: (value) {
                                  final t = value.trim();
                                  if (t.isEmpty) return;
                                  setModalState(() {
                                    checklist.items.add(ChecklistItem(text: t));
                                  });
                                  newItemController.clear();
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              final t = newItemController.text.trim();
                              if (t.isEmpty) return;
                              setModalState(() {
                                checklist.items.add(ChecklistItem(text: t));
                              });
                              newItemController.clear();
                            },
                            child: const Icon(Icons.add),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        });
      },
    ).whenComplete(() {
      setState(() {});
      newItemController.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final frequentlyForgottenItems = _frequentlyForgottenItems;
    final today = DateTime.now();
    
    int todaysRemindersCount = 0;
    try {
      todaysRemindersCount = _reminders.where((r) {
        try {
          final reminderDate = DateTime.parse(r.reminderDate);
          return reminderDate.year == today.year && 
                 reminderDate.month == today.month && 
                 reminderDate.day == today.day;
        } catch (e) {
          return false;
        }
      }).length;
    } catch (e) {
      todaysRemindersCount = 0;
    }

    int activeChecklistCount = 0;
    try {
      activeChecklistCount = _allChecklists.where((c) {
        if (c.items.isEmpty) return false;
        final completed = c.items.where((it) => it.checked).length;
        return completed < c.items.length;
      }).length;
    } catch (e) {
      activeChecklistCount = 0;
    }

    final theme = ThemeService().currentTheme;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(theme),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                children: [
                  _buildWelcomeCard(context),
                  const SizedBox(height: 16),
                  _buildStatsTiles(context, todaysRemindersCount, activeChecklistCount, theme),
                  const SizedBox(height: 16),
                  _buildAlertsTile(context, theme),
                  const SizedBox(height: 16),
                  _buildActiveRemindersCard(context, theme),
                  const SizedBox(height: 16),
                  _buildFrequentlyForgottenCard(frequentlyForgottenItems, theme),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context, theme),
    );
  }

  Widget _buildHeader(AppTheme theme) {
    return Container(
      height: 84.0,
      decoration: BoxDecoration(
        color: theme.primary,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(14), bottomRight: Radius.circular(14)),
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
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 3))],
              ),
              child: Center(child: Icon(Icons.vpn_key, color: theme.primary)),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Remindly', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                SizedBox(height: 2),
                Text('Never Forget', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('Hi, ${AppData.instance.userName}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Welcome!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          SizedBox(height: 8),
          Text('Student • Stay organized and never forget', style: TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildStatsTiles(BuildContext context, int todaysCount, int activeCount, AppTheme theme) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _statTile(icon: Icons.access_time, title: "Today's Reminders", value: '$todaysCount', gradient: _blueGradient(theme))),
            const SizedBox(width: 12),
            Expanded(child: _statTile(icon: Icons.checklist_rounded, title: 'Active Checklists', value: '$activeCount', gradient: _purpleGradient(theme))),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _statTile({required IconData icon, required String title, required String value, required Gradient gradient}) {
    return Container(
      height: 92,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
            child: Center(child: Icon(icon, color: Colors.white70, size: 20)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 6),
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsTile(BuildContext context, AppTheme theme) {
    return Container(
      height: 86,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [theme.secondary, theme.primary]),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 6))],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Total alerts', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 6),
              Text('${_alerts.length}', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
            ],
          ),
          const Spacer(),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AlertPage()));
            },
            child: const Text('Alerts'),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveRemindersCard(BuildContext context, AppTheme theme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 6))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Active Reminders', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (_reminders.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text('No reminders yet'),
            )
          else
            ...List.generate(_reminders.length, (i) {
              final reminder = _reminders[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(color: theme.primaryLighter, borderRadius: BorderRadius.circular(8), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 4))]),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(reminder.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          Text(reminder.repeatType, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                          const SizedBox(height: 6),
                          Row(children: [
                            const Icon(Icons.calendar_today, size: 13, color: Colors.black45),
                            const SizedBox(width: 6),
                            Text(reminder.reminderDate, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                            const SizedBox(width: 10),
                            const Icon(Icons.access_time, size: 13, color: Colors.black45),
                            const SizedBox(width: 6),
                            Text(reminder.reminderTime, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                          ]),
                        ]),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReminderPage()));
                        },
                        child: const Text('View'),
                      ),
                    ],
                  ),
                )
              );
            }),
        ],
      ),
    );
  }

  Widget _buildFrequentlyForgottenCard(List<ChecklistItem> items, AppTheme theme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Frequently Forgot', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.black87)),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.check_circle, size: 48, color: theme.primaryLight),
                    const SizedBox(height: 12),
                    Text('Great! You remember everything', style: TextStyle(color: Colors.black54, fontSize: 13)),
                  ],
                ),
              ),
            )
          else
            ...List.generate(items.length, (index) {
              final item = items[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0E6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFC78A), width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF8A50),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(Icons.warning, size: 18, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.text,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                )
              );
            }),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, AppTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: theme.primaryLighter, border: Border(top: BorderSide(color: Colors.black12.withOpacity(0.03)))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(icon: Icons.home, label: 'Home', active: true, theme: theme, onTap: () {}),
          _navItem(icon: Icons.list_alt, label: 'Checklist', theme: theme, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChecklistPage()))),
          _navItem(icon: Icons.access_time, label: 'Reminder', theme: theme, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReminderPage()))),
          _navItem(icon: Icons.notifications_none, label: 'Alert', theme: theme, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AlertPage()))),
          _navItem(icon: Icons.person_outline, label: 'Profile', theme: theme, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfilePage()))),
        ],
      ),
    );
  }

  Widget _navItem({required IconData icon, required String label, required AppTheme theme, bool active = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: active ? theme.primary.withOpacity(0.12) : Colors.transparent, shape: BoxShape.circle), child: Icon(icon, color: active ? theme.primary : Colors.black54)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  Gradient _blueGradient(AppTheme theme) => LinearGradient(colors: [theme.primary, theme.primaryLight]);
  Gradient _purpleGradient(AppTheme theme) => LinearGradient(colors: [theme.secondary, theme.primary]);
}