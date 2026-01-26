import 'package:flutter/material.dart';
import 'run_end_state.dart';
import 'run_end_messages.dart';

class RunEndOverlay extends StatelessWidget {
  final RunEndState state;
  final VoidCallback onReplay;

  const RunEndOverlay({
    super.key,
    required this.state,
    required this.onReplay,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onReplay,
      child: Container(
        color: Colors.black.withOpacity(0.75),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              RunEndMessages.title(state),
              style: const TextStyle(
                fontSize: 26,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              RunEndMessages.body(state),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Text(
              RunEndMessages.action(),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
