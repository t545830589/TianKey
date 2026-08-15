class MockESP32 {

  bool _connected = false;


  bool _adminAuthorized = false;

  bool _temporaryAuthorized = false;


  String _currentUser = "无";


  String _sessionRole = "无";


  String _temporaryPassword = "888888";


  DateTime? _temporaryStart;

  DateTime? _temporaryEnd;


  String _deviceId = "ESP32-TIANKEY-001";


  final List<String> logs = [];



  // =========================
  // BLE连接
  // =========================

  bool connectBLE() {

    _connected = true;

    logs.add("BLE连接成功");

    return true;

  }



  // =========================
  // BLE断开
  // 注意：
  // 不删除权限
  // =========================

  bool disconnectBLE(){

    _connected = false;

    logs.add("BLE连接断开");

    return true;

  }



  bool isConnected(){

    return _connected;

  }




  // =========================
  // 自动重新连接模拟
  // =========================

  bool autoReconnect(){

    if(!_connected){

      _connected = true;

      logs.add("BLE自动重新连接成功");

      return true;

    }


    logs.add("BLE已经连接");

    return true;

  }





  // =========================
  // 管理员登录
  // =========================

  bool adminLogin(String password){


    if(password == "123456"){


      _adminAuthorized = true;

      _temporaryAuthorized = false;


      _currentUser = "管理员";

      _sessionRole = "admin";


      logs.add("管理员认证成功");


      return true;

    }


    logs.add("管理员密码错误");


    return false;

  }







  // =========================
  // 临时借车
  // =========================

  bool temporaryLogin(String password){


    if(password == _temporaryPassword){


      _temporaryAuthorized = true;

      _adminAuthorized = false;


      _currentUser = "临时借车";

      _sessionRole = "temporary";


      _temporaryStart = DateTime.now();


      _temporaryEnd = DateTime.now()
          .add(const Duration(hours:8));



      logs.add("临时借车认证成功");


      return true;


    }



    logs.add("临时密码错误");


    return false;


  }






  // =========================
  // 当前身份
  // =========================

  String getCurrentUser(){

    return _currentUser;

  }



  String get sessionRole{

    return _sessionRole;

  }




  // =========================
  // 权限状态
  // =========================

  bool get adminAuthorized{

    return _adminAuthorized;

  }




  bool get temporaryAuthorized{

    return _temporaryAuthorized;

  }



  String get temporaryAuthorizationStatus{


    if(_temporaryAuthorized){

      return "临时授权有效";

    }


    return "无临时授权";


  }





  String get temporaryPassword{

    return _temporaryPassword;

  }





  DateTime? get temporaryStart{

    return _temporaryStart;

  }



  DateTime? get temporaryEnd{

    return _temporaryEnd;

  }





  // =========================
  // 设备ID
  // =========================

  String get deviceId{

    return _deviceId;

  }



  void _saveDeviceId(String id){

    _deviceId = id;

    logs.add("保存设备ID:$id");

  }






  // =========================
  // 车辆控制
  // =========================


  String controlCar(String action){


    return executeCommand(action);


  }





  String executeCommand(String command){



    if(!_connected){


      logs.add("设备未连接");


      return "设备未连接";


    }



    logs.add("执行车辆动作:$command");


    return "$command执行成功";


  }





  // =========================
  // 日志
  // =========================


  List<String> getLogs(){

    return logs;

  }


}
