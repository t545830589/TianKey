class TemporaryKeyService {
  final Map<String, DateTime> _keys = {};

  void createKey(String key, Duration validFor) {
    _keys[key] = DateTime.now().add(validFor);
  }

  bool isValid(String key) {
    final expire = _keys[key];
    if (expire == null) return false;
    return DateTime.now().isBefore(expire);
  }

  void removeKey(String key) {
    _keys.remove(key);
  }
}
