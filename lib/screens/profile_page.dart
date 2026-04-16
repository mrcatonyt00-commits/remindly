import 'package:flutter/material.dart';
import '../services/app_data.dart';
import '../services/theme_service.dart';
import '../services/auth_service.dart';
import 'dashboard_page.dart';
import 'checklist_page.dart';
import 'reminder_page.dart';
import 'alert_page.dart';
import 'landing_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Form controllers
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  late String _selectedTheme;
  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _selectedTheme = AppData.instance.selectedTheme;
    ThemeService().setTheme(AppData.instance.selectedTheme);
  }

  void _loadUserData() {
    _nameController = TextEditingController(text: AppData.instance.userName);
    final email = _authService.currentEmail ?? 'No email';
    _emailController = TextEditingController(text: email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    final newName = _nameController.text.trim();
    
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty!')),
      );
      return;
    }

    setState(() {
      AppData.instance.userName = newName;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Changes saved successfully!')),
    );
  }

  void _changeTheme(String themeName) {
    setState(() {
      _selectedTheme = themeName;
      AppData.instance.selectedTheme = themeName;
      ThemeService().setTheme(themeName);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Theme changed to $themeName')),
    );
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await _authService.signOut();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LandingPage()),
                    (route) => false,
                  );
                }
              },
              child: const Text('Logout', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeService().currentTheme;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: Column(
        children: [
          _buildHeader(theme),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildThemeSection(theme),
                  const SizedBox(height: 16),
                  _buildAccountProfileSection(theme),
                  const SizedBox(height: 20),
                  _buildLogoutButton(theme),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context, theme),
    );
  }

  Widget _buildHeader(AppTheme theme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
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
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))
                ],
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

  Widget _buildThemeSection(AppTheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Profile', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    SizedBox(height: 4),
                    Text('Profile and settings', style: TextStyle(color: Colors.black54, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // User Info Card
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 6))],
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: theme.primaryLighter,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(Icons.person, size: 32, color: theme.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppData.instance.userName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _emailController.text,
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountProfileSection(AppTheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Account Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 6))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Full Name', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Enter your full name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Email', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  enabled: false,
                  decoration: InputDecoration(
                    hintText: 'Enter your email',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Theme', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedTheme,
                  items: const [
                    DropdownMenuItem(value: 'Monochromatic Blue', child: Text('Monochromatic Blue')),
                    DropdownMenuItem(value: 'Monochromatic Teal', child: Text('Monochromatic Teal')),
                    DropdownMenuItem(value: 'Monochromatic Purple', child: Text('Monochromatic Purple')),
                  ],
                  onChanged: (value) {
                    if (value != null) _changeTheme(value);
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _saveChanges,
                    child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(AppTheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade400,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: _logout,
          child: const Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
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
          _navItem(icon: Icons.home, label: 'Home', theme: theme, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DashboardPage()))),
          _navItem(icon: Icons.list_alt, label: 'Checklist', theme: theme, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChecklistPage()))),
          _navItem(icon: Icons.access_time, label: 'Reminder', theme: theme, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReminderPage()))),
          _navItem(icon: Icons.notifications_none, label: 'Alert', theme: theme, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AlertPage()))),
          _navItem(icon: Icons.person_outline, label: 'Profile', active: true, theme: theme, onTap: () {}),
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
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: active ? theme.primary.withOpacity(0.12) : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: active ? theme.primary : Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}