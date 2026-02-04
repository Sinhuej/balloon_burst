import 'package:flutter/foundation.dart';

class DebugEvent {
  final String category;
  final String message;
  final int frame;

  DebugEvent(this.category, this.message, this.frame);
}

class DebugController extends ChangeNotifier {
  final List<DebugEvent> _events = [];

  int frame = 0;

  List<DebugEvent> get events => List.unmodifiable(_events);

  void tick(int frameCount) {
    frame = frameCount;
  }

  void log(String category, String message) {
    _events.add(DebugEvent(category, message, frame));
    notifyListeners();
  }

  void clear() {
    _events.clear();
    notifyListeners();
  }
}
