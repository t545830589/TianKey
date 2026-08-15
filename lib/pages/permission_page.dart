import 'package:flutter/material.dart';
import '../services/mock_esp32.dart';



class PermissionPage extends StatefulWidget {


  final MockESP32 esp32;


  const PermissionPage({

    super.key,

    required this.esp32,

  });



  @override
  State<PermissionPage> createState() => _PermissionPageState();


}





class _PermissionPageState extends State<PermissionPage> {



  final TextEditingController passwordController =
      TextEditingController();



  String message = "";





  void adminLogin(){


    bool ok = widget.esp32.adminLogin(

      passwordController.text,

    );



    setState(() {


      if(ok){


        message = "管理员授权成功";


      }else{


        message = "管理员密码错误";


      }


    });


  }







  void temporaryLogin(){


    bool ok = widget.esp32.temporaryLogin(

      passwordController.text,

    );



    setState(() {



      if(ok){


        message = "临时借车授权成功";


      }else{


        message = "临时密码错误";


      }



    });


  }








  String formatDate(DateTime? time){


    if(time == null){

      return "无";

    }


    return

    "${time.year}-${time.month}-${time.day} "

    "${time.hour}:${time.minute}";


  }








  @override
  Widget build(BuildContext context) {


    return Scaffold(


      backgroundColor:Colors.black,



      appBar:AppBar(


        title:const Text(

          "权限管理",

        ),


        centerTitle:true,


      ),






      body:Padding(


        padding:const EdgeInsets.all(20),



        child:Column(


          crossAxisAlignment:

          CrossAxisAlignment.start,



          children:[



            Text(

              "当前身份：${widget.esp32.getCurrentUser()}",

              style:

              const TextStyle(

                color:Colors.cyan,

                fontSize:20,

              ),

            ),




            const SizedBox(height:10),




            Text(

              "权限类型：${widget.esp32.sessionRole}",

            ),





            const SizedBox(height:10),





            Text(

              "临时状态：${widget.esp32.temporaryAuthorizationStatus}",

            ),






            const SizedBox(height:20),






            TextField(


              controller:passwordController,


              obscureText:true,


              decoration:

              const InputDecoration(

                labelText:"输入密码",

              ),



            ),





            const SizedBox(height:20),






            Row(

              children:[


                Expanded(

                  child:ElevatedButton(

                    onPressed:adminLogin,

                    child:

                    const Text(

                      "管理员授权",

                    ),

                  ),

                ),



                const SizedBox(width:10),



                Expanded(

                  child:ElevatedButton(

                    onPressed:temporaryLogin,

                    child:

                    const Text(

                      "临时借车",

                    ),

                  ),

                ),



              ],

            ),





            const SizedBox(height:20),





            Text(

              message,

              style:

              const TextStyle(

                color:Colors.greenAccent,

              ),

            ),





            const SizedBox(height:20),





            Text(

              "临时时间",

              style:

              const TextStyle(

                fontSize:18,

              ),

            ),





            Text(

              "开始：${formatDate(widget.esp32.temporaryStart)}",

            ),



            Text(

              "结束：${formatDate(widget.esp32.temporaryEnd)}",

            ),





          ],


        ),


      ),


    );


  }



}
