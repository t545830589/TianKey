import 'package:flutter/material.dart';

import '../services/mock_esp32.dart';
import '../services/mock_vehicle.dart';

import 'permission_page.dart';
import 'control_page.dart';
import 'log_page.dart';



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


  final MockVehicle vehicle = MockVehicle();




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

        builder:(context)=>

        PermissionPage(

          esp32:widget.esp32,

        ),

      ),

    ).then((value){

      setState(() {});

    });


  }








  void openControl(){

    Navigator.push(

      context,

      MaterialPageRoute(

        builder:(context)=>

        ControlPage(

          esp32:widget.esp32,

          vehicle:vehicle,

        ),

      ),

    );

}







  void openLog(){


    Navigator.push(

      context,

      MaterialPageRoute(

        builder:(context)=>

        LogPage(

          esp32:widget.esp32,

        ),

      ),

    );


  }







  @override
  Widget build(BuildContext context){



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


          crossAxisAlignment:

          CrossAxisAlignment.start,



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





            const SizedBox(height:25),





            Text(

              "🔋 电量：${vehicle.getBattery()}",

            ),





            Text(

              "🚪 车门：${vehicle.getDoorStatus()}",

            ),





            Text(

              "🔒 车锁：${vehicle.getLockStatus()}",

            ),





            Text(

              "🌡 温度：${vehicle.getTemperature()}",

            ),





            const SizedBox(height:25),






            Text(

              "蓝牙状态：${connected ? "已连接":"未连接"}",

            ),





            Text(

              "当前身份：${widget.esp32.getCurrentUser()}",

            ),





            Text(

              "设备ID：${widget.esp32.deviceId}",

            ),






            const SizedBox(height:25),





            ElevatedButton(

              onPressed:toggleConnection,

              child:Text(

                connected

                ?"断开设备"

                :"连接设备",

              ),

            ),






            const SizedBox(height:10),






            ElevatedButton(

              onPressed:openPermission,

              child:

              const Text(

                "权限管理",

              ),

            ),






            ElevatedButton(

              onPressed:openControl,

              child:

              const Text(

                "车辆控制中心",

              ),

            ),






            ElevatedButton(

              onPressed:openLog,

              child:

              const Text(

                "车辆日志",

              ),

            ),





          ],



        ),



      ),



    );


  }



}
