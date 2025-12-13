// lib/engine/momentum/momentum_storage.dart

/// Storage abstraction for Universal Momentum.
///
/// Keeps persistence concerns OUT of gameplay code.
/// Can be swapped later for SharedPreferences, database,
/// or cloud storage without refactoring the engine.
abstract class MomentumStorage {
  /// Load persisted universal momentum value
  Future<double> loadUniversal();

  /// Persist universal momentum value
  Future<void> saveUniversal(double value);
}

/// Simple in-memory storage (safe default).
///
/// Useful for:
/// - early development
/// - testing
/// - games without persistence
class InMemoryMomentumStorage implements MomentumStorage {
  double _universal = 0.0;

  @override
  Future<double> loadUniversal() async {
    return _universal;
  }

  @override
  Future<void> saveUniversal(double value) async {
    _universal = value;
  }
}

