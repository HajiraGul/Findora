import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../utils/app_snackbar.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authController = Get.find<AuthController>();
  bool _emailSent = false;

  bool _isValidEmail(String email) =>
      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);

  void _sendReset() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await _authController.forgotPassword(email: _emailController.text.trim());
      if (!mounted) return;
      setState(() => _emailSent = true);
      final devOtp = _authController.lastDevelopmentOtp.value;
      AppSnackBar.success(
        context,
        devOtp == null
            ? 'Password reset code sent to your email'
            : 'Password reset code sent. Development OTP: $devOtp',
      );
    } catch (error) {
      if (mounted) {
        AppSnackBar.error(
          context,
          error.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }

  void _resetPassword() async {
    if (!_resetFormKey.currentState!.validate()) return;

    try {
      await _authController.resetPassword(
        email: _emailController.text.trim(),
        otp: _otpController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      AppSnackBar.success(
        context,
        'Password reset successfully. Please sign in.',
      );
      Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        AppSnackBar.error(
          context,
          error.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF1D4ED8),
                  Color(0xFF2563EB),
                  Color(0xFF3B82F6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 28, 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Reset password',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'We\'ll send a reset code to your email',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 40, 28, 24),
              child: _emailSent ? _buildSuccessState() : _buildFormState(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormState() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.lock_reset_rounded,
              color: Color(0xFF2563EB),
              size: 36,
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Enter your email',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter the email associated with your account and we\'ll send you a password reset link.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),
          CustomTextField(
            label: 'Email address',
            hint: 'you@example.com',
            prefixIcon: Icons.mail_outline_rounded,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              if (!_isValidEmail(v.trim()))
                return 'Enter a valid email address';
              return null;
            },
          ),
          const SizedBox(height: 32),
          Obx(
            () => CustomButton(
              label: 'Send Reset Code',
              onPressed: _sendReset,
              isLoading: _authController.resetLoading.value,
              icon: Icons.send_rounded,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Text(
                'Back to Sign In',
                style: TextStyle(
                  color: Color(0xFF2563EB),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    return Form(
      key: _resetFormKey,
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(
              Icons.mark_email_read_outlined,
              color: Color(0xFF16A34A),
              size: 46,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Enter reset code',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'We\'ve sent a password reset code to\n${_emailController.text.trim()}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF64748B),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'The code will expire soon.',
            style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 20),
          CustomTextField(
            label: 'Reset code',
            hint: 'Enter 6-digit OTP',
            prefixIcon: Icons.pin_rounded,
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'OTP is required';
              if (!RegExp(r'^[0-9]{6}$').hasMatch(v.trim())) {
                return 'Enter a valid 6-digit OTP';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'New password',
            hint: 'Min 8 chars, 1 uppercase, 1 number',
            prefixIcon: Icons.lock_outline_rounded,
            isPassword: true,
            controller: _passwordController,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 8) return 'Password must be at least 8 characters';
              if (!RegExp(r'[A-Z]').hasMatch(v)) {
                return 'Must contain at least 1 uppercase letter';
              }
              if (!RegExp(r'[0-9]').hasMatch(v)) {
                return 'Must contain at least 1 number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Confirm password',
            hint: 'Re-enter your password',
            prefixIcon: Icons.lock_outline_rounded,
            isPassword: true,
            controller: _confirmPasswordController,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please confirm your password';
              if (v != _passwordController.text)
                return 'Passwords do not match';
              return null;
            },
          ),
          const SizedBox(height: 28),
          Obx(
            () => CustomButton(
              label: 'Reset Password',
              onPressed: _resetPassword,
              isLoading: _authController.resetLoading.value,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                _tipRow(
                  Icons.folder_outlined,
                  'Check your spam/junk folder if you don\'t see it.',
                ),
                const SizedBox(height: 10),
                _tipRow(
                  Icons.timer_outlined,
                  'Code expires soon. Request a new one if needed.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
          CustomButton(
            label: 'Back to Sign In',
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _sendReset,
            child: const Text(
              'Resend code',
              style: TextStyle(
                color: Color(0xFF2563EB),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tipRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
