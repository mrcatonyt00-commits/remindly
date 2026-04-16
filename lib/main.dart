import 'package:flutter/material.dart';
import 'screens/landing_page.dart';
import 'screens/sign_in_page.dart';
import 'screens/sign_up_page.dart';
import 'screens/dashboard_page.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Auth Service
  await AuthService().init();
  
  // Initialize Notification Service (Firebase + Local)
  await NotificationService().init();
  
  runApp(const MyApp());
}

// ... rest of code ...

class MyApp extends StatelessWidget {
  static const String title = 'Remindly';

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: title,
      theme: ThemeData(
        primaryColor: const Color(0xFF2E7CE6),
        scaffoldBackgroundColor: const Color(0xFFEFF7FB),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const _AuthWrapper(),
        '/signin': (context) => const SignInPage(),
        '/signup': (context) => const SignUpPage(),
      },
    );
  }
}

class _AuthWrapper extends StatefulWidget {
  const _AuthWrapper();

  @override
  State<_AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<_AuthWrapper> {
  late Future<bool> _checkAuthFuture;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkAuthFuture = _authService.checkUserLoggedIn();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkAuthFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Error: ${snapshot.error}'),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data == true) {
          return const DashboardPage();
        }

        return const LandingPage();
      },
    );
  }
}