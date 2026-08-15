
import '../services/mock_esp32.dart';
import '../services/mock_vehicle.dart';


class TianState {


  final MockESP32 esp32;

  final MockVehicle vehicle;


  TianState({

    required this.esp32,

    required this.vehicle,

  });



  bool get connected {

    return esp32.isConnected();

  }



  String get user {

    return esp32.getCurrentUser();

  }



  String get role {

    return esp32.sessionRole;

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



      case "后备箱":

        vehicle.openTrunk();

        break;



      case "寻车":

        vehicle.search();

        break;


    }


    return result;

  }


}
