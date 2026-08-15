class MockESP32 {
  bool _connected = false;

  bool _adminAuthorized = false;
  bool _temporaryAuthorized = false;

  String _currentUser = "无";

  final List<String> logs = [];


  // =========================
  // BLE连接模拟
  // =========================

  bool connectBLE() {
    _connected = true;

    logs.add("BLE连接成功");

    return true;
  }


  // =========================
  // BLE断开模拟
  // 注意：
  // 只断开通信
  // 不删除权限
  // =========================

  bool disconnectBLE() {
    _connected = false;

    logs.add("BLE连接断开");

    return true;
  }


  // =========================
  // 获取连接状态
  // =========================

  bool isConnected() {

    return _connected;

  }



  // =========================
  // 管理员认证
  // =========================

  bool adminLogin(String password) {


    if(password == "123456") {

      _adminAuthorized = true;
      _temporaryAuthorized = false;

      _currentUser = "管理员";

      logs.add("管理员认证成功");

      return true;

    }


    logs.add("管理员密码错误");

    return false;

  }




  // =========================
  // 临时借车认证
  // =========================

  bool temporaryLogin(String password) {


    if(password == "888888") {


      _temporaryAuthorized = true;
      _adminAuthorized = false;


      _currentUser = "临时借车";


      logs.add("临时借车认证成功");


      return true;

    }



    logs.add("临时密码错误");


    return false;


  }





  // =========================
  // 获取当前身份
  // =========================

  String getCurrentUser(){

    return _currentUser;

  }




  // =========================
  // 权限状态
  // =========================

  bool get adminAuthorized {

    return _adminAuthorized;

  }



  bool get temporaryAuthorized {

    return _temporaryAuthorized;

  }




  // =========================
  // 模拟车辆动作
  // =========================

  String controlCar(String action){


    if(!_connected){

      return "设备未连接";

    }



    logs.add("执行车辆动作:$action");


    return "$action执行成功";


  }





  // =========================
  // 获取日志
  // =========================

  List<String> getLogs(){

    return logs;

  }



}
