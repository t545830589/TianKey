import 'package:flutter/material.dart';
import '../services/mock_esp32.dart';


class HomePage extends StatefulWidget {

  const HomePage({super.key});


  @override
  State<HomePage> createState() => _HomePageState();

}



class _HomePageState extends State<HomePage> {


  final MockESP32 esp32 = MockESP32();


  String message = "设备未连接";



  void connectDevice(){


    setState(() {


      esp32.connectBLE();


      message = "BLE连接成功";


    });


  }





  void disconnectDevice(){


    setState(() {


      esp32.disconnectBLE();


      message = "BLE已断开";


    });


  }






  void control(String action){


    setState(() {


      message = esp32.executeCommand(action);


    });


  }





  @override
  Widget build(BuildContext context) {


    return Scaffold(


      backgroundColor: Colors.black,


      appBar: AppBar(


        backgroundColor: Colors.black,


        title: const Text(

          "Tian Key V11",

        ),


        centerTitle: true,


      ),




      body: SingleChildScrollView(


        padding: const EdgeInsets.all(20),


        child: Column(


          children: [




            Container(


              width: double.infinity,


              height: 170,


              decoration: BoxDecoration(


                borderRadius:

                BorderRadius.circular(20),


                color: Colors.grey[900],


              ),



              child: const Center(


                child: Text(


                  "车辆图片区域",


                  style: TextStyle(

                    color: Colors.grey,

                    fontSize:18,

                  ),

                ),

              ),


            ),





            const SizedBox(height:20),





            _card(


              "车辆信息",


              [

                "车牌：陕A0P92Y",

                "设备ID：${esp32.deviceId}",

              ],


            ),





            const SizedBox(height:15),





            _card(


              "当前状态",


              [

                "蓝牙：${esp32.isConnected() ? "已连接":"未连接"}",

                "身份：${esp32.getCurrentUser()}",

                "权限：${esp32.sessionRole}",

                "时间：已同步",

              ],


            ),






            const SizedBox(height:20),





            Row(


              mainAxisAlignment:

              MainAxisAlignment.spaceEvenly,


              children:[


                _bigButton(

                  "连接",

                  (){

                    connectDevice();

                  },

                ),



                _bigButton(

                  "断开",

                  (){

                    disconnectDevice();

                  },

                ),



              ],


            ),






            const SizedBox(height:20),






            Text(


              message,


              style:

              const TextStyle(

                color:Colors.cyan,

                fontSize:18,

              ),


            ),





            const SizedBox(height:25),






            Wrap(


              spacing:12,

              runSpacing:12,


              children:[



                _controlButton("锁车"),


                _controlButton("解锁"),


                _controlButton("升窗"),


                _controlButton("降窗"),


                _controlButton("寻车"),


                _controlButton("后备箱"),



              ],


            ),





          ],


        ),


      ),


    );


  }









  Widget _card(String title,List<String> items){


    return Container(


      width:double.infinity,


      padding:

      const EdgeInsets.all(15),


      decoration:

      BoxDecoration(


        color:Colors.grey[900],


        borderRadius:

        BorderRadius.circular(20),


      ),



      child:Column(


        crossAxisAlignment:

        CrossAxisAlignment.start,


        children:[



          Text(


            title,


            style:

            const TextStyle(

              color:Colors.white,

              fontSize:18,

              fontWeight:FontWeight.bold,

            ),


          ),



          const SizedBox(height:10),



          ...items.map(


                (e)=>Text(

              e,

              style:

              const TextStyle(

                color:Colors.grey,

              ),

            ),


          ),



        ],


      ),


    );


  }







  Widget _bigButton(String text,VoidCallback action){


    return ElevatedButton(


      onPressed:action,


      style:

      ElevatedButton.styleFrom(


        minimumSize:

        const Size(130,55),


      ),



      child:

      Text(text),


    );


  }







  Widget _controlButton(String text){


    return ElevatedButton(


      onPressed:(){


        control(text);


      },


      child:

      Text(text),


    );


  }




}
