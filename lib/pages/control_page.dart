import 'package:flutter/material.dart';

import '../services/mock_esp32.dart';



class ControlPage extends StatefulWidget {


  final MockESP32 esp32;


  const ControlPage({

    super.key,

    required this.esp32,

  });



  @override
  State<ControlPage> createState() => _ControlPageState();


}




class _ControlPageState extends State<ControlPage> {



  String status = "等待操作";




  void execute(String command){



    setState(() {


      status = "正在执行：$command";


    });




    Future.delayed(

      const Duration(seconds:1),

      (){


        String result =

        widget.esp32.executeCommand(command);



        setState(() {


          status = result;


        });


      },


    );


  }






  @override
  Widget build(BuildContext context){



    return Scaffold(



      appBar:AppBar(


        title:const Text(

          "车辆控制",

        ),


        centerTitle:true,


      ),




      body:Padding(


        padding:const EdgeInsets.all(20),



        child:Column(


          children:[



            Text(

              "当前身份：${widget.esp32.getCurrentUser()}",

              style:

              const TextStyle(

                color:Colors.cyan,

                fontSize:18,

              ),

            ),




            const SizedBox(height:10),




            Text(

              status,

              style:

              const TextStyle(

                fontSize:18,

              ),

            ),





            const SizedBox(height:40),




            Row(


              mainAxisAlignment:

              MainAxisAlignment.spaceEvenly,


              children:[



                _controlButton(

                  "🔒",

                  "锁车",

                  "锁车",

                ),



                _controlButton(

                  "🔓",

                  "解锁",

                  "解锁",

                ),



              ],


            ),





            const SizedBox(height:40),





            Row(


              mainAxisAlignment:

              MainAxisAlignment.spaceEvenly,


              children:[



                _controlButton(

                  "🚗",

                  "寻车",

                  "寻车",

                ),



                _controlButton(

                  "📦",

                  "后备箱",

                  "后备箱",

                ),



              ],


            ),



          ],



        ),



      ),



    );


  }







  Widget _controlButton(

      String icon,

      String title,

      String command,

      ){



    return ElevatedButton(



      style:

      ElevatedButton.styleFrom(


        minimumSize:

        const Size(130,130),



        shape:

        RoundedRectangleBorder(

          borderRadius:

          BorderRadius.circular(30),

        ),


      ),




      onPressed:(){


        execute(command);


      },



      child:Column(


        mainAxisAlignment:

        MainAxisAlignment.center,


        children:[



          Text(

            icon,

            style:

            const TextStyle(

              fontSize:40,

            ),

          ),



          const SizedBox(height:10),



          Text(title),



        ],


      ),


    );


  }



}
