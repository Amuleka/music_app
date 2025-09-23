import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

Future<bool> ensureMicPermission(BuildContext context) async {
  if (Platform.isIOS) return true; // iOS prompt handled natively in Swift
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
