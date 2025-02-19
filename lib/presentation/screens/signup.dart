import 'package:flutter/material.dart';
import 'package:velo/core/configs/theme/app_colors.dart';
import 'package:velo/presentation/intro/pages/what_screen.dart';
import 'package:velo/presentation/widgets/reusable_wdgts.dart';
import 'package:velo/data/sources/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'login.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  /// 🔹 Email & Password Signup with Validation
  void _signup() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseServices.signup(
          context: context,
          usernameController: usernameController,
          emailController: emailController,
          passwordController: passwordController,
          confirmPasswordController: confirmPasswordController,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Signup successful! Please log in.")),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Signup failed: $e")),
          );
        }
      }
    }
  }

  /// 🔹 Google Sign-Up (Force Account Selection)
  void _signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut(); // Ensure user selects an account

      GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        UserCredential userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);

        if (userCredential.user != null && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => WhatScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Google Sign-In failed: $e")),
        );
      }
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppLogo(),
                CustomTitleText(text: 'SIGN UP'),
                const SizedBox(height: 2),

                // Username Input with Validation
                CustomInputField(
                  label: 'USERNAME',
                  controller: usernameController,
                  hintText: 'Enter your username',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Username is required';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Email Input with Validation
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

                // Password Input with Validation
                CustomInputField(
                  label: 'PASSWORD',
                  controller: passwordController,
                  hintText: 'Enter your password',
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Confirm Password Input with Validation
                CustomInputField(
                  label: 'CONFIRM PASSWORD',
                  controller: confirmPasswordController,
                  hintText: 'Re-enter your password',
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Confirm password is required';
                    }
                    if (value != passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Signup Button
                Center(
                  child: CustomButton(
                    text: 'SIGN UP',
                    onPressed: _signup,
                  ),
                ),

                const SizedBox(height: 24),
                Center(child: CustomDivider()),
                const SizedBox(height: 24),

                // Google Sign-Up Button
                Center(
                  child: CustomButton(
                    text: 'With Google',
                    onPressed: _signInWithGoogle,
                    iconPath: 'assets/images/Google.png',
                  ),
                ),

                const SizedBox(height: 24),

                // Login Navigation
                AccountNavigationRow(
                  questionText: "Already have an account?",
                  actionText: "Log In",
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginPage()),
                    );
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
