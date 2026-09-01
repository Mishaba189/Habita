import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:habita/providers/auth_provider.dart';
import 'package:habita/providers/habit_provider.dart';
import 'package:habita/providers/notification_provider.dart';
import 'package:habita/providers/report_provider.dart';
import 'package:habita/screens/splash.dart';
import 'package:habita/services/notification_services.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initNotifications();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase init failed (expected if keys are placeholders): $e");
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => HabitProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habita',
      debugShowCheckedModeBanner: false,
      home: const Splash(),
    );
  }
}

