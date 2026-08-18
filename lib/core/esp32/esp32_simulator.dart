enum Esp32Command { lock, unlock, findCar, windowUp, windowDown, trunk }

class Esp32Simulator {
  String status = 'READY';
  bool locked = true;

  String send(Esp32Command command) {
    status = command.name.toUpperCase();
    if (command == Esp32Command.lock) locked = true;
    if (command == Esp32Command.unlock) locked = false;
    return status;
  }

  String executeCommand(String command) {
    switch (command.toLowerCase()) {
      case 'suoche':
      case 'lock':
        return send(Esp32Command.lock);
      case 'jiesuo':
      case 'unlock':
        return send(Esp32Command.unlock);
      case 'xunche':
      case 'find_car':
      case 'findcar':
        return send(Esp32Command.findCar);
      case 'chuangsheng':
      case 'window_up':
        return send(Esp32Command.windowUp);
      case 'chuangjiang':
      case 'window_down':
        return send(Esp32Command.windowDown);
      case 'houbeixiang':
      case 'trunk':
        return send(Esp32Command.trunk);
      default:
        status = 'FAILED';
        return status;
    }
  }
}
