import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const String fontFamily = 'InriaSans';

// LightMode
ThemeData themeDataLightMode = ThemeData(
  fontFamily: fontFamily,
  brightness: Brightness.light,
  colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromRGBO(245, 245, 245, 1), brightness: Brightness.light).copyWith(
    primary: const Color.fromRGBO(51, 51, 51, 1),
    secondary: const Color.fromRGBO(0, 128, 128, 1),
    //secondary: Colors.pink.shade400,
    inversePrimary: const Color.fromRGBO(135, 206, 235, 1),
    tertiary: Colors.blueAccent,



  )
);

// DarkMode
ThemeData themeDataDarkMode = ThemeData(
    fontFamily: fontFamily,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromRGBO(28, 28, 28, 1), brightness: Brightness.dark).copyWith(
      primary: const Color.fromRGBO(224, 224, 224, 1),
      secondary: const Color.fromRGBO(46, 245, 181, 1),
      //secondary: Colors.pink.shade400,
      inversePrimary: const Color.fromRGBO(0, 123, 255, 1),
      tertiary: Colors.blueAccent,
    )
);