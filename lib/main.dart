import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'services/profile_store.dart';
import 'models/player_profile.dart';
import 'models/player_stats.dart';
import 'screens/game_screen.dart';
import 'routes.dart';

/// Diagnostic build fingerprint
const String kBuildFingerprint = 'BB_DIAG_001';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  /// 🔴 CRITICAL: catch framework errors and render them
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
    runApp(_ErrorApp(details));
  };

  runApp(const BalloonBurstBootstrap());
}

///
/// Shows Flutter errors directly on screen (release-safe)
///
class _ErrorApp extends StatelessWidget {
  final FlutterErrorDetails details;
  const _ErrorApp(this.details);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Text(
            details.exceptionAsString(),
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }
}

class BalloonBurstBootstrap extends StatelessWidget {
  const BalloonBurstBootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _Loader(),
    );
  }
}

class _Loader extends StatefulWidget {
  const _Loader();

  @override
  State<_Loader> createState() => _LoaderState();
}

class _LoaderState extends State<_Loader> {
  late final ProfileStore _store;
  PlayerProfile? _profile;
  PlayerStats? _stats;

  @override
  void initState() {
    super.initState();
    _store = ProfileStore();
    _load();
  }

  Future<void> _load() async {
    try {
      final profile = await _store.loadProfile();
      final stats = await _store.loadStats();
      setState(() {
        _profile = profile;
        _stats = stats;
      });
    } catch (e) {
      setState(() {
        _profile = PlayerProfile.fromJson(const {});
        _stats = PlayerStats.fromJson(const {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_profile == null || _stats == null) {
      return const Scaffold(
        body: Center(child: Text('Loading Balloon Burst…')),
      );
    }

    return BalloonBurstApp(
      store: _store,
      profile: _profile!,
      stats: _stats!,
    );
  }
}

class BalloonBurstApp extends StatefulWidget {
  final ProfileStore store;
  final PlayerProfile profile;
  final PlayerStats stats;

  const BalloonBurstApp({
    super.key,
    required this.store,
    required this.profile,
    required this.stats,
  });

  @override
  State<BalloonBurstApp> createState() => _BalloonBurstAppState();
}

class _BalloonBurstAppState extends State<BalloonBurstApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _saveSafely();
    }
  }

  Future<void> _saveSafely() async {
    try {
      await widget.store.saveProfile(widget.profile);
      await widget.store.saveStats(widget.stats);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const GameScreen(),
      routes: {
        AppRoutes.game: (_) => const GameScreen(),
      },
    );
  }
}
