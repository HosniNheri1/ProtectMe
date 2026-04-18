import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: Color.fromARGB(255, 217, 53, 229),
      primaryColorDark: Color.fromARGB(255, 181, 28, 183),
      primaryColorLight: Color(0xFFFFCDD2),
      scaffoldBackgroundColor: Color(0xFFFAFAFA),
      cardColor: Colors.white,
      brightness: Brightness.light,

      appBarTheme: AppBarTheme(
        backgroundColor: Color.fromARGB(255, 229, 53, 223),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),

      buttonTheme: ButtonThemeData(
        buttonColor: Color.fromARGB(255, 226, 53, 229),
        textTheme: ButtonTextTheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color.fromARGB(255, 220, 53, 229),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: Color.fromARGB(255, 226, 53, 229)),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Color.fromARGB(255, 203, 53, 229),
          side: BorderSide(color: Color.fromARGB(255, 206, 53, 229)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Color.fromARGB(255, 229, 53, 226), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(8),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey.shade100,
        selectedColor: Color.fromARGB(255, 220, 53, 229),
        secondarySelectedColor: Color.fromARGB(255, 229, 53, 197),
        labelStyle: TextStyle(color: Colors.black),
        secondaryLabelStyle: TextStyle(color: Colors.white),
        brightness: Brightness.light,
        padding: EdgeInsets.symmetric(horizontal: 12),
        shape: StadiumBorder(),
      ),

      colorScheme: ColorScheme.light(
        primary: Color.fromARGB(255, 223, 53, 229),
        secondary: Color(0xFF1976D2),
        surface: Colors.white,
        error: Color.fromARGB(255, 197, 47, 211),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.black,
        onError: Colors.white,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      primaryColor: Color.fromARGB(255, 223, 53, 229),
      primaryColorDark: Color.fromARGB(255, 183, 28, 175),
      primaryColorLight: Color(0xFFFFCDD2),
      scaffoldBackgroundColor: Color(0xFF121212),
      cardColor: Color(0xFF1E1E1E),
      brightness: Brightness.dark,

      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),

      buttonTheme: ButtonThemeData(
        buttonColor: Color.fromARGB(255, 228, 2, 221),
        textTheme: ButtonTextTheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color.fromARGB(255, 200, 53, 229),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: Color.fromARGB(255, 191, 53, 229)),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Color.fromARGB(255, 229, 53, 206),
          side: BorderSide(color: Color.fromARGB(255, 229, 53, 226)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Color.fromARGB(255, 203, 53, 229), width: 2),
        ),
        filled: true,
        fillColor: Color(0xFF2D2D2D),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(8),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: Color(0xFF2D2D2D),
        selectedColor: Color.fromARGB(255, 229, 53, 170),
        secondarySelectedColor: Color.fromARGB(255, 214, 53, 229),
        labelStyle: TextStyle(color: Colors.white),
        secondaryLabelStyle: TextStyle(color: Colors.white),
        brightness: Brightness.dark,
        padding: EdgeInsets.symmetric(horizontal: 12),
        shape: StadiumBorder(),
      ),

      colorScheme: ColorScheme.dark(
        primary: Color.fromARGB(255, 229, 53, 161),
        secondary: Color(0xFF1976D2),
        surface: Color(0xFF1E1E1E),
        error: Color.fromARGB(255, 211, 47, 194),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onError: Colors.white,
      ),
    );
  }
}
