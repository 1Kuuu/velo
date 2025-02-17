import 'package:flutter/material.dart';
import 'package:velo/presentation/screens/login.dart'; // Import the login screen
import 'package:velo/core/configs/theme/app_colors.dart'; // Import your color theme

class VerificationScreen extends StatefulWidget {
  final String email;
  const VerificationScreen({required this.email, super.key});

  @override
  _VerificationScreenState createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final TextEditingController verificationController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  void _verifyCode() {
    String code = verificationController.text;

    // Example verification (replace with your actual logic)
    if (code == '1234') {  // Replace with actual code verification logic
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Verification successful!")),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()), // Redirect to Login after verification
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid code, please try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary, // Use your primary color
        title: const Text("VELO - Verify Your Email"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Enter the verification code sent to your email:",
                style: TextStyle(
                  fontSize: 18,
                  color: AppColors.primary, // Use your primary color
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: verificationController,
                decoration: InputDecoration(
                  labelText: "Verification Code",
                  labelStyle: TextStyle(color: AppColors.primary), // Use your primary color
                  border: const OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter the verification code.";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: _verifyCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary, // Use your primary color
                  ),
                  child: const Text("Verify Code"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
