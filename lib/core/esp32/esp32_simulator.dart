enum Esp32Command {
  lock,
  unlock,
  findCar,
  windowUp,
  windowDown,
  trunk,
}

class Esp32Simulator {
  String status = 'READY';

  String send(Esp32Command command) {
    status = command.name.toUpperCase();
    return status;
  }

  String executeCommand(String command) {
    final normalized = command.toUpperCase();

    switch (normalized) {
      case 'LOCK':
        return send(Esp32Command.lock);
      case 'UNLOCK':
        return send(Esp32Command.unlock);
      case 'FIND_CAR':
      case 'FINDCAR':
        return send(Esp32Command.findCar);
      case 'WINDOW_UP':
        return send(Esp32Command.windowUp);
      case 'WINDOW_DOWN':
        return send(Esp32Command.windowDown);
      case 'TRUNK':
        return send(Esp32Command.trunk);
      default:
        status = 'FAILED';
        return status;
    }
  }
}
