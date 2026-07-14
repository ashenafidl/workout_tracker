import "package:flutter/material.dart";

class AppTheme {
  ThemeData get light {
    return _buildTheme(.light);
  }

  ThemeData get dark {
    return _buildTheme(.dark);
  }

  ThemeData _buildTheme(Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
  }
}
