import 'auth_service.dart';
import 'ble_service.dart';

class SessionState {
  final bool connected;
  final String role;
  final String device;

  const SessionState({
    required this.connected,
    required this.role,
    required this.device,
  });
}

class SessionManager {
  final BleService bleService;
  final AuthService authService;

  SessionState state = const SessionState(
    connected: false,
    role: 'NONE',
    device: '',
  );

  SessionManager({
    required this.bleService,
    required this.authService,
  });

  bool connectTianKeyDevice() {
    final connected = bleService.connect('TianKey-ESP32-V11');
    if (connected) {
      state = SessionState(
        connected: true,
        role: state.role,
        device: 'TianKey-ESP32-V11',
      );
    }
    return connected;
  }

  AuthResult loginAdmin(String password) {
    final result = authService.verifyAdmin(password);
    if (result.success) {
      state = SessionState(
        connected: state.connected,
        role: result.role,
        device: state.device,
      );
    }
    return result;
  }

  AuthResult loginGuest(String password) {
    final result = authService.verifyGuest(password);
    if (result.success) {
      state = SessionState(
        connected: state.connected,
        role: result.role,
        device: state.device,
      );
    }
    return result;
  }
}
