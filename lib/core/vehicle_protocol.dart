/// Tian Key vehicle command protocol.
///
/// Keeps UI, mock controller and future ESP32 BLE transport using the same
/// command names.
class VehicleProtocol {
  VehicleProtocol._();

  static const String lock = 'LOCK';
  static const String unlock = 'UNLOCK';
  static const String findCar = 'FIND';
  static const String windowUp = 'WINDOW_UP';
  static const String windowDown = 'WINDOW_DOWN';
  static const String trunk = 'TRUNK';
}
