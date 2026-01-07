import 'package:flutter/material.dart';

class BlankScreen extends StatelessWidget {
  const BlankScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Coming Soon',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}
