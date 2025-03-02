import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:velora/core/configs/theme/app_fonts.dart';
import 'package:velora/core/configs/theme/app_colors.dart';

// ---------------------- BUTTON ----------------------
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final String? iconPath;

  const CustomButton({
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

// ---------------------- VELORA LOGO ----------------------
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

// ---------------------- TITLES ----------------------
class CustomTitleText extends StatelessWidget {
  final String text;

  const CustomTitleText({super.key, required this.text});

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

// ---------------------- SUBTITLES ----------------------
class CustomSubtitleText extends StatelessWidget {
  final String text;
  const CustomSubtitleText({super.key, required this.text});

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

// ---------------------- -OR- ----------------------
class CustomDivider extends StatelessWidget {
  const CustomDivider({super.key});

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

// ---------------------- TEXT FIELD || TEXT BOX ----------------------
class CustomInputField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final String? Function(String?)? validator;

  const CustomInputField({
    super.key,
    required this.label,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.validator,
  });

  @override
  _CustomInputFieldState createState() => _CustomInputFieldState();
}

class _CustomInputFieldState extends State<CustomInputField> {
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

// ---------------------- DON'T || ALREADY ... HAVE AN ACCOUNT ----------------------
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

// ---------------------- APP BAR ----------------------
class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onWeatherTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;
  final bool hasWeatherAlert;
  final List<Widget>? actions; // Accept custom actions

  const MyAppBar({
    super.key,
    required this.title,
    this.onWeatherTap,
    this.onNotificationTap,
    this.onProfileTap,
    this.hasWeatherAlert = false,
    this.actions, // Accept a list of action widgets
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      backgroundColor: theme.primaryColor,
      elevation: 0,
      title: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          color: theme.colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(18), // Adjust curve radius as needed
        ),
      ),

      actions: actions ?? [], // Ensure actions are properly set
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(67.0);
}

// ---------------------- APP BAR ICON ----------------------
class AppBarIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool showBadge;

  const AppBarIcon({
    super.key,
    required this.icon,
    required this.onTap,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: Icon(icon, color: Colors.white), // Ensure icon color is visible
          onPressed: onTap,
        ),
        if (showBadge)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------- ANIMATED BOTTOM NAV BAR ----------------------
class AnimatedBottomBarButton extends StatelessWidget {
  final Widget body;
  final int selectedIndex;
  final ValueChanged<int>? onItemTapped; // Callback for tab change

  const AnimatedBottomBarButton({
    super.key,
    required this.body,
    required this.selectedIndex,
    this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: body,
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.white,
        color: AppColors.primary,
        animationCurve: Curves.easeOut,
        maxWidth: 450,
        height: 60,
        animationDuration: const Duration(milliseconds: 600),
        index: selectedIndex,
        items: const [
          Icon(Icons.home, color: Colors.white),
          Icon(Icons.work, color: Colors.white),
          Icon(Icons.calendar_today, color: Colors.white),
          Icon(Icons.chat_bubble_outline, color: Colors.white),
          Icon(Icons.settings, color: Colors.white),
        ],
        onTap: onItemTapped, // Use callback to update state
      ),
    );
  }
}

// ---------------------- FAB ----------------------
class TheFloatingActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const TheFloatingActionButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: Colors.black,
        child: Icon(icon, size: 28, color: Colors.white),
      ),
    );
  }
}
