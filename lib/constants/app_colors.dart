import 'package:flutter/material.dart';


class AppColors {
  static const Color orange = Color(0xFFFF5C00);
  static const Color green = Color(0xFF37C871);
  static const Color blackGrey = Color(0xFF2F2F2F);
  static const Color grey = Color(0xFFFBFBFB);
  static const Color yellow = Color(0xFFFDD2AB);

  static const LinearGradient orangeGradient = LinearGradient(
    colors: [Color(0xFFFF5C00), Color(0xFFFFA450)],
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF37C871), Color(0xFF5FE394)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}