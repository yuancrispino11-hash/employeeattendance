import 'package:flutter/material.dart';

class AppTheme {
  static const bgDark = Color(0xFF0F172A);
  static const cardDark = Color(0xFF1E293B);
  static const primaryBlue = Color(0xFF1E3A8A);
  static const border = Color(0xFF334155);

  static InputDecoration inputDecoration({
    required String label,
    String? hint,
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: Colors.white70),
      hintStyle: const TextStyle(color: Colors.white38),
      prefixIcon:
          icon != null ? Icon(icon, color: Colors.white54, size: 20) : null,
      filled: true,
      fillColor: bgDark,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.blueAccent),
      ),
    );
  }
}
