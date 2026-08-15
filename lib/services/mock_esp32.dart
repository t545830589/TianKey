
class MockESP32 {

  // 设备信息
  final String deviceName = "陕A0P92Y";

  final String deviceId = "TianKey-V11-001";


  // 连接状态
  bool connected = false;


  // 管理员状态
  bool adminAuthorized = false;


  // 时间同步
  DateTime? deviceTime;



  // 管理员密码
  String adminPassword = "13092991951";



  // 临时借车信息

  String? temporaryPassword;

  DateTime? temporaryStart;

  DateTime? temporaryEnd;



  // 日志

  List<String> logs = [];



  // 添加日志

  void addLog(String message){

    logs.add(
      "${DateTime.now()} : $message"
    );


    //最多保存200条

    if(logs.length > 200){

      logs.removeAt(0);

    }

  }





  // 模拟BLE连接

  bool connect(){

    connected = true;

    addLog(
      "BLE连接成功"
    );


    return true;

  }





  // 管理员验证

  bool verifyAdmin(String password){


    if(password == adminPassword){


      adminAuthorized = true;


      syncTime();


      addLog(
        "管理员认证成功"
      );


      return true;

    }



    addLog(
      "管理员密码错误"
    );


    return false;

  }







  // 时间同步

  void syncTime(){


    deviceTime = DateTime.now();


    addLog(
      "时间同步完成"
    );


  }







  // 创建临时密码

  void createTemporaryPassword(

      String password,

      DateTime start,

      DateTime end

      ){



    temporaryPassword = password;


    temporaryStart = start;


    temporaryEnd = end;



    addLog(
      "生成临时借车密码"
    );



  }







  // 临时用户验证

  bool verifyTemporaryUser(

      String password

      ){



    if(temporaryPassword == null){

      addLog(
        "没有临时授权"
      );


      return false;

    }




    DateTime now = DateTime.now();



    if(

    password == temporaryPassword &&

    now.isAfter(temporaryStart!) &&

    now.isBefore(temporaryEnd!)

    ){


      syncTime();


      addLog(
        "临时借车认证成功"
      );


      return true;


    }



    addLog(
      "临时借车认证失败"
    );



    return false;


  }









  // 六个车辆动作模拟


  String executeCommand(String command){



    if(!adminAuthorized && temporaryPassword == null){


      return "无权限";


    }





    switch(command){



      case "suoche":


        addLog(
          "锁车 GPIO12 执行"
        );


        return "锁车成功";





      case "jiesuo":


        addLog(
          "解锁 GPIO13 执行"
        );


        return "解锁成功";







      case "xunche":


        addLog(
          "寻车 GPIO12 双脉冲"
        );


        return "寻车成功";







      case "chuangsheng":


        addLog(
          "升窗 GPIO12 7秒"
        );


        return "升窗成功";








      case "chuangjiang":


        addLog(
          "降窗 GPIO13 7秒"
        );


        return "降窗成功";








      case "houbeixiang":


        addLog(
          "后备箱 GPIO14 7秒"
        );


        return "后备箱成功";







      default:


        return "未知指令";


    }



  }



}
