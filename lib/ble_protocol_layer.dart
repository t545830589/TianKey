import 'dart:typed_data';

/// BLE protocol foundation layer.
///
/// This file intentionally does not contain TianKey/ESP32 UUIDs or command
/// frames. It provides a stable place for real hardware protocol integration
/// after the actual ESP32 specification is available.
class BleProtocolPacket {
  const BleProtocolPacket({required this.bytes});

  final Uint8List bytes;

  String get hex => bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join(' ');
}

class BleProtocolResult {
  const BleProtocolResult({required this.success, this.message = ''});

  final bool success;
  final String message;
}

/// A protocol request container for upper BLE layers.
///
/// It keeps the command path separate from BLE transport so UI code does not
/// directly depend on raw bytes.
class BleProtocolRequest {
  const BleProtocolRequest({required this.payload, this.name = ''});

  final Uint8List payload;
  final String name;

  BleProtocolPacket toPacket() {
    return BleProtocolPacket(bytes: Uint8List.fromList(payload));
  }
}

class TianKeyBleProtocolLayer {
  BleProtocolPacket createPacket(Uint8List payload) {
    return BleProtocolPacket(bytes: Uint8List.fromList(payload));
  }

  BleProtocolResult validatePacket(BleProtocolPacket packet) {
    if (packet.bytes.isEmpty) {
      return const BleProtocolResult(success: false, message: 'empty BLE packet');
    }
    return const BleProtocolResult(success: true);
  }

  BleProtocolResult validateRequest(BleProtocolRequest request) {
    return validatePacket(request.toPacket());
  }
}
