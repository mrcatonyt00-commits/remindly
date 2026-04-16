import 'package:flutter/material.dart';
import '../services/app_data.dart';
import '../services/theme_service.dart';
import '../services/auth_service.dart';
import '../services/checklist_service.dart';
import 'dashboard_page.dart';
import 'reminder_page.dart';
import 'alert_page.dart';
import 'profile_page.dart';

class ChecklistPage extends StatefulWidget {
  const ChecklistPage({super.key});

  @override
  _ChecklistPageState createState() => _ChecklistPageState();
}

class _ChecklistPageState extends State<ChecklistPage> {
  final List<TextEditingController> _itemControllers = [];
  final TextEditingController _newChecklistController = TextEditingController();
  final TextEditingController _customCategoryController = TextEditingController();
  String _selectedCategory = 'Work';
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    AppData.instance.seedIfEmpty();
    ThemeService().setTheme(AppData.instance.selectedTheme);
    _selectedCategory = AppData.instance.categories.isNotEmpty ? AppData.instance.categories.first : 'Work';
    
    // Load checklists from database
    _loadChecklistsFromDatabase();
  }

  Future<void> _loadChecklistsFromDatabase() async {
    final userId = _authService.currentUserId;
    if (userId == null) return;

    try {
      setState(() => _isLoading = true);
      final checklists = await ChecklistService.getUserChecklists(int.parse(userId));
      
      setState(() {
        AppData.instance.checklists.clear();
        AppData.instance.checklists.addAll(checklists);
        _syncControllersWithAppData();
      });
    } catch (e) {
      _showSnackBar('Failed to load checklists: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    for (final c in _itemControllers) {
      c.dispose();
    }
    _newChecklistController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  void _syncControllersWithAppData() {
    final lists = AppData.instance.checklists;
    while (_itemControllers.length < lists.length) {
      _itemControllers.add(TextEditingController());
    }
    while (_itemControllers.length > lists.length) {
      final c = _itemControllers.removeLast();
      c.dispose();
    }
  }

  void _showNewChecklistDialog() {
    _newChecklistController.clear();
    _customCategoryController.clear();
    _selectedCategory = AppData.instance.categories.isNotEmpty ? AppData.instance.categories.first : 'Work';
    final theme = ThemeService().currentTheme;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('New Checklist'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Create a new checklist to keep track of your tasks.'),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _newChecklistController,
                      decoration: const InputDecoration(
                        labelText: 'Checklist Name',
                        hintText: 'e.g., Daily Essentials',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Category', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedCategory,
                      items: [
                        ...AppData.instance.categories.map((cat) {
                          return DropdownMenuItem<String>(value: cat, child: Text(cat));
                        }),
                        const DropdownMenuItem<String>(
                          value: '__add_new__',
                          child: Text('+ Add New Category', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600)),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == '__add_new__') {
                          _showAddCategoryDialog(setStateDialog);
                        } else if (value != null) {
                          setStateDialog(() {
                            _selectedCategory = value;
                          });
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
                    final name = _newChecklistController.text.trim();
                    if (name.isNotEmpty) {
                      await _createChecklistInDatabase(name, _selectedCategory);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Confirm', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _createChecklistInDatabase(String title, String category) async {
    final userId = _authService.currentUserId;
    if (userId == null) {
      _showSnackBar('User not logged in');
      return;
    }

    try {
      setState(() => _isLoading = true);
      
      // Create in database
      await ChecklistService.createChecklist(
        userId: int.parse(userId),
        title: title,
        category: category,
      );

      // Reload from database
      await _loadChecklistsFromDatabase();
      _showSnackBar('Checklist created!');
    } catch (e) {
      _showSnackBar('Failed to create checklist: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAddCategoryDialog(Function setStateDialog) {
    _customCategoryController.clear();
    final theme = ThemeService().currentTheme;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Category'),
          content: TextField(
            controller: _customCategoryController,
            decoration: const InputDecoration(
              labelText: 'Category Name',
              hintText: 'e.g., Health',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: theme.primary),
              onPressed: () {
                final categoryName = _customCategoryController.text.trim();
                if (categoryName.isNotEmpty) {
                  AppData.instance.addCategory(categoryName);
                  setStateDialog(() {
                    _selectedCategory = categoryName;
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _toggleExpanded(int index) {
    setState(() {
      AppData.instance.checklists[index].expanded = !AppData.instance.checklists[index].expanded;
    });
  }

  Future<void> _deleteChecklist(int index) async {
    final checklistId = index; // You'll need to store ID in ChecklistModel

    try {
      setState(() => _isLoading = true);
      // Delete from database would go here
      // await ChecklistService.deleteChecklist(checklistId);
      
      AppData.instance.deleteChecklistAt(index);
      _syncControllersWithAppData();
      _showSnackBar('Checklist deleted');
    } catch (e) {
      _showSnackBar('Failed to delete: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addItemToList(int listIndex) {
    _syncControllersWithAppData();
    final text = _itemControllers[listIndex].text.trim();
    if (text.isEmpty) return;
    
    setState(() {
      AppData.instance.checklists[listIndex].items.add(ChecklistItem(text: text));
      _itemControllers[listIndex].clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeService().currentTheme;

    if (_isLoading && AppData.instance.checklists.isEmpty) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
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
        onPressed: _showNewChecklistDialog,
        backgroundColor: theme.primary,
        child: Icon(Icons.add),
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

  Widget _buildBody(AppTheme theme) {
    final checklists = AppData.instance.checklists;

    if (checklists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.black26),
            SizedBox(height: 16),
            Text('No checklists yet', style: TextStyle(fontSize: 18, color: Colors.black54)),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _showNewChecklistDialog,
              style: ElevatedButton.styleFrom(backgroundColor: theme.primary),
              child: Text('Create Checklist', style: TextStyle(color: Colors.white)),
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
            Text('My Checklists', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            SizedBox(height: 16),
            ...List.generate(checklists.length, (index) {
              final checklist = checklists[index];
              return _buildChecklistCard(checklist, index, theme);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistCard(ChecklistModel checklist, int index, AppTheme theme) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            title: Text(checklist.title, style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(checklist.category),
            trailing: IconButton(
              icon: Icon(checklist.expanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () => _toggleExpanded(index),
            ),
            onTap: () => _toggleExpanded(index),
          ),
          if (checklist.expanded) ...[
            Divider(),
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...List.generate(checklist.items.length, (itemIndex) {
                    final item = checklist.items[itemIndex];
                    return CheckboxListTile(
                      value: item.checked,
                      onChanged: (value) {
                        setState(() {
                          item.checked = value ?? false;
                        });
                      },
                      title: Text(item.text),
                    );
                  }),
                  SizedBox(height: 12),
                  TextField(
                    controller: _itemControllers[index],
                    decoration: InputDecoration(
                      hintText: 'Add new item',
                      border: OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () => _addItemToList(index),
                      ),
                    ),
                    onSubmitted: (_) => _addItemToList(index),
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _deleteChecklist(index),
                        icon: Icon(Icons.delete),
                        label: Text('Delete'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
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
          _navItem(icon: Icons.list_alt, label: 'Checklist', active: true, theme: theme, onTap: () {}),
          _navItem(icon: Icons.access_time, label: 'Reminder', theme: theme, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReminderPage()))),
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
          SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }
}