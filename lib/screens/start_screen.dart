import 'package:flutter/material.dart';
import '../state/app_state.dart';

class StartScreen extends StatelessWidget {
  final void Function() onStart;

  const StartScreen({super.key, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: onStart,
          child: const Text('START'),
        ),
      ),
    );
  }
}
