
import 'package:flutter/material.dart';

import '../services/mock_esp32.dart';



class LogPage extends StatefulWidget {


  final MockESP32 esp32;


  const LogPage({

    super.key,

    required this.esp32,

  });



  @override
  State<LogPage> createState() => _LogPageState();


}




class _LogPageState extends State<LogPage> {



  @override
  Widget build(BuildContext context){


    List<String> logs = widget.esp32.getLogs();



    return Scaffold(



      appBar: AppBar(


        title: const Text(

          "车辆日志",

        ),


        centerTitle:true,


      ),




      body:Padding(


        padding:

        const EdgeInsets.all(20),




        child:logs.isEmpty



        ?const Center(


          child:Text(

            "暂无日志",

          ),

        )



        :ListView.builder(


          itemCount:logs.length,



          itemBuilder:(context,index){



            return Card(



              child:ListTile(



                leading:

                const Icon(

                  Icons.history,

                ),



                title:

                Text(

                  logs[index],

                ),



              ),


            );


          },


        ),


      ),



    );


  }



}
