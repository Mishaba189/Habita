import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';


class AppVersionService {
  static Future<bool> isUpdateRequired(BuildContext context) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      int currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 1;

      final DatabaseReference ref = FirebaseDatabase.instanceFor(
        app: FirebaseDatabase.instance.app,
        databaseURL: 'https://habita-app-269b7-default-rtdb.asia-southeast1.firebasedatabase.app',
      ).ref('app_config');

      final DataSnapshot snapshot = await ref.get().timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('Database connection timed out'),
      );

      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        int latestVersion = int.tryParse(data['latestVersion'].toString()) ?? 0;
        String message = data['message'] ?? 'A new update is available. Please update to continue.';
        String updateUrl = data['updateUrl'] ?? '';

        if (latestVersion > currentBuildNumber && context.mounted) {
          _showUpdateBottomSheet(context, message, updateUrl);
          return true;
        }
      }
    } catch (e) {
      debugPrint("AppVersionService Error: $e");
    }
    return false;
  }

  static void _showUpdateBottomSheet(BuildContext context, String message, String updateUrl) {
    ValueNotifier<String> buttonText = ValueNotifier('Update Now');
    ValueNotifier<bool> isDownloading = ValueNotifier(false);

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: AppColors.light,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return PopScope(
          canPop: false,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Drag Handle Indicator
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.lightGrey,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Icon Box
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.orange.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.system_update_rounded,
                      size: 44,
                      color: AppColors.orange,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Text(
                    'Update Required',
                    style: GoogleFonts.nunito(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.blackGrey,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Message
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkGrey,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Action Button
                  ValueListenableBuilder<bool>(
                    valueListenable: isDownloading,
                    builder: (context, downloading, child) {
                      return Container(
                        width: double.infinity,
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: AppColors.orangeGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.orange.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: downloading
                              ? null
                              : () async {
                            isDownloading.value = true;
                            buttonText.value = 'Starting...';

                            try {
                              final dir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
                              final filePath = '${dir.path}/habita_update.apk';

                              final dio = Dio();
                              await dio.download(
                                updateUrl,
                                filePath,
                                onReceiveProgress: (received, total) {
                                  if (total > 0) {
                                    int percentage = ((received / total) * 100).toInt();
                                    buttonText.value = 'Downloading: $percentage%';
                                  } else {
                                    buttonText.value = 'Downloading...';
                                  }
                                },
                              );

                              buttonText.value = 'Installing...';
                              final result = await OpenFilex.open(filePath);

                              if (result.type != ResultType.done) {
                                buttonText.value = 'Failed. Tap to Retry';
                                isDownloading.value = false;
                              }
                            } catch (e) {
                              debugPrint("Download Error: $e");
                              isDownloading.value = false;
                              buttonText.value = 'Failed. Tap to Retry';
                            }
                          },
                          child: ValueListenableBuilder<String>(
                            valueListenable: buttonText,
                            builder: (context, label, child) {
                              return Text(
                                label,
                                style: GoogleFonts.nunito(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.light,
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}