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

  // Step 5C-2: controlled data activation (no UI usage)
  final store = ProfileStore();

  // Load asynchronously but do not render or act on data yet
  PlayerProfile profile;
  PlayerStats stats;

  try {
    profile = await store.loadProfile();
    stats = await store.loadStats();
    // Intentionally unused for now
    // ignore: unused_local_variable
    profile = profile;
    // ignore: unused_local_variable
    stats = stats;
  } catch (_) {
    // Absolute safety: swallow errors, preserve boot
  }

  runApp(const BalloonBurstApp());
}

class BalloonBurstApp extends StatelessWidget {
  const BalloonBurstApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Text(
            'Balloon Burst',
            style: TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }
}
