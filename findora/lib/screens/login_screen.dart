import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../routes/app_routes.dart';
import '../utils/app_snackbar.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'guest_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authController = Get.find<AuthController>();

  bool _rememberMe = false;
  Map<String, String> _savedAccounts = {};
  final _emailFocus = FocusNode();

  List<String> get _savedEmails => _savedAccounts.keys.toList();

  @override
  void initState() {
    super.initState();
    _loadRememberedCredentials();
  }

  Future<void> _loadRememberedCredentials() async {
    final accounts = await _authController.loadRememberedAccounts();
    if (!mounted || accounts.isEmpty) return;

    setState(() {
      _savedAccounts = accounts;
      final email = accounts.keys.first;
      _emailController.text = email;
      _passwordController.text = accounts[email] ?? '';
      _rememberMe = true;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      await _authController.login(email: email, password: password);

      if (_rememberMe) {
        await _authController.saveRememberedCredentials(
          email: email,
          password: password,
        );
      } else {
        await _authController.removeRememberedAccount(email);
      }

      if (!mounted) return;

      if (_authController.isAdmin) {
        Get.offAllNamed(AppRoutes.adminDashboard);
      } else {
        Get.offAllNamed(AppRoutes.home);
      }
    } catch (error) {
      if (mounted) {
        AppSnackBar.error(
          context,
          error.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      final signedIn = await _authController.googleSignIn();
      if (!signedIn || !mounted) return;

      if (_authController.isAdmin) {
        Get.offAllNamed(AppRoutes.adminDashboard);
      } else {
        Get.offAllNamed(AppRoutes.home);
      }
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Gradient Header
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
                padding: const EdgeInsets.fromLTRB(28, 40, 28, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Welcome back',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Sign in to your Findora account',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildEmailField(),

                    const SizedBox(height: 20),

                    CustomTextField(
                      label: 'Password',
                      hint: 'Enter your password',
                      prefixIcon: Icons.lock_outline_rounded,
                      isPassword: true,
                      controller: _passwordController,
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Password is required';
                        }

                        if (v.length < 6) {
                          return 'Password must be at least 6 characters';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 4),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Remember me
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () =>
                              setState(() => _rememberMe = !_rememberMe),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Radio<bool>(
                                value: true,
                                groupValue: _rememberMe ? true : null,
                                toggleable: true,
                                activeColor: const Color(0xFF2563EB),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                onChanged: (v) =>
                                    setState(() => _rememberMe = v ?? false),
                              ),
                              const Text(
                                'Remember me',
                                style: TextStyle(
                                  color: Color(0xFF475569),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Forgot password
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ForgotPasswordScreen(),
                            ),
                          ),
                          child: const Text(
                            'Forgot password?',
                            style: TextStyle(
                              color: Color(0xFF2563EB),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Obx(
                      () => CustomButton(
                        label: 'Sign In',
                        onPressed: _login,
                        isLoading: _authController.isLoading.value,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Center(
                      child: Text(
                        'Admin? Login with your credentials',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            'or continue with',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Obx(
                      () => CustomButton(
                        label: 'Continue with Google',
                        onPressed: _handleGoogleSignIn,
                        isLoading: _authController.isLoading.value,
                        isOutlined: true,
                        leadingWidget: _GoogleIcon(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Guest Button
                    CustomButton(
                      label: 'Continue as Guest',
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const GuestHomeScreen(),
                          ),
                        );
                      },
                      isOutlined: true,
                      icon: Icons.person_outline_rounded,
                    ),

                    const SizedBox(height: 36),

                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            ),
                            child: const Text(
                              'Sign Up',
                              style: TextStyle(
                                color: Color(0xFF2563EB),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Email field with native-style autocomplete: focusing/typing shows a
  // dropdown of accounts saved via "Remember me". Picking one fills the
  // password too. With no saved accounts it behaves like a plain field.
  Widget _buildEmailField() {
    return Autocomplete<String>(
      textEditingController: _emailController,
      focusNode: _emailFocus,
      optionsBuilder: (TextEditingValue value) {
        if (_savedEmails.isEmpty) return const Iterable<String>.empty();
        final query = value.text.toLowerCase();
        return _savedEmails.where(
          (email) => email.toLowerCase().contains(query) &&
              email.toLowerCase() != query,
        );
      },
      onSelected: (email) {
        setState(() {
          _passwordController.text = _savedAccounts[email] ?? '';
          _rememberMe = true;
        });
        _emailFocus.unfocus();
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return CustomTextField(
          label: 'Email address',
          hint: 'you@example.com',
          prefixIcon: Icons.mail_outline_rounded,
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.emailAddress,
          onFieldSubmitted: (_) => onFieldSubmitted(),
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'Email is required';
            }
            if (!_isValidEmail(v.trim())) {
              return 'Enter a valid email address';
            }
            return null;
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220, maxWidth: 360),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final email = options.elementAt(index);
                  return InkWell(
                    onTap: () => onSelected(email),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.account_circle_outlined,
                            size: 18,
                            color: Color(0xFF2563EB),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              email,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    paint.color = const Color(0xFF4285F4);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.57,
      3.14,
      true,
      paint,
    );

    paint.color = const Color(0xFF34A853);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      1.57,
      1.57,
      true,
      paint,
    );

    paint.color = const Color(0xFFFBBC05);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.14,
      0.79,
      true,
      paint,
    );

    paint.color = const Color(0xFFEA4335);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.93,
      0.79,
      true,
      paint,
    );

    paint.color = Colors.white;

    canvas.drawCircle(center, radius * 0.55, paint);

    paint.color = const Color(0xFF4285F4);

    canvas.drawRect(
      Rect.fromLTWH(
        center.dx,
        center.dy - radius * 0.15,
        radius * 0.9,
        radius * 0.3,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
