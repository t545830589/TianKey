import 'dart:async';

/// TianKey V11 vehicle control simulation layer.
/// This module simulates the command pipeline before ESP32 hardware is connected.
class VehicleController {
  String status = 'READY';
  bool locked = true;
  bool radarEnabled = false;

  final StreamController<String> _events = StreamController.broadcast();

  Stream<String> get events => _events.stream;

  void lock() {
    locked = true;
    status = 'LOCKED';
    _events.add('LOCK command sent');
  }

  void unlock() {
    locked = false;
    status = 'UNLOCKED';
    _events.add('UNLOCK command sent');
  }

  void radar() {
    radarEnabled = !radarEnabled;
    status = radarEnabled ? 'RADAR ON' : 'RADAR OFF';
    _events.add(status);
  }

  void dispose() {
    _events.close();
  }
}
