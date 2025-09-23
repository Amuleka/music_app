import 'dart:io';
import 'package:flutter/services.dart';

const _native = MethodChannel('idea/native');

Future<bool> startNativeRecord() async {
  if (!Platform.isIOS) return false;
  final ok = await _native.invokeMethod<bool>('startRecord');
  return ok == true;
}

Future<String?> stopNativeRecord() async {
  if (!Platform.isIOS) return null;
  return await _native.invokeMethod<String>('stopRecord');
}
