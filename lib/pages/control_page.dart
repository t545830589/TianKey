import 'package:flutter/material.dart';

import '../services/mock_esp32.dart';
import '../services/mock_vehicle.dart';



class ControlPage extends StatefulWidget {


  final MockESP32 esp32;


  final MockVehicle vehicle;


  const ControlPage({

    super.key,

    required this.esp32,

    required this.vehicle,

  });



  @override
  State<ControlPage> createState() => _ControlPageState();


}





class _ControlPageState extends State<ControlPage> {


  String status = "等待操作";




  void execute(String command){


    setState(() {



      if(command=="锁车"){


        widget.vehicle.lockCar();


      }




      if(command=="解锁"){


        widget.vehicle.unlockCar();


      }




      if(command=="后备箱"){


        widget.vehicle.openDoor();


      }




      status =

      widget.esp32.executeCommand(command);



    });


  }







  @override
  Widget build(BuildContext context){



    return Scaffold(



      appBar:AppBar(

        title:

        const Text(

          "车辆控制",

        ),

      ),




      body:Center(



        child:Column(



          mainAxisAlignment:

          MainAxisAlignment.center,



          children:[




            Text(

              status,

              style:

              const TextStyle(

                color:Colors.cyan,

                fontSize:20,

              ),

            ),





            const SizedBox(height:40),






            ElevatedButton(

              onPressed:(){

                execute("锁车");

              },

              child:

              const Text(

                "🔒 锁车",

              ),

            ),





            ElevatedButton(

              onPressed:(){

                execute("解锁");

              },

              child:

              const Text(

                "🔓 解锁",

              ),

            ),





            ElevatedButton(

              onPressed:(){

                execute("寻车");

              },

              child:

              const Text(

                "🚗 寻车",

              ),

            ),





            ElevatedButton(

              onPressed:(){

                execute("后备箱");

              },

              child:

              const Text(

                "📦 后备箱",

              ),

            ),




          ],


        ),



      ),



    );


  }



}
