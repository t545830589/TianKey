import 'package:flutter/material.dart';

import 'services/mock_esp32.dart';

import 'pages/home_page.dart';



void main() {

  WidgetsFlutterBinding.ensureInitialized();


  runApp(const TianKeyApp());

}




class TianKeyApp extends StatelessWidget {


  const TianKeyApp({super.key});



  // 全局唯一模拟ESP32车辆

  static final MockESP32 esp32 = MockESP32();




  @override
  Widget build(BuildContext context) {


    return MaterialApp(


      debugShowCheckedModeBanner:false,



      title:'Tian Key V11',



      theme:ThemeData(


        brightness:Brightness.dark,


        scaffoldBackgroundColor:Colors.black,


        fontFamily:'Arial',


      ),



      home: HomePage(

        esp32: esp32,

      ),



    );


  }



}
