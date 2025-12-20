import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'services/profile_store.dart';
import 'models/player_profile.dart';
import 'models/player_stats.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  final store = ProfileStore();

  PlayerProfile profile;
  PlayerStats stats;

  try {
    profile = await store.loadProfile();
    stats = await store.loadStats();
  } catch (_) {
    profile = PlayerProfile.fromJson(const {});
    stats = PlayerStats.fromJson(const {});
  }

  runApp(
    BalloonBurstApp(
      store: store,
      profile: profile,
      stats: stats,
    ),
  );
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
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Balloon Burst',
                style: TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 16),
              Text('Profile loaded: ${widget.profile.runtimeType}'),
              Text('Stats loaded: ${widget.stats.runtimeType}'),
            ],
          ),
        ),
      ),
    );
  }
}
