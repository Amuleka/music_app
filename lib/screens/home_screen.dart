// lib/screens/home_screen.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

import '../models/idea.dart';
import '../main.dart';
import '../widgets/animated_bg.dart';
import '../native/ios_recorder.dart'; // <-- MethodChannel helpers (startNativeRecord/stopNativeRecord)

/// Ask for mic permission safely (Android/others). iOS uses native system prompt on the Swift side.
Future<bool> ensureMicPermission(BuildContext context) async {
  if (Platform.isIOS) return true; // handled natively
  var status = await Permission.microphone.status;

  if (status.isPermanentlyDenied) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Enable Microphone in Settings to record')),
    );
    await openAppSettings();
    return false;
  }

  status = await Permission.microphone.request();
  if (!status.isGranted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Microphone permission required')),
    );
    return false;
  }
  return true;
}

class HomeScreen extends StatefulWidget {
  final void Function(Idea) onIdeaSaved;
  const HomeScreen({super.key, required this.onIdeaSaved});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Used for Android (FlutterSound). iOS uses native Swift via MethodChannel.
  final FlutterSoundRecorder _rec = FlutterSoundRecorder();

  bool _recording = false;
  DateTime? _startedAt;
  Timer? _timer;
  int _elapsedMs = 0;

  @override
  void dispose() {
    _timer?.cancel();
    // Safe to close; no-op on iOS path
    _rec.closeRecorder();
    super.dispose();
  }

  void _toast(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _start() async {
    try {
      print('[REC] start tapped');

      // iOS → call native recorder (system mic prompt handled in Swift)
      if (Platform.isIOS) {
        final ok = await startNativeRecord();
        if (ok != true) {
          _toast('Could not start recorder');
          return;
        }
        print('[REC][iOS] native recorder started');
      } else {
        // Android/others → FlutterSound with runtime permission
        final permOk = await ensureMicPermission(context);
        if (!permOk) {
          print('[REC][Android] mic permission not granted');
          return;
        }

        if (!_rec.isRecording && !_rec.isPaused) {
          await _rec.openRecorder();
          print('[REC][Android] recorder opened');
        }

        final dir = await getApplicationDocumentsDirectory();
        final filePath =
            '${dir.path}/idea_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _rec.startRecorder(
          toFile: filePath,
          codec: Codec.aacMP4,
          sampleRate: 48000,
          bitRate: 96000,
          numChannels: 1,
        );
        print('[REC][Android] started -> $filePath');
      }

      // Common UI state (both iOS & Android)
      setState(() {
        _recording = true;
        _startedAt = DateTime.now();
        _elapsedMs = 0;
      });

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
        if (!mounted || _startedAt == null) return;
        setState(() =>
        _elapsedMs = DateTime.now().difference(_startedAt!).inMilliseconds);
      });
    } catch (e) {
      print('[REC] start error: $e');
      _toast('Recorder error: $e');
    }
  }

  Future<void> _stop() async {
    try {
      print('[REC] stop tapped');
      String? path;

      if (Platform.isIOS) {
        // iOS native returns absolute path (or empty on failure)
        path = await stopNativeRecord();
        print('[REC][iOS] stopped -> $path');
      } else {
        // Android/others
        path = await _rec.stopRecorder();
        await _rec.closeRecorder();
        print('[REC][Android] stopped -> $path');
      }

      _timer?.cancel();
      setState(() => _recording = false);

      if (path == null || path.isEmpty) {
        print('[REC] stop returned null/empty path');
        return;
      }

      print('[REC] saved at: $path');
      final duration = Duration(milliseconds: _elapsedMs);

      final idea = Idea(
        id: const Uuid().v4(),
        title:
        'Idea ${DateTime.now().toLocal().toIso8601String().substring(0, 16)}',
        filePath: path,
        duration: duration,
        createdAt: DateTime.now(),
      );

      IdeaStashApp.of(context).addIdea(idea);
      if (!mounted) return;
      Navigator.pushNamed(context, '/refine', arguments: idea);
    } catch (e) {
      print('[REC] stop error: $e');
      _toast('Stop error: $e');
    }
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
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
              // Recordings nav
              Positioned(
                right: 16,
                top: 16,
                child: FilledButton.tonal(
                  onPressed: () => Navigator.pushNamed(context, '/recordings'),
                  child: const Text('Recordings'),
                ),
              ),
              // Big record button (always tappable)
              Align(
                alignment: const Alignment(0, 0.85),
                child: GestureDetector(
                  onTap: _recording ? _stop : _start,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 96,
                    width: 96,
                    decoration: BoxDecoration(
                      color: _recording ? Colors.redAccent : Colors.white,
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
                      _recording ? Icons.stop_rounded : Icons.mic_rounded,
                      size: 38,
                      color: _recording ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
