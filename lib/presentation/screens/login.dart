import 'package:flutter/material.dart';
import 'package:velo/core/configs/theme/app_colors.dart';
import 'package:velo/core/configs/theme/app_fonts.dart';
import 'package:velo/presentation/screens/forgot_password.dart';
import 'package:velo/presentation/screens/home.dart';
import 'package:velo/presentation/screens/signup.dart';
import 'package:velo/presentation/widgets/reusable_wdgts.dart';
import 'package:velo/data/sources/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  /// Email & Password Login
  void _login() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseServices.login(
          context: context,
          emailController: emailController,
          passwordController: passwordController,
        );

        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Login failed: $e")),
          );
        }
      }
    }
  }

  /// Google Sign-In (Force Account Selection)
  void _signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut(); // Ensure the user is signed out first

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
            MaterialPageRoute(builder: (context) => const HomePage()),
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
                TitleText(text: 'LOGIN'),
                const SizedBox(height: 32),

                // Email Input with Validation
                InputField(
                  label: 'EMAIL',
                  controller: emailController,
                  hintText: 'ENTER EMAIL',
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
                InputField(
                  label: 'PASSWORD',
                  controller: passwordController,
                  hintText: 'ENTER PASSWORD',
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

                const SizedBox(height: 2),

                // Forgot Password Button
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ForgotPasswordPage()),
                    );
                  },
                  child: Text(
                    'Forgot Password?',
                    style: AppFonts.light.copyWith(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 64),

                // Login Button
                Center(
                  child: Button(
                    text: 'LOGIN',
                    onPressed: _login,
                  ),
                ),

                const SizedBox(height: 24),
                Center(child: OrDivider()),
                const SizedBox(height: 24),

                // Google Sign-In Button
                Center(
                  child: Button(
                    text: 'With Google',
                    onPressed: _signInWithGoogle,
                    iconPath: 'assets/images/Google.png',
                  ),
                ),

                const SizedBox(height: 24),

                // Signup Navigation
                AccountNavigationRow(
                  questionText: "Don't have an account?",
                  actionText: "Sign Up",
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const Signup()),
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
