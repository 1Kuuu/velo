import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:velora/core/configs/theme/app_fonts.dart';
import 'package:velora/core/configs/theme/app_colors.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:http/http.dart' as http;
import 'package:velora/presentation/screens/0Auth/profile.dart';
import 'package:provider/provider.dart';
import 'package:velora/core/configs/theme/theme_provider.dart';

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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: 200,
      height: 51,
      child: iconPath == null
          ? ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isDarkMode ? const Color(0xFF4A3B7C) : AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: isDarkMode ? 0 : 2,
              ),
              child: Text(
                text,
                style: AppFonts.bold.copyWith(
                  fontSize: 15,
                  color: Colors.white,
                ),
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
                backgroundColor:
                    isDarkMode ? const Color(0xFF4A3B7C) : AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: isDarkMode ? 0 : 2,
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      top: 52.5,
      left: 17,
      child: Image.asset(
        isDarkMode ? 'assets/images/logo-w.png' : 'assets/images/logo.png',
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
        color: Theme.of(context).brightness == Brightness.dark
            ? Color(0xFF4A3B7C)
            : AppColors.primary,
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
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final dividerColor = themeProvider.isDarkMode
            ? const Color(0xFF4A3B7C)
            : AppColors.blacktxt;

        return Row(
          children: [
            Expanded(child: Container(height: 1, color: dividerColor)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'or',
                style: AppFonts.semibold
                    .copyWith(color: dividerColor, fontSize: 16),
              ),
            ),
            Expanded(child: Container(height: 1, color: dividerColor)),
          ],
        );
      },
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          questionText,
          style: TextStyle(
            color: isDarkMode ? Colors.white70 : Colors.black87,
          ),
        ),
        TextButton(
          onPressed: onPressed,
          child: Text(
            actionText,
            style: TextStyle(
              color: isDarkMode ? const Color(0xFF4A3B7C) : AppColors.linkText,
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
  final List<Widget>? actions;

  const MyAppBar({
    super.key,
    required this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return AppBar(
      backgroundColor: isDarkMode ? const Color(0xFF4A3B7C) : AppColors.primary,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(30),
        ),
      ),
      title: Text(
        title,
        style: AppFonts.bold.copyWith(
          fontSize: 20,
          color: Colors.white,
        ),
      ),
      actions: actions != null 
        ? <Widget>[
            ...actions!,
            // Add a small padding at the end to prevent overflow
            const SizedBox(width: 8),
          ]
        : null,
      actionsIconTheme: const IconThemeData(
        size: 24,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// ---------------------- APP BAR ICON ----------------------
class AppBarIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const AppBarIcon({
    super.key,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      color: Colors.white,
      onPressed: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
    );
  }
}

// ---------------------- PROFILE APP BAR ICON ----------------------
class ProfileAppBarIcon extends StatelessWidget {
  final VoidCallback onTap;
  final String? profileUrl;
  final String? userName;

  const ProfileAppBarIcon({
    super.key,
    required this.onTap,
    this.profileUrl,
    this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      onPressed: onTap,
      icon: CircleAvatar(
        radius: 16,
        backgroundColor: Colors.grey[200],
        backgroundImage: profileUrl != null && profileUrl!.isNotEmpty
            ? NetworkImage(profileUrl!)
            : null,
        child: profileUrl == null || profileUrl!.isEmpty
            ? Text(
                userName != null && userName!.isNotEmpty
                    ? userName![0].toUpperCase()
                    : 'U',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
    );
  }
}

// ---------------------- ANIMATED BOTTOM NAV BAR ----------------------
class AnimatedBottomBarButton extends StatelessWidget {
  final Widget body;
  final int selectedIndex;
  final Function(int) onItemTapped;

  const AnimatedBottomBarButton({
    super.key,
    required this.body,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      body: body,
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.transparent,
        color: isDarkMode ? const Color(0xFF4A3B7C) : AppColors.primary,
        buttonBackgroundColor:
            isDarkMode ? const Color(0xFF4A3B7C) : AppColors.primary,
        height: 60,
        index: selectedIndex,
        onTap: onItemTapped,
        items: [
          Icon(Icons.home_outlined, color: Colors.white),
          Icon(Icons.build_outlined, color: Colors.white),
          Icon(Icons.newspaper_outlined, color: Colors.white),
          Icon(Icons.chat_bubble_outline, color: Colors.white),
          Icon(Icons.settings_outlined, color: Colors.white),
        ],
      ),
    );
  }
}

// ---------------------- FAB ----------------------
class TheFloatingActionButton extends StatelessWidget {
  final String? svgAsset;
  final IconData? icon;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final String? heroTag;

  const TheFloatingActionButton({
    super.key,
    this.svgAsset,
    this.icon,
    required this.onPressed,
    required this.backgroundColor,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isDarkMode
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6B4C9E), Color(0xFF4A3B7C)],
                  stops: [0.2, 0.8],
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? const Color(0xFF4A3B7C).withOpacity(0.5)
                  : Colors.black.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          heroTag: heroTag ?? (svgAsset ?? icon.toString()),
          onPressed: onPressed,
          backgroundColor: isDarkMode ? Colors.transparent : AppColors.primary,
          elevation: isDarkMode ? 0 : 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          child: svgAsset != null
              ? SvgPicture.asset(
                  svgAsset!,
                  width: 40,
                  height: 40,
                )
              : Icon(
                  icon,
                  size: 24,
                  color: Colors.white,
                ),
        ),
      ),
    );
  }
}

// ---------------------- DATE PICKER ----------------------
class CustomDatePicker extends StatefulWidget {
  final DateTime initialDate;
  final Function(DateTime) onDateSelected;
  final Widget child;

  const CustomDatePicker({
    super.key,
    required this.initialDate,
    required this.onDateSelected,
    required this.child,
  });

  @override
  _CustomDatePickerState createState() => _CustomDatePickerState();
}

class _CustomDatePickerState extends State<CustomDatePicker> {
  List<DateTime> holidayDates = [];

  @override
  void initState() {
    super.initState();
    _fetchHolidays();
  }

  Future<void> _fetchHolidays() async {
    final year = DateTime.now().year;
    final url =
        Uri.parse('https://date.nager.at/api/v3/PublicHolidays/$year/PH');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> holidays = jsonDecode(response.body);
        setState(() {
          holidayDates =
              holidays.map((h) => DateTime.parse(h['date'])).toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching holidays: $e');
    }
  }

  void _pickDate(BuildContext context) {
    final isDarkMode =
        Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          contentPadding: const EdgeInsets.all(16),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SfDateRangePicker(
                  selectionMode: DateRangePickerSelectionMode.single,
                  initialSelectedDate: widget.initialDate,
                  selectionColor: AppColors.primary,
                  headerStyle: DateRangePickerHeaderStyle(
                    textAlign: TextAlign.center,
                    textStyle: AppFonts.bold.copyWith(fontSize: 18),
                  ),
                  selectionTextStyle: AppFonts.bold.copyWith(
                    color: Colors.white,
                  ),
                  selectionShape: DateRangePickerSelectionShape.rectangle,

                  // ✅ Correct way to add holiday dates
                  monthViewSettings: DateRangePickerMonthViewSettings(
                    specialDates: holidayDates,
                  ),

                  monthCellStyle: DateRangePickerMonthCellStyle(
                    specialDatesDecoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    specialDatesTextStyle: AppFonts.bold.copyWith(
                      color: Colors.red,
                    ),
                  ),
                  onSelectionChanged:
                      (DateRangePickerSelectionChangedArgs args) {
                    widget.onDateSelected(args.value);
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      widget.onDateSelected(DateTime.now());
                      Navigator.pop(context);
                    },
                    child: Text(
                      "Today",
                      style: AppFonts.bold.copyWith(
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _pickDate(context),
      child: widget.child,
    );
  }
}

// Utility class for chat-related functions
class ChatUtils {
  static Color generateRandomColor(String input) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink
    ];
    return colors[input.hashCode % colors.length];
  }

  static bool hasProfilePicture(String? url) {
    return url != null &&
        url.isNotEmpty &&
        Uri.tryParse(url)?.hasAbsolutePath == true;
  }

  static String getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
  }
}

class ChatAppBar extends StatelessWidget {
  final String recipientName;
  final String recipientProfileUrl;
  final String recipientId;

  const ChatAppBar({
    super.key,
    required this.recipientName,
    required this.recipientProfileUrl,
    required this.recipientId,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfilePage(userId: recipientId),
        ),
      ),
      child: Row(
        children: [
          Transform.translate(
            offset: const Offset(-25, 0),
            child: CircleAvatar(
              backgroundColor: ChatUtils.generateRandomColor(recipientName),
              backgroundImage: ChatUtils.hasProfilePicture(recipientProfileUrl)
                  ? NetworkImage(recipientProfileUrl)
                  : null,
              child: !ChatUtils.hasProfilePicture(recipientProfileUrl)
                  ? Text(
                      ChatUtils.getInitials(recipientName),
                      style: AppFonts.regular.copyWith(
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
          ),
          Transform.translate(
            offset: const Offset(-18, 0),
            child: Flexible(
              child: Text(
                recipientName,
                style: AppFonts.bold.copyWith(fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isMe;

  const MessageBubble({super.key, required this.data, required this.isMe});

  @override
  Widget build(BuildContext context) {
    String senderName = data["senderName"] ?? "Unknown";
    String messageText = data["text"] ?? "";
    DateTime? timestamp = (data["timestamp"] as Timestamp?)?.toDate();
    String status = data["status"] ?? "sent";

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe)
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage(userId: data["senderId"]),
                ),
              ),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: ChatUtils.generateRandomColor(senderName),
                backgroundImage:
                    ChatUtils.hasProfilePicture(data["senderProfileUrl"])
                        ? NetworkImage(data["senderProfileUrl"])
                        : null,
                child: !ChatUtils.hasProfilePicture(data["senderProfileUrl"])
                    ? Text(
                        ChatUtils.getInitials(senderName),
                        style: AppFonts.regular.copyWith(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Text(
                    senderName,
                    style: AppFonts.medium
                        .copyWith(fontSize: 12, color: Colors.grey[700]),
                  ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: isMe ? AppColors.primary : Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        messageText,
                        style: AppFonts.regular.copyWith(
                          fontSize: 14,
                          color: isMe ? Colors.white : Colors.black,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTimestamp(timestamp!),
                            style: AppFonts.regular.copyWith(
                              fontSize: 10,
                              color: isMe ? Colors.white70 : Colors.grey[600],
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          if (isMe)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: _buildStatusIndicator(status),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String status) {
    switch (status) {
      case 'sent':
        return Icon(Icons.check, size: 14, color: Colors.grey);
      case 'delivered':
        return Icon(Icons.done_all, size: 14, color: Colors.grey);
      case 'seen':
        return Icon(Icons.done_all, size: 14, color: Colors.white);
      default:
        return const SizedBox();
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final hour = timestamp.hour % 12 == 0 ? 12 : timestamp.hour % 12;
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = timestamp.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}

class DateHeader extends StatelessWidget {
  final String dateKey;

  const DateHeader({super.key, required this.dateKey});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _formatDateHeader(dateKey),
            style: AppFonts.regular.copyWith(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateHeader(String dateKey) {
    DateTime now = DateTime.now();
    DateTime date = DateTime.parse(dateKey);
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return "Today";
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      return "Yesterday";
    } else {
      return "${_getMonthName(date.month)} ${date.day}, ${date.year}";
    }
  }

  String _getMonthName(int month) {
    final months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December"
    ];
    return months[month - 1];
  }
}

class MessageInputField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSendPressed;

  const MessageInputField({
    Key? key,
    required this.controller,
    required this.onSendPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(
                  color: isDarkMode ? Colors.white60 : Colors.grey,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide(
                    color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                  ),
                ),
                filled: true,
                fillColor: isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onSendPressed,
            child: Icon(
              Icons.send,
              color: isDarkMode ? const Color(0xFF4A3B7C) : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// USED IN TOOLBOX
class BikeSelectionDialog extends StatelessWidget {
  final Function(String) onBikeSelected;
  final String currentBikeType;

  const BikeSelectionDialog({
    super.key,
    required this.onBikeSelected,
    required this.currentBikeType,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    // Get available bike types excluding the current one
    final availableBikes = _getAvailableBikes(currentBikeType);

    return AlertDialog(
      backgroundColor: isDarkMode ? const Color(0xFF2D2D2D) : Colors.grey[100],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Text(
        'Change Bike Type',
        style: AppFonts.bold.copyWith(
          fontSize: 20,
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
        textAlign: TextAlign.center,
      ),
      content: SingleChildScrollView(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          width: 535,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: availableBikes
                .map((bike) => Column(
                      children: [
                        _buildBikeOption(
                          context,
                          bike['title']!,
                          bike['image']!,
                          bike['type']!,
                          bike['description']!,
                        ),
                        if (bike != availableBikes.last)
                          const SizedBox(height: 16),
                      ],
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }

  List<Map<String, String>> _getAvailableBikes(String currentBikeType) {
    final allBikes = [
      {
        'title': 'ROAD BIKE',
        'image': 'assets/images/roadbike.png',
        'type': 'ROADBIKE',
        'description': 'Perfect for speed and efficiency on paved roads',
      },
      {
        'title': 'MOUNTAIN BIKE',
        'image': 'assets/images/mountainbike.png',
        'type': 'MOUNTAINBIKE',
        'description': 'Built for off-road trails and rough terrain',
      },
      {
        'title': 'FIXIE',
        'image': 'assets/images/fixie.png',
        'type': 'FIXIE',
        'description': 'Simple, lightweight, and great for urban riding',
      },
    ];

    return allBikes
        .where((bike) =>
            bike['type']!.toLowerCase() != currentBikeType.toLowerCase())
        .toList();
  }

  Widget _buildBikeOption(
    BuildContext context,
    String title,
    String imagePath,
    String bikeType,
    String description,
  ) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        onBikeSelected(bikeType);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isDarkMode ? const Color(0xFF4A3B7C) : Colors.brown,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isDarkMode ? Colors.black26 : Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppFonts.bold.copyWith(
                      fontSize: 18,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: AppFonts.regular.copyWith(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(15),
                  bottomRight: Radius.circular(15),
                ),
                child: Container(
                  color: isDarkMode ? Colors.black : Colors.white,
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Add this to reusable_wdgts.dart
class BikePartsGrid extends StatelessWidget {
  final List<String> titles;
  final List<String> images;
  final Function(int) onPartTap;
  final bool isDarkMode;

  const BikePartsGrid({
    super.key,
    required this.titles,
    required this.images,
    required this.onPartTap,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: titles.length,
      itemBuilder: (context, index) {
        return Hero(
          tag: 'part_${titles[index].toLowerCase()}',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onPartTap(index),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDarkMode ? const Color(0xFF4A3B7C) : Colors.brown,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDarkMode
                          ? Colors.black26
                          : Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 80,
                      width: 80,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? const Color(0xFF2D2D2D)
                            : Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset(
                        images[index],
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      titles[index],
                      style: AppFonts.bold.copyWith(
                        fontSize: 16,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getPartDescription(titles[index]),
                      textAlign: TextAlign.center,
                      style: AppFonts.regular.copyWith(
                        fontSize: 12,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getPartDescription(String part) {
    switch (part.toUpperCase()) {
      case 'HANDLE':
        return 'Control and steering';
      case 'WHEELS':
        return 'Mobility and traction';
      case 'FRAME':
        return 'Structure and support';
      case 'SADDLE':
        return 'Comfort and posture';
      case 'CRANK':
        return 'Power transmission';
      case 'SHIFTER':
        return 'Gear control';
      case 'BRAKE':
        return 'Speed control';
      default:
        return '';
    }
  }
}

// Add this to reusable_wdgts.dart
class BikeUtils {
  static List<String> getTitles(String selectedBike) {
    if (selectedBike.toLowerCase() == 'roadbike') {
      return ['HANDLE', 'WHEELS', 'FRAME', 'SADDLE', 'CRANK', 'SHIFTER'];
    } else if (selectedBike.toLowerCase() == 'mountainbike') {
      return ['HANDLE', 'WHEELS', 'FRAME', 'SADDLE', 'CRANK', 'SHIFTER'];
    } else if (selectedBike.toLowerCase() == 'fixie') {
      return ['HANDLE', 'WHEELS', 'FRAME', 'SADDLE', 'CRANK', 'BRAKE'];
    }
    return [
      'HANDLE',
      'WHEELS',
      'FRAME',
      'SADDLE',
      'CRANK',
      'SHIFTER'
    ]; // Default
  }

  static List<String> getImages(String selectedBike) {
    String prefix = '';
    if (selectedBike.toLowerCase() == 'roadbike') {
      prefix = 'rd';
    } else if (selectedBike.toLowerCase() == 'mountainbike') {
      prefix = 'mb';
    } else if (selectedBike.toLowerCase() == 'fixie') {
      prefix = 'fx';
    } else {
      prefix = 'rd'; // Default
    }

    List<String> parts = getTitles(selectedBike);
    List<String> images = parts.map((part) {
      if (part == 'BRAKE') {
        return 'assets/images/$prefix-Break.png';
      }
      return 'assets/images/$prefix-${part.capitalize()}.png';
    }).toList();

    return images;
  }
}

extension StringExtension on String {
  String capitalize() {
    if (this.isEmpty) return this;
    return "${this[0].toUpperCase()}${this.substring(1).toLowerCase()}";
  }
}

