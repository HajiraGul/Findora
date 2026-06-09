import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../routes/app_routes.dart';
import '../utils/app_snackbar.dart';
import '../widgets/custom_button.dart';
import 'dart:async';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  const OtpVerificationScreen({super.key, required this.email});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final _authController = Get.find<AuthController>();
  int _resendSeconds = 59;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final devOtp = _authController.lastDevelopmentOtp.value;
      AppSnackBar.success(
        context,
        devOtp == null
            ? 'Verification code sent to your email'
            : 'Verification code sent. Development OTP: $devOtp',
      );
    });
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _resendSeconds = 59);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendSeconds == 0) {
        t.cancel();
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  void _resend() async {
    try {
      await _authController.resendOtp(email: widget.email);
      _startTimer();
      for (final c in _controllers) c.clear();
      _focusNodes[0].requestFocus();
      final devOtp = _authController.lastDevelopmentOtp.value;
      AppSnackBar.success(
        context,
        devOtp == null
            ? 'Verification code sent'
            : 'Verification code sent. Development OTP: $devOtp',
      );
    } catch (error) {
      AppSnackBar.error(
        context,
        error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void _verify() async {
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length < 6) {
      AppSnackBar.error(context, 'Please enter the complete 6-digit OTP');
      return;
    }
    try {
      await _authController.verifyOtp(email: widget.email, otp: otp);
      if (!mounted) return;
      AppSnackBar.success(context, 'Your account has been verified');
      Get.offAllNamed(AppRoutes.home);
    } catch (error) {
      AppSnackBar.error(
        context,
        error.toString().replaceFirst('Exception: ', ''),
      );
      for (final c in _controllers) c.clear();
      _focusNodes[0].requestFocus();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.email;
    final atIndex = email.indexOf('@');
    final maskedEmail = atIndex > 2
        ? email.replaceRange(2, atIndex, '*' * (atIndex - 2))
        : email;

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
                      'Verify your email',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Code sent to $maskedEmail',
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
              padding: const EdgeInsets.fromLTRB(28, 36, 28, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter 6-digit code',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (i) {
                      return SizedBox(
                        width: 48,
                        height: 58,
                        child: TextFormField(
                          controller: _controllers[i],
                          focusNode: _focusNodes[i],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.zero,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                                width: 1.5,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFF2563EB),
                                width: 2,
                              ),
                            ),
                          ),
                          onChanged: (v) {
                            if (v.isNotEmpty && i < 5) {
                              _focusNodes[i + 1].requestFocus();
                            } else if (v.isEmpty && i > 0) {
                              _focusNodes[i - 1].requestFocus();
                            }
                            final otp = _controllers.map((c) => c.text).join();
                            if (otp.length == 6) _verify();
                          },
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 40),
                  Obx(
                    () => CustomButton(
                      label: 'Verify & Continue',
                      onPressed: _verify,
                      isLoading: _authController.otpLoading.value,
                      icon: Icons.arrow_forward_rounded,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Center(
                    child: _resendSeconds > 0
                        ? RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF64748B),
                              ),
                              children: [
                                const TextSpan(text: 'Resend code in '),
                                TextSpan(
                                  text:
                                      '00:${_resendSeconds.toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                    color: Color(0xFF2563EB),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : GestureDetector(
                            onTap: _resend,
                            child: const Text(
                              "Didn't receive the code? Resend",
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
            ),
          ),
        ],
      ),
    );
  }
}
