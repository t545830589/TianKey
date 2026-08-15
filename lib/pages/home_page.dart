import 'package:flutter/material.dart';
import '../services/mock_esp32.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});


  @override
  State<HomePage> createState() => _HomePageState();
}



class _HomePageState extends State<HomePage> {

  final MockESP32 esp32 = MockESP32();


  bool connected = false;


  void toggleConnection(){

    setState(() {

      if(connected){

        esp32.disconnectBLE();

        connected = false;

      }else{

        esp32.connectBLE();

        connected = true;

      }

    });

  }




  @override
  Widget build(BuildContext context) {


    return Scaffold(

      appBar: AppBar(

        title: const Text('Tian Key V11'),

        centerTitle: true,

      ),


      body: Padding(

        padding: const EdgeInsets.all(20),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [


            const Text(
              '车辆信息',
              style: TextStyle(
                fontSize:18,
                fontWeight:FontWeight.bold,
              ),
            ),



            const SizedBox(height:10),



            const Text(

              '陕A0P92Y',

              style:TextStyle(

                fontSize:22,

                color:Colors.cyan,

              ),

            ),



            const SizedBox(height:20),



            const Text(

              '当前状态',

              style:TextStyle(

                fontSize:18,

                fontWeight:FontWeight.bold,

              ),

            ),



            const SizedBox(height:10),



            _buildStatusRow(

              '蓝牙',

              connected ? '已连接' : '未连接',

            ),



            _buildStatusRow(

              '管理员',

              '未授权',

            ),



            _buildStatusRow(

              '时间',

              '未同步',

            ),



            const SizedBox(height:30),



            ElevatedButton(

              onPressed: toggleConnection,

              child: Text(

                connected ? '断开车辆' : '连接车辆',

              ),

            ),



            const SizedBox(height:30),



            const Text(

              '控制操作',

              style:TextStyle(

                fontSize:16,

                color:Colors.grey,

              ),

            ),



            const SizedBox(height:15),



            Row(

              mainAxisAlignment:MainAxisAlignment.spaceEvenly,

              children:[


                _buildButton('锁车'),

                _buildButton('解锁'),

                _buildButton('寻车'),

                _buildButton('后备箱'),


              ],

            ),


          ],


        ),

      ),

    );

  }





  Widget _buildStatusRow(String label,String value){

    return Padding(

      padding:const EdgeInsets.symmetric(vertical:4),

      child:Row(

        children:[

          Text(

            '$label：',

            style:const TextStyle(

              color:Colors.grey,

            ),

          ),


          Text(

            value,

            style:const TextStyle(

              color:Colors.white,

            ),

          ),


        ],

      ),

    );

  }





  Widget _buildButton(String text){

    return ElevatedButton(

      onPressed:null,

      child:Text(text),

    );

  }


}
