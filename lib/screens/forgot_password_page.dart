import 'package:flutter/material.dart';
import '../widgets/header_widget.dart';
import '../services/auth_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  int _currentStep = 1; // 1: Email, 2: OTP, 3: New Password
  bool _isLoading = false;
  String _resetEmail = ''; // Store email for password reset flow
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showSnackBar('Please enter your email address');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // STEP 1: Check if email exists in database
      await _authService.checkEmailExists(email: email);
      
      // STEP 2: If email exists, send OTP
      await _authService.sendOtpForPasswordReset(email: email);
      
      setState(() {
        _resetEmail = email; // Store email for next steps
        _currentStep = 2;
      });
      _showSnackBar('OTP sent to your email!');
    } catch (e) {
      _showSnackBar(e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();

    if (otp.isEmpty) {
      _showSnackBar('Please enter the OTP');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // STEP 2: Verify OTP is correct and not expired
      await _authService.verifyOtpOnly(email: _resetEmail, otp: otp);
      
      setState(() => _currentStep = 3);
      _showSnackBar('OTP verified! Now enter your new password.');
    } catch (e) {
      _showSnackBar(e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password.isEmpty || confirmPassword.isEmpty) {
      _showSnackBar('Please fill in all password fields');
      return;
    }

    if (password != confirmPassword) {
      _showSnackBar('Passwords do not match');
      return;
    }

    if (password.length < 6) {
      _showSnackBar('Password must be at least 6 characters');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // STEP 3: Reset password with verified OTP
      final success = await _authService.verifyOtpAndResetPassword(
        email: _resetEmail,
        otp: _otpController.text.trim(),
        newPassword: password,
      );

      if (success) {
        _showSnackBar('Password reset successful! Please sign in.');
        Future.delayed(Duration(seconds: 1), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    } catch (e) {
      _showSnackBar(e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _goBack() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final headerHeight = 160.0;
    final horizontalPadding = 20.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            HeaderWidget(height: headerHeight, title: 'Remindly', showTitle: true),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 18),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  SizedBox(height: 6),
                                  Text(
                                    'Forgot Password',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.black87),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Recover your account',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.black54, fontSize: 14),
                                  ),
                                  SizedBox(height: 32),
                                  
                                  // Step indicator
                                  _buildStepIndicator(),
                                  SizedBox(height: 32),

                                  // Step content
                                  if (_currentStep == 1) ...[
                                    const Text(
                                      'Email',
                                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                    ),
                                    SizedBox(height: 8),
                                    _buildTextField(
                                      controller: _emailController,
                                      hint: 'your@email.com',
                                      label: 'Email Address',
                                    ),
                                    SizedBox(height: 24),
                                    SizedBox(
                                      height: 50,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color(0xFF90CDFD),
                                          foregroundColor: Colors.black87,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        onPressed: _isLoading ? null : _sendOtp,
                                        child: _isLoading
                                            ? SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              )
                                            : Text('Confirm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                      ),
                                    ),
                                  ] else if (_currentStep == 2) ...[
                                    const Text(
                                      'Code',
                                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                    ),
                                    SizedBox(height: 8),
                                    _buildTextField(
                                      controller: _otpController,
                                      hint: '000000',
                                      label: 'Enter OTP',
                                    ),
                                    SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: _isLoading ? null : _sendOtp,
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: Size(0, 0),
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          "Didn't get code? Resend",
                                          style: TextStyle(color: Color(0xFF2E7CE6), fontSize: 12),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 16),
                                    SizedBox(
                                      height: 50,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color(0xFF90CDFD),
                                          foregroundColor: Colors.black87,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        onPressed: _isLoading ? null : _verifyOtp,
                                        child: _isLoading
                                            ? SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              )
                                            : Text('Confirm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                      ),
                                    ),
                                  ] else if (_currentStep == 3) ...[
                                    const Text(
                                      'New Password',
                                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                    ),
                                    SizedBox(height: 8),
                                    _buildTextField(
                                      controller: _passwordController,
                                      hint: '••••••••••',
                                      label: 'New Password',
                                      obscure: true,
                                    ),
                                    SizedBox(height: 16),
                                    const Text(
                                      'Confirm Password',
                                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                    ),
                                    SizedBox(height: 8),
                                    _buildTextField(
                                      controller: _confirmPasswordController,
                                      hint: '••••••••••',
                                      label: 'Confirm Password',
                                      obscure: true,
                                    ),
                                    SizedBox(height: 24),
                                    SizedBox(
                                      height: 50,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color(0xFF90CDFD),
                                          foregroundColor: Colors.black87,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        onPressed: _isLoading ? null : _resetPassword,
                                        child: _isLoading
                                            ? SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              )
                                            : Text('Confirm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                      ),
                                    ),
                                  ],
                                ],
                              ),

                              SizedBox(height: 16),
                              TextButton(
                                onPressed: _goBack,
                                child: Text(
                                  _currentStep == 1 ? 'Back to Sign In' : 'Back',
                                  style: TextStyle(color: Color(0xFF6B46C1)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStep(1, 'Email'),
        _buildStep(2, 'Code'),
        _buildStep(3, 'Password'),
      ],
    );
  }

  Widget _buildStep(int stepNumber, String label) {
    bool isActive = stepNumber <= _currentStep;
    bool isCompleted = stepNumber < _currentStep;

    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isActive ? Color(0xFF90CDFD) : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isCompleted
                ? Icon(Icons.check, color: Colors.white, size: 24)
                : Text(
                    stepNumber.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? Colors.black87 : Colors.grey,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required String label,
    bool obscure = false,
  }) {
    final borderRadius = BorderRadius.circular(10.0);
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: Color(0xFF2E7CE6), width: 2),
        ),
        border: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
    );
  }
}