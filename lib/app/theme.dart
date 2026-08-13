
import 'package:flutter/material.dart';


class TianKeyTheme {


  static ThemeData darkTheme = ThemeData(


    brightness: Brightness.dark,


    scaffoldBackgroundColor: Colors.black,


    primaryColor: const Color(0xff0A1628),



    colorScheme: const ColorScheme.dark(


      primary: Color(0xffD4AF37),


      secondary: Color(0xff003B73),


      surface: Color(0xff050505),


    ),



    textTheme: const TextTheme(


      titleLarge: TextStyle(

        color: Color(0xffD4AF37),

        fontSize: 28,

        fontWeight: FontWeight.bold,

      ),



      titleMedium: TextStyle(

        color: Colors.white,

        fontSize: 20,

        fontWeight: FontWeight.w600,

      ),



      bodyMedium: TextStyle(

        color: Colors.white70,

        fontSize: 16,

      ),



    ),



    elevatedButtonTheme: ElevatedButtonThemeData(


      style: ElevatedButton.styleFrom(


        backgroundColor: Color(0xff0A1628),


        foregroundColor: Color(0xffD4AF37),


        shape: RoundedRectangleBorder(


          borderRadius: BorderRadius.circular(12),


        ),



      ),


    ),



  );


}
