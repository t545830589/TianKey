import '../services/mock_esp32.dart';
import '../services/mock_vehicle.dart';


class TianKeyState {


  final MockESP32 esp32 = MockESP32();


  final MockVehicle vehicle = MockVehicle();



  String get user {

    return esp32.getCurrentUser();

  }



  String get role {

    return esp32.sessionRole;

  }



  bool get connected {

    return esp32.isConnected();

  }



  void connect(){

    esp32.connectBLE();

  }



  void disconnect(){

    esp32.disconnectBLE();

  }



  String execute(String command){


    String result =
        esp32.executeCommand(command);



    switch(command){


      case "锁车":

        vehicle.lock();

        break;


      case "解锁":

        vehicle.unlock();

        break;


      case "寻车":

        vehicle.search();

        break;


      case "后备箱":

        vehicle.openTrunk();

        break;


    }


    return result;

  }


}
