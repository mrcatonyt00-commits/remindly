import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'app_data.dart';
import 'notification_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  late SharedPreferences _prefs;
  String? _currentUserId;
  String? _currentUsername;

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _currentUserId = _prefs.getString('user_id');
    _currentUsername = _prefs.getString('username');
  }

  bool get isLoggedIn => _currentUserId != null;
  String? get currentUsername => _currentUsername;
  String? get currentUserId => _currentUserId;
  String? get currentEmail {
    try {
      return _prefs.getString('email');
    } catch (e) {
      return null;
    }
  }
  String? get currentName {
    try {
      return _prefs.getString('name');
    } catch (e) {
      return null;
    }
  }

  // Sign up
  Future<bool> signUpWithEmail({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await ApiService.register(
        name: name,
        username: username,
        email: email,
        password: password,
      );

      if (response['success'] == true) {
        return true;
      } else {
        throw Exception(response['message'] ?? 'Registration failed');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // Sign in
  Future<bool> signInWithEmail({
    required String username,
    required String password,
  }) async {
    try {
      final response = await ApiService.login(
        username: username,
        password: password,
      );

      if (response['success'] == true) {
        final user = response['user'];
        
        // Check if email is verified
        if (user['is_verified'] != 1 && user['is_verified'] != true) {
          throw Exception('Please verify your email before signing in. Check your inbox for the verification link.');
        }

        // Save to shared preferences
        await _prefs.setString('user_id', user['id'].toString());
        await _prefs.setString('username', user['username']);
        await _prefs.setString('name', user['name']);
        await _prefs.setString('email', user['email']);

        // Update local variables
        _currentUserId = user['id'].toString();
        _currentUsername = user['username'];

        // Update app data
        AppData.instance.userName = user['name'];

        // Get device token and save to database
        print('Getting device token...');
        final deviceToken = await NotificationService().getDeviceToken();
        if (deviceToken.isNotEmpty) {
          print('Saving device token to database...');
          await _saveDeviceToken(user['id'], deviceToken);
        }

        return true;
      } else {
        throw Exception(response['message'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // Save device token to database
  Future<void> _saveDeviceToken(int userId, String token) async {
    try {
      final response = await ApiService.saveDeviceToken(
        userId: userId,
        token: token,
      );
      
      if (response['success'] == true) {
        print('Device token saved successfully');
      } else {
        print('Failed to save device token: ${response['message']}');
      }
    } catch (e) {
      print('Error saving device token: $e');
    }
  }

  // Check if email exists (for password reset)
  Future<bool> checkEmailExists({
    required String email,
  }) async {
    try {
      final response = await ApiService.checkEmailExists(email: email);

      if (response['success'] == true) {
        return true;
      } else {
        throw Exception(response['message'] ?? 'Email not found');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // Send OTP for password reset
  Future<bool> sendOtpForPasswordReset({
    required String email,
  }) async {
    try {
      final response = await ApiService.sendOtp(email: email);

      if (response['success'] == true) {
        return true;
      } else {
        throw Exception(response['message'] ?? 'Failed to send OTP');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // Verify OTP (validate it before password reset)
  Future<bool> verifyOtpOnly({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await ApiService.verifyOtpOnly(email: email, otp: otp);

      if (response['success'] == true) {
        return true;
      } else {
        throw Exception(response['message'] ?? 'Invalid or expired OTP');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // Verify OTP and reset password
  Future<bool> verifyOtpAndResetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await ApiService.verifyOtp(
        email: email,
        otp: otp,
        newPassword: newPassword,
      );

      if (response['success'] == true) {
        return true;
      } else {
        throw Exception(response['message'] ?? 'Failed to reset password');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _prefs.remove('user_id');
    await _prefs.remove('username');
    await _prefs.remove('name');
    await _prefs.remove('email');

    _currentUserId = null;
    _currentUsername = null;
    AppData.instance.userName = 'User';
  }

  // Check if user is logged in
  Future<bool> checkUserLoggedIn() async {
    await init();
    if (_currentUserId != null) {
      final name = _prefs.getString('name');
      if (name != null) {
        AppData.instance.userName = name;
      }
      return true;
    }
    return false;
  }
}