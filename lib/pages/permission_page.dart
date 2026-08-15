
import 'package:flutter/material.dart';
import '../services/mock_esp32.dart';


class PermissionPage extends StatefulWidget {

  const PermissionPage({super.key});


  @override
  State<PermissionPage> createState() => _PermissionPageState();

}



class _PermissionPageState extends State<PermissionPage> {


  final MockESP32 esp32 = MockESP32();



  @override
  Widget build(BuildContext context) {


    return Scaffold(

      appBar: AppBar(

        title: const Text(
          '权限管理',
        ),

        centerTitle:true,

      ),



      body: Padding(

        padding: const EdgeInsets.all(20),


        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,


          children: [



            const Text(

              '当前身份',

              style:TextStyle(

                fontSize:18,

                fontWeight:FontWeight.bold,

              ),

            ),



            const SizedBox(height:10),



            _infoCard(

              '身份',

              esp32.getCurrentUser(),

            ),



            _infoCard(

              '权限等级',

              esp32.sessionRole == "admin"

                  ? "最高权限"

                  : "临时控制",

            ),




            const SizedBox(height:20),



            const Text(

              '授权状态',

              style:TextStyle(

                fontSize:18,

                fontWeight:FontWeight.bold,

              ),

            ),



            const SizedBox(height:10),




            _infoCard(

              '管理员授权',

              esp32.adminAuthorized

                  ? "已授权"

                  : "未授权",

            ),




            _infoCard(

              '临时授权',

              esp32.temporaryAuthorizationStatus,

            ),




            const SizedBox(height:20),




            const Text(

              '临时借车信息',

              style:TextStyle(

                fontSize:18,

                fontWeight:FontWeight.bold,

              ),

            ),




            const SizedBox(height:10),



            _infoCard(

              '临时密码',

              esp32.temporaryPassword,

            ),



            _infoCard(

              '开始时间',

              esp32.temporaryStart?.toString()

              ?? "无",

            ),



            _infoCard(

              '结束时间',

              esp32.temporaryEnd?.toString()

              ?? "无",

            ),




            const SizedBox(height:30),




            ElevatedButton(

              onPressed:(){


                setState((){});


              },


              child: const Text(

                '刷新权限状态',

              ),

            ),



          ],

        ),

      ),

    );

  }






  Widget _infoCard(String title,String value){


    return Padding(

      padding:

      const EdgeInsets.symmetric(vertical:5),


      child:Row(

        children:[


          Text(

            '$title：',

            style:const TextStyle(

              color:Colors.grey,

            ),

          ),



          Expanded(

            child:Text(

              value,

              style:const TextStyle(

                color:Colors.white,

              ),

            ),

          ),


        ],

      ),

    );


  }



}
