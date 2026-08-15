import 'package:flutter/material.dart';
import 'pages/main_page.dart';


void main(){

  WidgetsFlutterBinding.ensureInitialized();

  runApp(const TianKeyApp());

}



class TianKeyApp extends StatelessWidget{

  const TianKeyApp({super.key});


  @override
  Widget build(BuildContext context){

    return MaterialApp(

      debugShowCheckedModeBanner:false,

      title:"Tian Key",

      theme:ThemeData(

        brightness:Brightness.dark,

        scaffoldBackgroundColor:Colors.black,

        colorScheme:ColorScheme.dark(

          primary:Colors.blueAccent,

        ),

      ),


      home:const MainPage(),

    );

  }


}
