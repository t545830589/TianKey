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


  String role = "请选择身份";


  final TextEditingController passwordController =
      TextEditingController();



  String result = "";




  void adminLogin(){


    bool success = widget.esp32.adminLogin(

      passwordController.text,

    );



    setState(() {


      role = "管理员";


      if(success){


        result = "管理员授权成功";


      }else{


        result = "管理员密码错误";


      }


    });


  }






  void temporaryLogin(){


    bool success = widget.esp32.temporaryLogin(

      passwordController.text,

    );



    setState(() {


      role = "临时借车";


      if(success){


        result = "临时借车授权成功\n有效时间8小时";


      }else{


        result = "临时密码错误";


      }


    });


  }






  @override
  Widget build(BuildContext context) {


    return Scaffold(


      backgroundColor: Colors.black,



      appBar: AppBar(


        backgroundColor: Colors.black,


        title: const Text(

          "权限授权",

        ),


        centerTitle:true,


      ),





      body: Padding(


        padding:

        const EdgeInsets.all(20),



        child:Column(


          crossAxisAlignment:

          CrossAxisAlignment.start,



          children:[



            const Text(

              "请选择连接身份",

              style:

              TextStyle(

                color:Colors.white,

                fontSize:20,

                fontWeight:

                FontWeight.bold,

              ),

            ),




            const SizedBox(height:20),






            Row(


              children:[



                Expanded(


                  child:

                  ElevatedButton(


                    onPressed:(){


                      setState(() {


                        role="管理员";


                      });


                    },


                    child:

                    const Text(

                      "管理员",

                    ),


                  ),


                ),




                const SizedBox(width:15),





                Expanded(


                  child:

                  ElevatedButton(


                    onPressed:(){


                      setState(() {


                        role="临时借车";


                      });


                    },


                    child:

                    const Text(

                      "临时借车",

                    ),


                  ),


                ),



              ],


            ),






            const SizedBox(height:30),





            Text(


              "当前选择：$role",


              style:

              const TextStyle(

                color:Colors.cyan,

                fontSize:18,

              ),


            ),






            const SizedBox(height:20),






            TextField(


              controller:

              passwordController,



              obscureText:true,



              style:

              const TextStyle(

                color:Colors.white,

              ),



              decoration:

              const InputDecoration(


                labelText:"请输入密码",


                labelStyle:

                TextStyle(

                  color:Colors.grey,

                ),


                enabledBorder:

                UnderlineInputBorder(


                  borderSide:

                  BorderSide(

                    color:Colors.grey,

                  ),

                ),

              ),



            ),







            const SizedBox(height:30),





            SizedBox(


              width:

              double.infinity,



              child:

              ElevatedButton(


                onPressed:(){



                  if(role=="管理员"){



                    adminLogin();



                  }else if(role=="临时借车"){



                    temporaryLogin();



                  }



                },



                child:

                const Text(

                  "确认授权",

                ),



              ),



            ),






            const SizedBox(height:30),






            Text(


              result,


              style:

              const TextStyle(

                color:Colors.greenAccent,

                fontSize:18,

              ),



            ),




          ],



        ),



      ),



    );


  }



}
