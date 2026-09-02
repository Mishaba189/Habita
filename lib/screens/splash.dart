import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/habit_provider.dart';
import '../services/app_version_services.dart';
import 'auth_screen.dart';
import 'bottom_menu.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  void initState() {
    super.initState();
    _checkSessionAndNavigate();
  }

  void _checkSessionAndNavigate() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isFirstTime = prefs.getBool('is_first_time') ?? true;

    // 1. Request permissions FIRST on launch
    if (mounted && isFirstTime) {
      final FlutterLocalNotificationsPlugin localNotifications =
      FlutterLocalNotificationsPlugin();

      final androidImplementation = localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      await androidImplementation?.requestNotificationsPermission();
      await androidImplementation?.requestExactAlarmsPermission();

      final iosImplementation = localNotifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      await iosImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

      await prefs.setBool('is_first_time', false);
    }

    // 2. CHECK APP VERSION HERE BEFORE NAVIGATING
    bool requiresUpdate = false;
    if (mounted) {
      requiresUpdate = await AppVersionService.isUpdateRequired(context);
    }

    if (requiresUpdate) {
      // Stop execution if update bottom sheet was shown
      return;
    }

    // 3. Short delay before proceeding to screen navigation
    await Future.delayed(const Duration(milliseconds: 800));

    // 4. Perform navigation
    final bool isLoggedIn = prefs.getBool('is_logged_in') ?? false;

    if (mounted) {
      if (isLoggedIn) {
        await Provider.of<HabitProvider>(context, listen: false).fetchHabits();
        await Provider.of<AuthProvider>(context, listen: false).fetchUserData();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => BottomMenu()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AuthScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.light,
      body: Center(
        child: Text(
          'Habita',
          style: TextStyle(
            fontSize: 60,
            fontWeight: FontWeight.w900,
            foreground: Paint()
              ..shader = const LinearGradient(
                colors: [
                  Color(0xFFFF5C00),
                  Color(0xFFFFA450),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ).createShader(
                const Rect.fromLTWH(0, 0, 300, 70),
              ),
          ),
        ),
      ),
    );
  }
}
