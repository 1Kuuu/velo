import 'package:flutter/material.dart';
import 'package:velora/core/configs/theme/app_colors.dart';
import 'package:velora/presentation/screens/0Auth/reset_pass.dart';
import 'package:velora/presentation/widgets/reusable_wdgts.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController emailController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  void _resetPassword() {
    String email = emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your email")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ResetPasswordPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 20),
              Center(child: const AppLogo()),
              const SizedBox(height: 40),
              Center(
                child: Text(
                  'FORGOT PASSWORD?',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              CustomInputField(
                label: 'EMAIL',
                controller: emailController,
                hintText: 'Enter your email',
              ),
              const SizedBox(height: 32),
              Center(
                child: CustomButton(
                  text: 'RESET PASSWORD',
                  onPressed: _resetPassword,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
