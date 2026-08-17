class TimeSyncService {
  DateTime _deviceTime = DateTime.now();

  DateTime get deviceTime => _deviceTime;

  void sync(DateTime serverTime) {
    _deviceTime = serverTime;
  }

  bool get isSynced => true;
}
