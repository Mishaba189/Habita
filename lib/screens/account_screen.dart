import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../providers/auth_provider.dart';
import 'auth_screen.dart';


class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late final TextEditingController _nameController;
  bool _notificationsEnabled = true;

  // State for toggling name editing mode
  bool _isEditingName = false;
  String _selectedLanguage = "English";

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _nameController = TextEditingController(text: authProvider.userName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Show Success Dialog instead of SnackBar
  void _showSuccessDialog(String updatedName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Icon Container with Gradient
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: AppColors.orangeGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.orange.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  "Success!",
                  style: GoogleFonts.nunito(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.blackGrey,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle/Message
                Text(
                  "Name updated to $updatedName",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.darkGrey,
                  ),
                ),
                const SizedBox(height: 24),

                // Action Button (Full-width Gradient Button)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppColors.orangeGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.orange.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        "OK",
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
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


  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Warning Icon Container (using Red Accent for Log Out)
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Colors.redAccent,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  "Log Out",
                  style: GoogleFonts.nunito(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.blackGrey,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle/Message
                Text(
                  "Are you sure you want to log out of your account?",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.darkGrey,
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons Row
                Row(
                  children: [
                    // Cancel Button
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: AppColors.lightGrey.withOpacity(0.8),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            "Cancel",
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.blackGrey,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Confirm Log Out Button
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(dialogContext); // Close dialog first

                            // Perform Sign Out & Navigation
                            Provider.of<AuthProvider>(context, listen: false).signOut();
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) =>  AuthScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            "Log Out",
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  // Language Picker Bottom Sheet
  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Modal Handle Bar for a modern look
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.lightGrey,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
          
                // Title
                Text(
                  "Select Language",
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.blackGrey,
                  ),
                ),
                const SizedBox(height: 16),
          
                // Language Options
                _buildLanguageOption("English"),
                const SizedBox(height: 8),
                _buildLanguageOption("Malayalam"),
                const SizedBox(height: 8),
                _buildLanguageOption("Hindi"),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(String language) {
    final isSelected = _selectedLanguage == language;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLanguage = language;
        });
        Navigator.pop(context);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.orange.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.orange : AppColors.lightGrey.withOpacity(0.6),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              language,
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? AppColors.orange : AppColors.blackGrey,
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: AppColors.orange,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  size: 14,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSaveName(AuthProvider authProvider) async {
    FocusScope.of(context).unfocus();
    final newName = _nameController.text.trim();

    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Name cannot be empty"), backgroundColor: Colors.redAccent),
      );
      return;
    }

    try {
      await authProvider.updateUserName(newName);

      if (!mounted) return;

      setState(() {
        _isEditingName = false; // Switch back to Edit button mode
      });

      // Show custom success dialog
      _showSuccessDialog(newName);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.light,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Page Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: AppColors.blackGrey,
                        size: 18,
                      ),
                    ),
                  ),
                  Text(
                    "Account Settings",
                    style: GoogleFonts.nunito(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.blackGrey,
                    ),
                  ),
                  const SizedBox(width: 36),
                ],
              ),
              const SizedBox(height: 28),

              // 2. Simple Initial Avatar Header
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.orange.withOpacity(0.15),
                          child: Text(
                            authProvider.userName.isNotEmpty
                                ? authProvider.userName[0].toUpperCase()
                                : 'U',
                            style: GoogleFonts.nunito(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppColors.orange,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          authProvider.userName,
                          style: GoogleFonts.nunito(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.blackGrey,
                          ),
                        ),
                        Text(
                          authProvider.userEmail,
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            color: AppColors.darkGrey,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              // 3. Profile Information Section
              _buildSectionHeader("ACCOUNT DETAILS"),
              const SizedBox(height: 12),

              // Full Name input with dynamic Edit/Save Toggle Button
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return _buildEditableNameField(
                    label: "Full Name",
                    controller: _nameController,
                    isEditing: _isEditingName,
                    onTapAction: () {
                      if (!_isEditingName) {
                        setState(() {
                          _isEditingName = true;
                        });
                      } else {
                        _handleSaveName(authProvider);
                      }
                    },
                    isLoading: authProvider.isLoading,
                  );
                },
              ),
              const SizedBox(height: 16),

              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return _buildReadOnlyField(
                    label: "Email Address",
                    value: authProvider.userEmail,
                    icon: Icons.lock_outline,
                  );
                },
              ),
              const SizedBox(height: 28),

              // 4. App Preferences Section
              _buildSectionHeader("APP SETTINGS"),
              const SizedBox(height: 12),

              // Notifications Toggle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: _cardBoxDecoration(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTileTitle(
                      icon: Icons.notifications_active_outlined,
                      title: "Push Notifications",
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _notificationsEnabled = !_notificationsEnabled;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        width: 40,
                        height: 22,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: _notificationsEnabled
                              ? AppColors.orange
                              : Colors.grey.withOpacity(0.25),
                        ),
                        child: AnimatedAlign(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          alignment: _notificationsEnabled
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 3,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // App Language
              _buildActionTile(
                icon: Icons.language_outlined,
                title: "App Language",
                trailingText: _selectedLanguage,
                onTap: _showLanguagePicker,
              ),
              const SizedBox(height: 12),

              // Security & Privacy
              _buildActionTile(
                icon: Icons.security_outlined,
                title: "Privacy & Security",
                onTap: () {},
              ),
              const SizedBox(height: 28),

              // 5. Support & Danger Zone
              _buildSectionHeader("SUPPORT & ACCOUNT"),
              const SizedBox(height: 12),

              _buildActionTile(
                icon: Icons.help_outline_rounded,
                title: "Help & Support",
                onTap: () {},
              ),
              const SizedBox(height: 12),

              _buildActionTile(
                icon: Icons.logout_rounded,
                title: "Log Out",
                titleColor: Colors.redAccent,
                iconColor: Colors.redAccent,
                showArrow: false,
                onTap: () {
                  _showLogoutConfirmationDialog(context);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---


  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.nunito(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.darkGrey,
        letterSpacing: 1.1,
      ),
    );
  }

  BoxDecoration _cardBoxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.02),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _buildTileTitle({
    required IconData icon,
    required String title,
    Color? iconColor,
    Color? titleColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: iconColor ?? AppColors.blackGrey,
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: titleColor ?? AppColors.blackGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? trailingText,
    Color? iconColor,
    Color? titleColor,
    bool showArrow = true,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: _cardBoxDecoration(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildTileTitle(
              icon: icon,
              title: title,
              iconColor: iconColor,
              titleColor: titleColor,
            ),
            Row(
              children: [
                if (trailingText != null)
                  Text(
                    trailingText,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkGrey,
                    ),
                  ),
                if (showArrow) ...[
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.darkGrey,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
  // Editable Name Widget with dynamic Edit / Save Switch Button
  Widget _buildEditableNameField({
    required String label,
    required TextEditingController controller,
    required bool isEditing,
    required VoidCallback onTapAction,
    bool isLoading = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.darkGrey,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: _cardBoxDecoration(),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: isEditing,
                  autofocus: isEditing, // Automatically trigger keyboard when editing starts
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.blackGrey,
                  ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: GestureDetector(
                  onTap: isLoading ? null : onTapAction,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.orange.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: isLoading
                        ? const SizedBox(
                      height: 14,
                      width: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.orange,
                      ),
                    )
                        : Text(
                      isEditing ? "Save" : "Edit",
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.orange,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.darkGrey,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.withOpacity(0.12),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.blackGrey.withOpacity(0.7),
                ),
              ),
              Icon(
                icon,
                size: 18,
                color: AppColors.darkGrey.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

