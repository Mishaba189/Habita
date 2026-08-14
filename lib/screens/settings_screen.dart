import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';


class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.light,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page Title
              Text(
                "Setting",
                style: GoogleFonts.nunito(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.blackGrey,
                ),
              ),
              const SizedBox(height: 24),

              // White Container Card containing options & integrated logout
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildSettingTile(
                      title: "Account",
                      onTap: () {
                        // Navigate to Account screen
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildSettingTile(
                      title: "Term and Condition",
                      onTap: () {
                        // Navigate to Terms screen
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildSettingTile(
                      title: "Policy",
                      onTap: () {
                        // Navigate to Policy screen
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildSettingTile(
                      title: "About App",
                      onTap: () {
                        // Navigate to About App screen
                      },
                    ),
                    const SizedBox(height: 12),
                    // Integrated Logout Option
                    _buildLogoutTile(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Individual Setting Tile Widget
  Widget _buildSettingTile({
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.blackGrey,
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.blackGrey,
            ),
          ],
        ),
      ),
    );
  }

  // Integrated Logout List Tile Widget
  Widget _buildLogoutTile(BuildContext context) {
    return GestureDetector(
      onTap: () => _showLogoutDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0EC), // Soft orange tint for destructive action contrast
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.logout_rounded,
                  size: 20,
                  color: AppColors.orange,
                ),
                const SizedBox(width: 10),
                Text(
                  "Logout",
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.orange,
                  ),
                ),
              ],
            ),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.orange,
            ),
          ],
        ),
      ),
    );
  }

  // Logout Confirmation Dialog
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFECE5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: AppColors.orange,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Logout",
                  style: GoogleFonts.nunito(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.blackGrey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Are you sure you want to log out of your account?",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: AppColors.darkGrey,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(color: AppColors.lightGrey),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          "Cancel",
                          style: GoogleFonts.nunito(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.blackGrey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          // Perform actual Logout logic here
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            gradient: AppColors.orangeGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              "Logout",
                              style: GoogleFonts.nunito(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
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
}