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
}
