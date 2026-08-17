class BleSimulator {
  bool connected = false;
  String? vehicleId;

  List<String> scan() {
    return ['陕A0P92Y'];
  }

  bool connect(String id) {
    vehicleId = id;
    connected = true;
    return connected;
  }

  void disconnect() {
    connected = false;
  }

  bool reconnect() {
    if (vehicleId == null) return false;
    connected = true;
    return connected;
  }
}
