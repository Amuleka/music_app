import 'dart:io';
import 'package:flutter/services.dart' show rootBundle, MethodChannel;
import 'package:path_provider/path_provider.dart';

const _sf2Asset = 'assets/sf2/GeneralUser-GS.sf2'; // <- must match pubspec.yaml
const _channel = MethodChannel('idea/native_midi');

/// Copy the SF2 soundfont from assets to a real file the native player can read.
/// Returns the absolute on-disk path to the .sf2 file.
Future<String> ensureSf2OnDisk() async {
  final docs = await getApplicationDocumentsDirectory();
  final outFile = File('${docs.path}/GeneralUser-GS.sf2');

  if (!await outFile.exists()) {
    final data = await rootBundle.load(_sf2Asset);
    await outFile.writeAsBytes(data.buffer.asUint8List(), flush: true);
  }
  return outFile.path;
}

/// Ask iOS to load the MIDI file with the provided SF2 soundfont.
Future<bool> midiLoad({required String midiPath}) async {
  final sf2Path = await ensureSf2OnDisk();
  final ok = await _channel.invokeMethod<bool>('midiLoad', {
    'midiPath': midiPath,
    'sf2Path': sf2Path,
  });
  return ok ?? false;
}

/// Start playback.
Future<void> midiPlay() => _channel.invokeMethod('midiPlay');

/// Stop playback.
Future<void> midiStop() => _channel.invokeMethod('midiStop');

/// Optional: set volume (0.0 - 1.0). Native side may ignore if not supported.
Future<void> midiSetVolume(double volume) =>
    _channel.invokeMethod('midiVolume', {'volume': volume.clamp(0.0, 1.0)});
