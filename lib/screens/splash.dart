import 'package:flutter/material.dart';
import 'auth_screen.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  void initState() {
    super.initState();
    _navigateToSignUp();
  }

  void _navigateToSignUp() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AuthScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
