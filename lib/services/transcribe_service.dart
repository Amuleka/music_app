import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class TranscribeService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 60),
  ));

  /// Sends the recorded audio to the backend and saves a .mid file locally.
  /// Returns the local MIDI file path, or null on failure.
  Future<String?> transcribeToMidi({
    required String apiBase,   // e.g. https://your-ngrok-url.ngrok-free.app
    required String audioPath, // .m4a path from your recorder
    required int bpm,
  }) async {
    final form = FormData.fromMap({
      'bpm': bpm,
      'file': await MultipartFile.fromFile(audioPath, filename: 'idea.m4a'),
    });

    final res = await _dio.post('$apiBase/transcribe', data: form);
    final b64 = (res.data is Map) ? res.data['midi_b64'] as String? : null;
    if (b64 == null) return null;

    final bytes = base64Decode(b64);
    final dir = await getApplicationDocumentsDirectory();
    final midiPath =
        '${dir.path}/idea_${DateTime.now().millisecondsSinceEpoch}.mid';
    await File(midiPath).writeAsBytes(bytes);
    return midiPath;
  }
}
