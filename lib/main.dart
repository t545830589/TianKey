import 'package:flutter/material.dart';

import 'pages/home_page.dart';


void main() {

  WidgetsFlutterBinding.ensureInitialized();

  runApp(const TianKeyApp());

}



class TianKeyApp extends StatelessWidget {

  const TianKeyApp({super.key});


  @override
  Widget build(BuildContext context) {


    return MaterialApp(

      debugShowCheckedModeBanner: false,


      title: 'Tian Key V11',


      theme: ThemeData(

        brightness: Brightness.dark,

        scaffoldBackgroundColor: Colors.black,


        fontFamily: 'Arial',


      ),


      home: const HomePage(),


    );


  }


}
