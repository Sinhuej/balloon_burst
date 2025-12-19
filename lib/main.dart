import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;

  const MyApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: MainMenu(prefs: prefs),
    );
  }
}

class MainMenu extends StatelessWidget {
  final SharedPreferences prefs;

  const MainMenu({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050817),
      body: const Center(
        child: Text(
          'Main Menu (Step 5A Safe)',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
