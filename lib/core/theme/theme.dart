import 'package:flutter/material.dart';

class AppTheme {
  static const lightColorScheme = ColorScheme(
  brightness: Brightness.light, 
  primary: Color(0xFFF44336), 
  onPrimary: Color(0xFFFFFFFF), 
  secondary: Color(0xFF6EAEE7), 
  onSecondary: Color(0xFFFFFFFF), 
  error: Color(0xFFBA1A1A), 
  onError: Color(0xFFFFFFFF), 
  background: Color(0xFFFCFDF6), 
  onBackground: Color(0xFF1A1C18), 
  surface: Color(0xFFF9FAF3), 
  onSurface: Color(0xFF1A1C18)
  );

  static const darkColorscheme = ColorScheme(
  brightness: Brightness.dark, 
  primary: Color(0xFFF44336), 
  onPrimary: Color(0xFFFFFFFF), 
  secondary: Color(0xFF6EAEE7), 
  onSecondary: Color(0xFFFFFFFF), 
  error: Color(0xFFBA1A1A), 
  onError: Color(0xFFFFFFFF), 
  background: Color(0xFFFCFDF6), 
  onBackground: Color(0xFF1A1C18), 
  surface: Color(0xFFF9FAF3), 
  onSurface: Color(0xFF1A1C18)
  );

  ThemeData lightMode = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: lightColorScheme,
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: MaterialStateProperty.all<Color>(Colors.black),
      foregroundColor: 
      MaterialStateProperty.all<Color>(Colors.white),
      elevation: MaterialStateProperty.all<double>(5.0),
      padding: MaterialStateProperty.all<EdgeInsets>(
        const EdgeInsets.symmetric(horizontal: 20, vertical: 18)),
      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)
        )
      )
      )
    )
  );

  ThemeData darkMode =ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: darkColorscheme,
);


  static const Color primaryColor = Color(0xFFF44336);
  static const Color secondaryColor = Color(0xFF6EAEE7);

  static const TextStyle headline1 = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );

  static const TextStyle headline2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );

  static const TextStyle bodyText1 = TextStyle(
    fontSize: 16,
    color: Colors.black,
  );

  static const TextStyle bodyText2 = TextStyle(
    fontSize: 14,
    color: Colors.black,
  );

  static const LinearGradient gradient = LinearGradient(
    colors: [primaryColor, secondaryColor],
  );
  //button theme to use the linear gradient
  static ButtonStyle elevatedButtonStyle = ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    foregroundColor: Colors.white, // Text color
    backgroundColor: const Color(0xFF310EF1), // Background color
    side: const BorderSide(color: Colors.transparent), // Border color
  );

  static ElevatedButtonThemeData elevatedButtonTheme = ElevatedButtonThemeData(
    style: elevatedButtonStyle,
  );
  //add the app bar theme
  static const AppBarTheme appBarTheme =
      AppBarTheme(color: primaryColor, centerTitle: true);
  static ThemeData get theme => ThemeData(
        primaryColor: primaryColor,
        textTheme: const TextTheme(
          displayLarge: AppTheme.bodyText1,
          displayMedium: AppTheme.bodyText2,
        ),
        appBarTheme: appBarTheme,
        elevatedButtonTheme: elevatedButtonTheme,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
            foregroundColor: MaterialStateProperty.all(primaryColor),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: ButtonStyle(
            foregroundColor: MaterialStateProperty.all(primaryColor),
            overlayColor:
                MaterialStateProperty.all(primaryColor.withOpacity(0.1)),
          ),
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        dividerTheme: const DividerThemeData(
          thickness: 1,
          color: Color(0xFFE20E0E),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: primaryColor,
          unselectedItemColor: Color(0xFFF44336),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primaryColor,
        ),
      );
}