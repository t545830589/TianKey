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



    if(!widget.esp32.isConnected()){


      setState(() {


        status = "设备未连接";


      });


      return;


    }




    if(!widget.esp32.adminAuthorized &&

       !widget.esp32.temporaryAuthorized){



      setState(() {


        status = "请先完成身份授权";


      });


      return;


    }






    setState(() {


      status = "正在执行：$command";


    });





    Future.delayed(

      const Duration(seconds:1),

      (){



        String result =

        widget.esp32.executeCommand(command);



        setState(() {


          status=result;


        });



      },

    );



  }







  @override
  Widget build(BuildContext context){



    bool admin =

    widget.esp32.adminAuthorized;



    bool temporary =

    widget.esp32.temporaryAuthorized;





    return Scaffold(



      appBar:AppBar(


        title:const Text(

          "车辆控制中心",

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

            ),





            const SizedBox(height:30),




            Wrap(


              spacing:15,

              runSpacing:15,



              children:[



                _button(

                  "🔒",

                  "锁车",

                  "锁车",

                ),




                _button(

                  "🔓",

                  "解锁",

                  "解锁",

                ),




                _button(

                  "🚗",

                  "寻车",

                  "寻车",

                ),






                if(admin)

                _button(

                  "📦",

                  "后备箱",

                  "后备箱",

                ),




              ],



            ),





            const SizedBox(height:30),





            if(!admin && !temporary)


            const Text(

              "无授权，无法控制车辆",

              style:

              TextStyle(

                color:Colors.redAccent,

              ),

            ),



          ],



        ),



      ),



    );


  }








  Widget _button(

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
