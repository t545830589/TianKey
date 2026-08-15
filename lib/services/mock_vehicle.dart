
class MockVehicle {


  int battery = 86;


  bool doorOpen = false;


  bool locked = true;


  double temperature = 26.0;



  String getBattery(){

    return "$battery%";

  }



  String getDoorStatus(){

    return doorOpen ? "开启" : "关闭";

  }



  String getLockStatus(){

    return locked ? "已锁" : "未锁";

  }



  String getTemperature(){

    return "$temperature℃";

  }




  void openDoor(){

    doorOpen = true;

  }




  void closeDoor(){

    doorOpen = false;

  }




  void lockCar(){

    locked = true;

  }




  void unlockCar(){

    locked = false;

  }


}
