import 'package:flutter/material.dart';
import 'package:velo/core/configs/theme/app_fonts.dart';
import 'package:velo/core/configs/theme/app_colors.dart';

//Buttons
class Button extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final String? iconPath;

  const Button({
    super.key,
    required this.text,
    required this.onPressed,
    this.iconPath,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 51,
      child: iconPath == null
          ? ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                text,
                style:
                    AppFonts.bold.copyWith(fontSize: 15, color: Colors.white),
              ),
            )
          : ElevatedButton.icon(
              onPressed: onPressed,
              icon: Image.asset(iconPath!, height: 24),
              label: Text(
                text,
                style: AppFonts.semibold.copyWith(
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
    );
  }
}

//Velora_Logo
class AppLogo extends StatelessWidget {
  const AppLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 52.5,
      left: 17,
      child: Image.asset(
        'assets/images/logo.png',
        height: 35,
      ),
    );
  }
}

//Titles
class TitleText extends StatelessWidget {
  final String text;

  const TitleText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppFonts.bold.copyWith(
        fontSize: 48,
        color: AppColors.titletxt,
        letterSpacing: 4.8,
      ),
    );
  }
}

//subTitles
class SubtitleText extends StatelessWidget {
  final String text;
  const SubtitleText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppFonts.medium.copyWith(
        fontSize: 24,
        height: 1.2,
        letterSpacing: 5,
      ),
    );
  }
}

//-or-
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: AppColors.blacktxt)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('or',
              style: AppFonts.semibold
                  .copyWith(color: AppColors.blacktxt, fontSize: 16)),
        ),
        Expanded(child: Container(height: 1, color: AppColors.blacktxt)),
      ],
    );
  }
}

//Text Fields || Text Box
class InputField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final String? Function(String?)? validator;

  const InputField({
    super.key,
    required this.label,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.validator,
  });

  @override
  _InputFieldState createState() => _InputFieldState();
}

class _InputFieldState extends State<InputField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  void _toggleObscureText() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style:
              AppFonts.bold.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          obscureText: _obscureText,
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: AppFonts.bold.copyWith(fontSize: 16, color: Colors.grey),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8), // Keep original radius
              borderSide: const BorderSide(
                  color: Colors.black, width: 1), // Keep original width
            ),
            suffixIcon: widget.obscureText
                ? IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: _toggleObscureText,
                  )
                : null, // Show icon only for password fields
          ),
          validator: widget.validator,
        ),
      ],
    );
  }
}

//Don't || Already ... Have an Account
class AccountNavigationRow extends StatelessWidget {
  final String questionText;
  final String actionText;
  final VoidCallback onPressed;

  const AccountNavigationRow({
    super.key,
    required this.questionText,
    required this.actionText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(questionText),
        TextButton(
          onPressed: onPressed,
          child: Text(
            actionText,
            style: const TextStyle(
              color: AppColors.linkText,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
