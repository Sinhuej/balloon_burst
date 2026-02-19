/// ===============================================================
/// SYSTEM: NowProvider
/// ===============================================================
///
/// Abstraction over DateTime.now()
/// Allows deterministic testing and future server-time override.
/// ===============================================================
abstract class NowProvider {
  DateTime now();
}

/// Default implementation using system clock.
class SystemNowProvider implements NowProvider {
  @override
  DateTime now() => DateTime.now();
}
