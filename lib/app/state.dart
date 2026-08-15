
import 'package:flutter/material.dart';


class AppState extends ChangeNotifier{


  bool connected=false;


  String role="无";


  String vehicle="陕A0P92Y";


  void setConnected(bool value){

    connected=value;

    notifyListeners();

  }



  void setRole(String value){

    role=value;

    notifyListeners();

  }



}
