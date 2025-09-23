import 'dart:async';
import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/idea.dart';
import '../native/ios_recorder.dart';

class RecordingState {
  final bool isRecording;
  final int elapsedMs;
  const RecordingState({required this.isRecording, required this.elapsedMs});
}

class RecorderService {
  final FlutterSoundRecorder _androidRec = FlutterSoundRecorder();

  Timer? _ticker;
  DateTime? _startedAt;
  bool _isRecording = false;
  int _elapsedMs = 0;

  final _stateCtrl = StreamController<RecordingState>.broadcast();
  Stream<RecordingState> get state$ => _stateCtrl.stream;

  void _emit() =>
      _stateCtrl.add(RecordingState(isRecording: _isRecording, elapsedMs: _elapsedMs));

  Future<void> start() async {
    if (Platform.isIOS) {
      final ok = await startNativeRecord();
      if (ok != true) throw Exception('Failed to start native recorder');
    } else {
      if (!_androidRec.isRecording && !_androidRec.isPaused) {
        await _androidRec.openRecorder();
      }
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/idea_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _androidRec.startRecorder(
        toFile: path,
        codec: Codec.aacMP4,
        sampleRate: 48000,
        bitRate: 96000,
        numChannels: 1,
      );
    }

    _isRecording = true;
    _startedAt = DateTime.now();
    _elapsedMs = 0;
    _emit();

    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (_startedAt == null) return;
      _elapsedMs = DateTime.now().difference(_startedAt!).inMilliseconds;
      _emit();
    });
  }

  /// Stops recording and returns the created Idea (caller persists/navigates).
  Future<Idea?> stopAndSave() async {
    String? path;
    if (Platform.isIOS) {
      path = await stopNativeRecord();
    } else {
      path = await _androidRec.stopRecorder();
      await _androidRec.closeRecorder();
    }

    _ticker?.cancel();
    _isRecording = false;
    _emit();

    if (path == null || path.isEmpty) return null;

    return Idea(
      id: const Uuid().v4(),
      title: 'Idea ${DateTime.now().toLocal().toIso8601String().substring(0, 16)}',
      filePath: path,
      duration: Duration(milliseconds: _elapsedMs),
      createdAt: DateTime.now(),
    );
  }

  Future<void> dispose() async {
    _ticker?.cancel();
    await _androidRec.closeRecorder();
    await _stateCtrl.close();
  }
}
