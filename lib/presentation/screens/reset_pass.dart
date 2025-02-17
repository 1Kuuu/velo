import 'package:flutter/material.dart';
import 'package:velo/core/configs/theme/app_colors.dart';
import 'package:velo/core/configs/theme/app_fonts.dart';
import 'package:velo/presentation/widgets/reusable_wdgts.dart';
import 'package:velo/core/utils/validators.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key}); 

  @override
  ResetPasswordPageState createState() => ResetPasswordPageState();
}

class ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  void submitForm() {
    if (_formKey.currentState!.validate()) { 
    
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password reset successful!")),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon:
                        const Icon(Icons.arrow_back, color: AppColors.primary), 
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                const SizedBox(height: 10),
                const AppLogo(),
                const SizedBox(height: 10),

                Center(
                  child: Text(
                    'Enter Your New Password',
                    style: AppFonts.bold.copyWith(
                      fontSize: 20,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // New Password Field
                CustomInputField(
                  label: 'NEW PASSWORD',
                  controller: passwordController,
                  hintText: 'Enter your new password',
                  obscureText: true,
                  validator: FormValidators.validatePassword,
                ),

                const SizedBox(height: 16),

                CustomInputField(
                  label: 'CONFIRM PASSWORD',
                  controller: confirmPasswordController,
                  hintText: 'Re-enter your new password',
                  obscureText: true,
                  validator: (value) => FormValidators.validatePasswordMatch(
                    value,
                    passwordController.text,
                  ),
                ),

                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  child: CustomButton(
                    text: 'SUBMIT',
                    onPressed: submitForm,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
