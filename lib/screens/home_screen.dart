// lib/screens/home_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/idea.dart';
import '../widgets/animated_bg.dart';
import '../widgets/record_button.dart';
import '../services/recorder_service.dart';
import '../services/permission.dart';

class HomeScreen extends StatefulWidget {
  final void Function(Idea) onIdeaSaved;
  const HomeScreen({super.key, required this.onIdeaSaved});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _recorder = RecorderService();
  late final StreamSubscription _sub;

  bool _recording = false;
  int _elapsedMs = 0;

  @override
  void initState() {
    super.initState();
    _sub = _recorder.state$.listen((s) {
      setState(() {
        _recording = s.isRecording;
        _elapsedMs = s.elapsedMs;
      });
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    _recorder.dispose();
    super.dispose();
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _onRecordTap() async {
    if (_recording) {
      final idea = await _recorder.stopAndSave();
      if (!mounted || idea == null) return;
      widget.onIdeaSaved(idea);
      Navigator.pushNamed(context, '/refine', arguments: idea);
      return;
    }

    // Before starting (Android), ensure mic permission
    if (!await ensureMicPermission(context)) return;

    try {
      await _recorder.start();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recorder error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = Duration(milliseconds: _elapsedMs);
    return Scaffold(
      body: AnimatedBg(
        child: SafeArea(
          child: Stack(
            children: [
              const Align(
                alignment: Alignment(0, -0.85),
                child: Text(
                  'What are you thinking?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              if (_recording)
                Align(
                  alignment: const Alignment(0, -0.65),
                  child: Text(
                    _format(elapsed),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              Positioned(
                right: 16,
                top: 16,
                child: FilledButton.tonal(
                  onPressed: () => Navigator.pushNamed(context, '/recordings'),
                  child: const Text('Recordings'),
                ),
              ),
              Align(
                alignment: const Alignment(0, 0.85),
                child: RecordButton(
                  recording: _recording,
                  onTap: _onRecordTap,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
