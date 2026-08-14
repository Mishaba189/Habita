import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/habit_provider.dart';
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
    await Future.delayed(const Duration(milliseconds: 800));

    final prefs = await SharedPreferences.getInstance();
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
      backgroundColor: AppColors.light, // Optional: match background color
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
