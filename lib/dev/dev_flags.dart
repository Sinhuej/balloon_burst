/// Centralized dev / debug feature flags.
/// SAFE to ship — defaults control all debug behavior.
///
/// Flip this ONE flag to enable/disable:
/// - Debug HUD
/// - Detailed miss telemetry
class DevFlags {
  /// Master debug switch
  static const bool debugEnabled = true;

  /// On-screen HUD
  static bool get showDebugHud => debugEnabled;

  /// Detailed miss logs
  static bool get logMissDetails => debugEnabled;
}
