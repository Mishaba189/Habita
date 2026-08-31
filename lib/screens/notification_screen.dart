import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import 'package:provider/provider.dart';

import '../providers/notification_provider.dart';


class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.light,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.maybePop(context),
                        child: const Icon(
                          Icons.arrow_back,
                          color: AppColors.blackGrey,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Notifications",
                        style: GoogleFonts.nunito(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.blackGrey,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => context.read<NotificationProvider>().markAllAsRead(),
                    child: Text(
                      "Mark all as read",
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.orange,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Dynamic List
              Expanded(
                child: Consumer<NotificationProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (provider.notifications.isEmpty) {
                      return Center(
                        child: Text(
                          "No notifications yet",
                          style: GoogleFonts.nunito(color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: provider.notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = provider.notifications[index];
                        return GestureDetector(
                          onTap: () => provider.markAsRead(item.id),
                          child: _buildNotificationCard(
                            type: item.type,
                            title: item.title,
                            message: item.message,
                            time: _formatTimeAgo(item.createdAt),
                            isRead: item.isRead,
                            isSuccess: item.isSuccess,
                            status: item.status,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard({
    required String type,
    required String title,
    required String message,
    required String time,
    required bool isRead,
    required bool isSuccess,
    required String status,
  }) {
    IconData iconData;
    Color iconColor;
    Color iconBgColor;
    Color badgeColor;
    Color badgeTextColor;

    switch (type) {
      case 'goal_completed':
        if (isSuccess) {
          iconData = Icons.task_alt_rounded;
          iconColor = const Color(0xFF37C871);
          iconBgColor = const Color(0xFFEDFFF4);
          badgeColor = const Color(0xFFEDFFF4);
          badgeTextColor = const Color(0xFF37C871);
        } else {
          iconData = Icons.cancel_outlined;
          iconColor = const Color(0xFFFF4D4D);
          iconBgColor = const Color(0xFFFFEBEB);
          badgeColor = const Color(0xFFFFEBEB);
          badgeTextColor = const Color(0xFFFF4D4D);
        }
        break;

      case 'target_date_reminder':
      case 'nightly_missed_reminder':
      case 'day_end_reminder':
        iconData = Icons.access_time_filled_rounded;
        iconColor = AppColors.orange;
        iconBgColor = const Color(0xFFFFF0E6);
        badgeColor = const Color(0xFFFFF0E6);
        badgeTextColor = AppColors.orange;
        break;

      case 'new_goal_created':
      default:
        iconData = Icons.add_task_rounded;
        iconColor = const Color(0xFF2F80ED);
        iconBgColor = const Color(0xFFEDF5FF);
        badgeColor = const Color(0xFFEDF5FF);
        badgeTextColor = const Color(0xFF2F80ED);
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRead
              ? const Color(0xFFEBEBEB)
              : (isSuccess ? AppColors.yellow.withValues(alpha: 0.5) : const Color(0xFFFFCCCC)),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(iconData, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.blackGrey,
                        ),
                      ),
                    ),
                    Text(
                      time,
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status,
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: badgeTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}