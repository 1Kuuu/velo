import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:velora/core/configs/theme/app_colors.dart';
import 'package:velora/data/sources/auth_service.dart';
import 'package:velora/presentation/widgets/reusable_wdgts.dart';
import 'login.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  /// Shows a toast message with the given parameters
  void _showToast({
    required String message,
    required IconData icon,
    Color iconColor = Colors.red,
  }) {
    if (!mounted) return;

    DelightToastBar(
      builder: (context) {
        return ToastCard(
          title: Text(message),
          leading: Icon(icon, color: iconColor),
        );
      },
      position: DelightSnackbarPosition.top,
      autoDismiss: true,
      snackbarDuration: const Duration(seconds: 2),
      animationDuration: const Duration(milliseconds: 300),
    ).show(context);
  }

  /// Validates password strength
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }
    return null;
  }

  /// 🔹 Email & Password Signup with Firestore Storage
  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    if (passwordController.text.trim() !=
        confirmPasswordController.text.trim()) {
      _showToast(
        message: 'Passwords do not match!',
        icon: Icons.error,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _authService.signUpWithEmail(
        context: context,
        username: usernameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        confirmPassword: confirmPasswordController.text.trim(),
      );

      if (!mounted) return;

      if (result == true) {
        _showToast(
          message: 'Signup Successful!',
          icon: Icons.check_circle,
          iconColor: Colors.green,
        );

        await Future.delayed(const Duration(seconds: 2));

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      } else {
        _showToast(
          message: 'Signup Failed',
          icon: Icons.error,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showToast(
        message: 'An error occurred: ${e.toString()}',
        icon: Icons.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 🔹 Google Sign-Up with Firestore Storage
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final user = await _authService.signInWithGoogle(context);

      if (!mounted) return;

      if (user != null) {
        _showToast(
          message: 'Success',
          icon: Icons.check_circle,
          iconColor: Colors.green,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showToast(
        message: 'Google sign-in failed: ${e.toString()}',
        icon: Icons.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF121212) : AppColors.lightBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppLogo(),
                const SizedBox(height: 40),
                CustomTitleText(text: 'SIGN UP'),
                const SizedBox(height: 2),
                CustomInputField(
                  label: 'USERNAME',
                  controller: usernameController,
                  hintText: 'Enter your username',
                  validator: (value) => value == null || value.isEmpty
                      ? 'Username is required'
                      : null,
                ),
                const SizedBox(height: 16),
                CustomInputField(
                  label: 'EMAIL',
                  controller: emailController,
                  hintText: 'Enter your email',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email is required';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value)) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomInputField(
                  label: 'PASSWORD',
                  controller: passwordController,
                  hintText: 'Enter your password',
                  obscureText: true,
                  validator: _validatePassword,
                ),
                const SizedBox(height: 16),
                CustomInputField(
                  label: 'CONFIRM PASSWORD',
                  controller: confirmPasswordController,
                  hintText: 'Re-enter your password',
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Center(
                  child: CustomButton(
                    text: 'SIGN UP',
                    onPressed: _isLoading ? () {} : _signup,
                  ),
                ),
                const SizedBox(height: 24),
                Center(child: CustomDivider()),
                const SizedBox(height: 24),
                Center(
                  child: CustomButton(
                    text: 'With Google',
                    onPressed: _isLoading ? () {} : _signInWithGoogle,
                    iconPath: 'assets/images/Google.png',
                  ),
                ),
                const SizedBox(height: 24),
                AccountNavigationRow(
                  questionText: "Already have an account?",
                  actionText: "Log In",
                  onPressed: _isLoading
                      ? () {}
                      : () {
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
