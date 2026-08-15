import 'package:flutter/material.dart';

import '../services/mock_esp32.dart';
import 'permission_page.dart';



class HomePage extends StatefulWidget {


  final MockESP32 esp32;


  const HomePage({

    super.key,

    required this.esp32,

  });



  @override
  State<HomePage> createState() => _HomePageState();


}




class _HomePageState extends State<HomePage> {



  bool connected = false;



  void toggleConnection(){


    setState(() {


      if(connected){


        widget.esp32.disconnectBLE();


        connected = false;


      }else{


        widget.esp32.connectBLE();


        connected = true;


      }


    });


  }






  void openPermission(){


    Navigator.push(


      context,


      MaterialPageRoute(


        builder:(context)=>PermissionPage(

          esp32:widget.esp32,

        ),


      ),


    ).then((value){


      setState(() {});


    });


  }







  @override
  Widget build(BuildContext context) {


    return Scaffold(


      appBar:AppBar(


        title:const Text(

          "Tian Key V11",

        ),


        centerTitle:true,


      ),





      body:Padding(


        padding:const EdgeInsets.all(20),



        child:Column(


          crossAxisAlignment:CrossAxisAlignment.start,


          children:[




            const Text(

              "车辆信息",

              style:TextStyle(

                fontSize:18,

                fontWeight:FontWeight.bold,

              ),

            ),




            const SizedBox(height:10),




            const Text(

              "陕A0P92Y",

              style:TextStyle(

                fontSize:24,

                color:Colors.cyan,

              ),

            ),




            const SizedBox(height:30),




            Text(

              "蓝牙状态：${connected ? "已连接":"未连接"}",

            ),




            const SizedBox(height:10),




            Text(

              "当前身份：${widget.esp32.getCurrentUser()}",

            ),




            const SizedBox(height:10),




            Text(

              "设备ID：${widget.esp32.deviceId}",

            ),





            const SizedBox(height:30),





            ElevatedButton(

              onPressed:toggleConnection,

              child:Text(

                connected

                ?"断开设备"

                :"连接设备",

              ),

            ),




            const SizedBox(height:15),





            ElevatedButton(


              onPressed:openPermission,


              child:const Text(

                "权限管理",

              ),


            ),





            const SizedBox(height:30),





            const Text(

              "车辆控制",

              style:TextStyle(

                fontSize:18,

                fontWeight:FontWeight.bold,

              ),

            ),





            const SizedBox(height:15),




            Wrap(

              spacing:10,

              runSpacing:10,


              children:[


                _button("锁车"),

                _button("解锁"),

                _button("寻车"),

                _button("后备箱"),


              ],


            )



          ],


        ),


      ),


    );


  }








  Widget _button(String text){


    return ElevatedButton(


      onPressed:(){



        widget.esp32.executeCommand(text);


        setState(() {});


      },


      child:Text(text),


    );


  }



}
