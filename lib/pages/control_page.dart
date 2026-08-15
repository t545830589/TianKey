
import 'package:flutter/material.dart';
import '../services/mock_esp32.dart';


class ControlPage extends StatefulWidget {

  const ControlPage({super.key});


  @override
  State<ControlPage> createState() => _ControlPageState();

}



class _ControlPageState extends State<ControlPage> {


  final MockESP32 esp32 = MockESP32();


  String status = "等待操作";



  void execute(String command) {


    setState(() {

      status = "正在执行：$command";

    });



    Future.delayed(

      const Duration(seconds:1),

      () {


        String result =
            esp32.executeCommand(command);



        setState(() {


          status = result;


        });



      },

    );


  }






  @override
  Widget build(BuildContext context) {


    return Scaffold(


      appBar: AppBar(

        title: const Text(

          "车辆控制",

        ),

        centerTitle:true,

      ),




      body: Padding(


        padding:

        const EdgeInsets.all(20),



        child:Column(


          children:[




            const SizedBox(height:20),




            Text(

              status,

              style:

              const TextStyle(

                fontSize:18,

                color:Colors.cyan,

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

                  (){

                    execute("锁车");

                  },

                ),



                _controlButton(

                  "🔓",

                  "解锁",

                  (){

                    execute("解锁");

                  },

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

                  (){

                    execute("寻车");

                  },

                ),




                _controlButton(

                  "📦",

                  "后备箱",

                  (){


                    _confirmTrunk();


                  },

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

      VoidCallback action,

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



      onPressed: action,



      child:

      Column(


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



          Text(

            title,

          ),



        ],

      ),


    );

  }







  void _confirmTrunk(){



    showDialog(


      context:context,


      builder:(context){


        return AlertDialog(



          title:

          const Text(

            "确认打开后备箱？",

          ),



          actions:[



            TextButton(

              onPressed:(){

                Navigator.pop(context);

              },

              child:

              const Text(

                "取消",

              ),

            ),



            TextButton(

              onPressed:(){


                Navigator.pop(context);


                execute("后备箱");


              },

              child:

              const Text(

                "确定",

              ),

            ),



          ],

        );


      },


    );

  }



}
