import 'package:flutter/material.dart';

class RecordButton extends StatelessWidget {
  final bool recording;
  final VoidCallback onTap;

  const RecordButton({super.key, required this.recording, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 96,
        width: 96,
        decoration: BoxDecoration(
          color: recording ? Colors.redAccent : Colors.white,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              blurRadius: 16,
              spreadRadius: 2,
              color: Colors.black26,
              offset: Offset(0, 6),
            )
          ],
        ),
        child: Icon(
          recording ? Icons.stop_rounded : Icons.mic_rounded,
          size: 38,
          color: recording ? Colors.white : Colors.black87,
        ),
      ),
    );
  }
}
