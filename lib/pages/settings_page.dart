
import 'package:flutter/material.dart';
import '../services/mock_esp32.dart';


class SettingsPage extends StatefulWidget {

  const SettingsPage({super.key});


  @override
  State<SettingsPage> createState() => _SettingsPageState();

}



class _SettingsPageState extends State<SettingsPage> {


  final MockESP32 esp32 = MockESP32();


  String carName = "陕A0P92Y";

  String bleName = "TianKey BLE";



  final TextEditingController carController =
      TextEditingController();


  final TextEditingController passwordController =
      TextEditingController();




  @override
  void initState(){

    super.initState();

    carController.text = carName;

  }





  @override
  Widget build(BuildContext context){


    return Scaffold(

      appBar: AppBar(

        title: const Text(
          "车辆设置",
        ),

        centerTitle:true,

      ),



      body: Padding(

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



            TextField(

              controller:carController,

              decoration:

              const InputDecoration(

                labelText:"车辆名称",

              ),

            ),




            const SizedBox(height:20),



            ElevatedButton(

              onPressed:(){


                setState((){


                  carName =
                    carController.text;


                });


              },


              child:const Text(

                "保存车辆名称",

              ),

            ),




            const SizedBox(height:30),




            const Text(

              "安全设置",

              style:TextStyle(

                fontSize:18,

                fontWeight:FontWeight.bold,

              ),

            ),




            TextField(

              controller:passwordController,

              obscureText:true,

              decoration:

              const InputDecoration(

                labelText:"修改管理员密码",

              ),

            ),




            const SizedBox(height:10),



            ElevatedButton(

              onPressed:(){


                setState((){});


              },


              child:const Text(

                "保存密码",

              ),

            ),




            const SizedBox(height:30),




            const Text(

              "ESP32设备信息",

              style:TextStyle(

                fontSize:18,

                fontWeight:FontWeight.bold,

              ),

            ),




            Text(

              "设备ID：${esp32.deviceId}",

            ),




            Text(

              "蓝牙名称：$bleName",

            ),



          ],


        ),

      ),

    );


  }



}
