class InputLatch {
  bool _tap = false;

  void registerTap() {
    _tap = true;
  }

  bool consumeTap() {
    final t = _tap;
    _tap = false;
    return t;
  }
}
