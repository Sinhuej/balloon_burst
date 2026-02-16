import 'momentum_config.dart';
import 'momentum_manager.dart';
import 'momentum_models.dart';
import 'momentum_storage.dart';

/// TJ Engine MomentumController (façade)
/// - Provides a stable, simple API surface for games to call
/// - Internally uses MomentumManager (which includes RisingWorlds via snapshot.worldLevel)
/// - Intentionally lightweight so the engine stays reusable/licensable
class MomentumController {
  final MomentumManager _mgr;

  MomentumController._(this._mgr);

  static MomentumController? _instance;

  /// Global engine singleton used by GameManager and any TJ Engine-powered game.
  static MomentumController get instance {
    _instance ??= MomentumController._(
      MomentumManager(
        config: MomentumConfig.defaults(),
        storage: InMemoryMomentumStorage(),
      ),
    );
    return _instance!;
  }

  /// Optional init hook if you later swap storage to disk/cloud.
  Future<void> init() async {
    await _mgr.init();
  }

  /// Add “momentum” (called by gameplay events; currency is game-defined)
  void add(double amount) => _mgr.addLocal(amount);

  /// Decay local momentum over time (dt seconds)
  void update(double dt) => _mgr.decayLocal(dt);

  /// Snapshot includes RisingWorlds worldLevel (derived from universalMomentum)
  MomentumSnapshot snapshot() => _mgr.snapshot();

  double get local => _mgr.local;
  double get universal => _mgr.universal;

  /// Hard reset local momentum (keeps universal momentum unless you also reset storage).
  void reset() {
    // MomentumManager does not currently expose a direct reset;
    // we keep this façade stable and simply re-create the manager if needed later.
    // For now, emulate “reset local” by decaying aggressively to zero.
    // (Safe + deterministic + doesn’t touch long-term progression.)
    _mgr.decayLocal(999999);
  }
}

/// Minimal in-memory storage.
/// Safe default for now; later you can swap to SharedPreferences/secure storage/cloud.
class InMemoryMomentumStorage implements MomentumStorage {
  double _universal = 0.0;

  @override
  Future<double> loadUniversal() async => _universal;

  @override
  Future<void> saveUniversal(double value) async {
    _universal = value;
  }
}

/// Global singleton instance (matches GameManager’s current usage).
final MomentumController momentumController = MomentumController.instance;
