import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:velora/core/configs/theme/app_colors.dart';
import 'package:velora/core/configs/theme/app_fonts.dart';
import 'package:velora/presentation/widgets/reusable_wdgts.dart';
import 'package:provider/provider.dart';
import 'package:velora/core/configs/theme/theme_provider.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isEmailSent = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _resetPassword() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    FirebaseAuth.instance
        .sendPasswordResetEmail(email: emailController.text.trim())
        .then((_) {
      setState(() {
        _isLoading = false;
        _isEmailSent = true;
      });

      if (mounted) {
        DelightToastBar(
          builder: (context) {
            return const ToastCard(
              title: Text("Success"),
              subtitle:
                  Text("Password reset email sent. Please check your inbox."),
              leading: Icon(Icons.check_circle, color: Colors.green),
            );
          },
          position: DelightSnackbarPosition.top,
          autoDismiss: true,
          snackbarDuration: const Duration(seconds: 3),
          animationDuration: const Duration(milliseconds: 300),
        ).show(context);

        // Navigate back after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      }
    }).catchError((e) {
      setState(() => _isLoading = false);

      String errorMessage = "An error occurred. Please try again.";
      if (e is FirebaseAuthException) {
        if (e.code == 'user-not-found') {
          errorMessage = "No user found with this email address.";
        } else if (e.code == 'invalid-email') {
          errorMessage = "Please enter a valid email address.";
        } else if (e.code == 'too-many-requests') {
          errorMessage = "Too many attempts. Please try again later.";
        }
      }

      if (mounted) {
        DelightToastBar(
          builder: (context) {
            return ToastCard(
              title: const Text("Error"),
              subtitle: Text(errorMessage),
              leading: const Icon(Icons.error, color: Colors.red),
            );
          },
          position: DelightSnackbarPosition.top,
          autoDismiss: true,
          snackbarDuration: const Duration(seconds: 3),
          animationDuration: const Duration(milliseconds: 300),
        ).show(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Stack(
            children: [
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: isDark ? Colors.white : AppColors.primary,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(height: 20),
                    const SizedBox(height: 40),
                    const SizedBox(height: 40),
                    Center(
                      child: Text(
                        'FORGOT PASSWORD?',
                        style: AppFonts.bold.copyWith(
                          fontSize: 24,
                          color: isDark
                              ? const Color(0xFF4A3B7C)
                              : AppColors.primary,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Enter your email to reset your password',
                        style: AppFonts.regular.copyWith(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: emailController,
                      style: AppFonts.regular.copyWith(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        labelText: 'EMAIL',
                        labelStyle: AppFonts.bold.copyWith(
                          color: isDark ? Colors.white70 : Colors.black54,
                          fontSize: 14,
                        ),
                        hintText: 'Enter your email',
                        hintStyle: AppFonts.regular.copyWith(
                          color: isDark ? Colors.white38 : Colors.black38,
                          fontSize: 16,
                        ),
                        filled: true,
                        fillColor:
                            isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color:
                                isDark ? Colors.white24 : Colors.grey.shade300,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color:
                                isDark ? Colors.white24 : Colors.grey.shade300,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? const Color(0xFF4A3B7C)
                                : AppColors.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!_isValidEmail(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    if (_isEmailSent)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Check your email for password reset instructions',
                                style: AppFonts.medium.copyWith(
                                  color: Colors.green,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Center(
                        child: _isLoading
                            ? CircularProgressIndicator(
                                color: isDark
                                    ? const Color(0xFF4A3B7C)
                                    : AppColors.primary,
                              )
                            : CustomButton(
                                text: 'RESET PASSWORD',
                                onPressed: () => _resetPassword(),
                              ),
                      ),
                  ],
                ),
              ),
              const AppLogo(),
            ],
          ),
        ),
      ),
    );
  }
}
