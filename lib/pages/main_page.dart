import 'package:flutter/material.dart';

import 'home_page.dart';
import 'permission_page.dart';
import 'settings_page.dart';


class MainPage extends StatefulWidget{


  const MainPage({super.key});


  @override
  State<MainPage> createState()=>_MainPageState();


}




class _MainPageState extends State<MainPage>{


  int index=0;



  final pages=[


    const HomePage(),


    const PermissionPage(),


    const SettingsPage(),



  ];





  @override
  Widget build(BuildContext context){


    return Scaffold(



      body:pages[index],




      bottomNavigationBar:BottomNavigationBar(


        currentIndex:index,


        backgroundColor:Colors.black,


        selectedItemColor:Colors.blueAccent,


        unselectedItemColor:Colors.grey,



        onTap:(i){


          setState((){


            index=i;


          });


        },



        items:[



          const BottomNavigationBarItem(

            icon:Icon(Icons.home),

            label:"首页",

          ),




          const BottomNavigationBarItem(

            icon:Icon(Icons.people),

            label:"权限",

          ),




          const BottomNavigationBarItem(

            icon:Icon(Icons.settings),

            label:"设置",

          ),



        ],



      ),


    );


  }


}
