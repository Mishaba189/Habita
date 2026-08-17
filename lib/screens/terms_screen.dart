import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.light,
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar
            _buildHeader(context, "Term and Condition"),

            // Content Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Container(
                  padding: const EdgeInsets.all(20.0),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle("1. Acceptance of Terms"),
                      _buildSectionContent(
                        "By accessing and using this habit tracking application, you accept and agree to be bound by the terms and provision of this agreement.",
                      ),
                      const SizedBox(height: 16),
                      _buildSectionTitle("2. User Accounts"),
                      _buildSectionContent(
                        "You are responsible for safeguarding your account details, password, and for any activities or actions under your account. You agree to notify us immediately of any unauthorized use.",
                      ),
                      const SizedBox(height: 16),
                      _buildSectionTitle("3. Habit Tracking & Data"),
                      _buildSectionContent(
                        "Our app is designed to help you build and monitor personal habits and goals. While we strive for reliability, we do not guarantee uninterrupted availability or absolute data preservation.",
                      ),
                      const SizedBox(height: 16),
                      _buildSectionTitle("4. Modifications to Service"),
                      _buildSectionContent(
                        "We reserve the right to modify or discontinue, temporarily or permanently, the service with or without notice. Continued use of the app constitutes your agreement to such modifications.",
                      ),
                    ],
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


class PolicyScreen extends StatelessWidget {
  const PolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.light,
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar
            _buildHeader(context, "Policy"),

            // Content Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Container(
                  padding: const EdgeInsets.all(20.0),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle("1. Information Collection"),
                      _buildSectionContent(
                        "We collect information you provide directly to us when creating an account, such as your name and email address, as well as your habit creation and progress data.",
                      ),
                      const SizedBox(height: 16),
                      _buildSectionTitle("2. How We Use Information"),
                      _buildSectionContent(
                        "Your data is used solely to provide, maintain, and improve our habit tracking features, personalize your experience, and secure your account.",
                      ),
                      const SizedBox(height: 16),
                      _buildSectionTitle("3. Data Security"),
                      _buildSectionContent(
                        "We implement robust administrative, technical, and physical security measures to protect your personal information from unauthorized access or disclosure.",
                      ),
                      const SizedBox(height: 16),
                      _buildSectionTitle("4. Contact Us"),
                      _buildSectionContent(
                        "If you have any questions or concerns regarding our privacy practices, please feel free to reach out to our support team through the Help & Support section.",
                      ),
                    ],
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

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.light,
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar
            _buildHeader(context, "About App"),

            // Content Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24.0),
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
                          // App Logo Icon with Gradient
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: AppColors.orangeGradient,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.orange.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.track_changes_rounded,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Habita",
                            style: GoogleFonts.nunito(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.blackGrey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Version 1.0.0",
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.darkGrey,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            "Habita is your personal habit tracker designed to help you build great routines, break bad habits, and achieve your daily goals with style and consistency.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              color: AppColors.blackGrey,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}




// Reusable Top Page Header with Back Button
Widget _buildHeader(BuildContext context, String title) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
    child: Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
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
              size: 16,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          title,
          style: GoogleFonts.nunito(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.blackGrey,
          ),
        ),
      ],
    ),
  );
}

Widget _buildSectionTitle(String title) {
  return Text(
    title,
    style: GoogleFonts.nunito(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: AppColors.blackGrey,
    ),
  );
}

Widget _buildSectionContent(String content) {
  return Text(
    content,
    style: GoogleFonts.nunito(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: AppColors.darkGrey,
      height: 1.5,
    ),
  );
}