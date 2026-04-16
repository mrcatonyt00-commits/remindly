import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/reminder_service.dart';
import '../services/theme_service.dart';
import 'dashboard_page.dart';
import 'checklist_page.dart';
import 'reminder_page.dart';
import 'profile_page.dart';

class AlertPage extends StatefulWidget {
  const AlertPage({super.key});

  @override
  _AlertPageState createState() => _AlertPageState();
}

class _AlertPageState extends State<AlertPage> {
  List<AlertModel> _alerts = [];
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    final userId = _authService.currentUserId;
    if (userId == null) return;

    try {
      setState(() => _isLoading = true);
      final alerts = await ReminderService.getUserAlerts(int.parse(userId));
      setState(() {
        _alerts = alerts;
      });
    } catch (e) {
      _showSnackBar('Failed to load alerts: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAlertRead(int alertId, int index) async {
    try {
      setState(() => _isLoading = true);
      await ReminderService.markAlertRead(alertId);
      
      // Update local state
      _alerts[index].isRead = true;
      
      setState(() {});
      _showSnackBar('Alert marked as read');
    } catch (e) {
      _showSnackBar('Failed to mark as read: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAlert(int alertId, int index) async {
    try {
      setState(() => _isLoading = true);
      await ReminderService.deleteAlert(alertId);
      
      // Remove from local list
      _alerts.removeAt(index);
      
      setState(() {});
      _showSnackBar('Alert deleted');
    } catch (e) {
      _showSnackBar('Failed to delete alert: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAllReadAlerts() async {
    final readAlerts = _alerts.where((alert) => alert.isRead).toList();
    
    if (readAlerts.isEmpty) {
      _showSnackBar('No read alerts to delete');
      return;
    }

    try {
      setState(() => _isLoading = true);
      
      // Delete all read alerts
      for (var alert in readAlerts) {
        await ReminderService.deleteAlert(alert.id!);
      }
      
      // Reload
      await _loadAlerts();
      _showSnackBar('All read alerts deleted');
    } catch (e) {
      _showSnackBar('Failed to delete alerts: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Color _getAlertTypeColor(String alertType) {
    switch (alertType) {
      case '30-mins':
        return Colors.blue;
      case '15-mins':
        return Colors.orange;
      case '5-mins':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getAlertTypeLabel(String alertType) {
    switch (alertType) {
      case '30-mins':
        return '30 Minutes Before';
      case '15-mins':
        return '15 Minutes Before';
      case '5-mins':
        return '5 Minutes Before';
      default:
        return alertType;
    }
  }

  int _getUnreadCount() {
    return _alerts.where((alert) => !alert.isRead).length;
  }

  int _getReadCount() {
    return _alerts.where((alert) => alert.isRead).length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeService().currentTheme;

    if (_isLoading && _alerts.isEmpty) {
      return Scaffold(
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: Column(
        children: [
          _buildHeader(theme),
          _buildStatsBar(theme),
          Expanded(
            child: _buildBody(theme),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context, theme),
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
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Center(
                child: Icon(Icons.notifications_active, color: theme.primary),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Remindly',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Never Forget',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (_getUnreadCount() > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_getUnreadCount()} new',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsBar(AppTheme theme) {
    return Container(
      padding: const EdgeInsets.all(14),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard(
            label: 'Unread',
            count: _getUnreadCount(),
            color: Colors.blue,
          ),
          _buildStatCard(
            label: 'Read',
            count: _getReadCount(),
            color: Colors.green,
          ),
          _buildStatCard(
            label: 'Total',
            count: _alerts.length,
            color: Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(AppTheme theme) {
    if (_alerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: Colors.black26,
            ),
            const SizedBox(height: 16),
            const Text(
              'No alerts yet',
              style: TextStyle(fontSize: 18, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create a reminder to get alerts',
              style: TextStyle(fontSize: 14, color: Colors.black38),
            ),
          ],
        ),
      );
    }

    // Separate unread and read alerts
    final unreadAlerts = _alerts.where((alert) => !alert.isRead).toList();
    final readAlerts = _alerts.where((alert) => alert.isRead).toList();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Unread alerts section
            if (unreadAlerts.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Unread Alerts (${unreadAlerts.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...List.generate(
                unreadAlerts.length,
                (index) => _buildAlertCard(
                  alert: unreadAlerts[index],
                  index: _alerts.indexOf(unreadAlerts[index]),
                  theme: theme,
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Read alerts section
            if (readAlerts.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Read Alerts (${readAlerts.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (readAlerts.isNotEmpty)
                    TextButton(
                      onPressed: _deleteAllReadAlerts,
                      child: const Text(
                        'Clear All',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              ...List.generate(
                readAlerts.length,
                (index) => _buildAlertCard(
                  alert: readAlerts[index],
                  index: _alerts.indexOf(readAlerts[index]),
                  theme: theme,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard({
    required AlertModel alert,
    required int index,
    required AppTheme theme,
  }) {
    final alertColor = _getAlertTypeColor(alert.alertType);
    final alertLabel = _getAlertTypeLabel(alert.alertType);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: alert.isRead ? 0 : 2,
      color: alert.isRead ? Colors.grey.shade50 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and type badge
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.alertTitle,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: alert.isRead ? Colors.black54 : Colors.black87,
                          decoration: alert.isRead
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: alertColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: alertColor.withOpacity(0.5)),
                        ),
                        child: Text(
                          alertLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: alertColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!alert.isRead)
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: alertColor,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Date and time
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.black54),
                const SizedBox(width: 6),
                Text(
                  alert.alertDate,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 14, color: Colors.black54),
                const SizedBox(width: 6),
                Text(
                  alert.alertTime,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!alert.isRead)
                  TextButton.icon(
                    onPressed: () => _markAlertRead(alert.id!, index),
                    icon: const Icon(Icons.done, size: 18),
                    label: const Text('Mark Read'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.green,
                    ),
                  ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _deleteAlert(alert.id!, index),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, AppTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: theme.primaryLighter,
        border: Border(
          top: BorderSide(color: Colors.black12.withOpacity(0.03)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(
            icon: Icons.home,
            label: 'Home',
            theme: theme,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DashboardPage()),
            ),
          ),
          _navItem(
            icon: Icons.list_alt,
            label: 'Checklist',
            theme: theme,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChecklistPage()),
            ),
          ),
          _navItem(
            icon: Icons.access_time,
            label: 'Reminder',
            theme: theme,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReminderPage()),
            ),
          ),
          _navItem(
            icon: Icons.notifications_none,
            label: 'Alert',
            active: true,
            theme: theme,
            onTap: () {},
          ),
          _navItem(
            icon: Icons.person_outline,
            label: 'Profile',
            theme: theme,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required AppTheme theme,
    bool active = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: active ? theme.primary : Colors.black54),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}