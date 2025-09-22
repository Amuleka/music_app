import 'package:flutter/foundation.dart';

class Idea {
  final String id;
  String title;
  final String filePath;
  final Duration duration;
  final DateTime createdAt;
  int bpm;
  String keySig; // e.g. "C Maj", "A Min"
  bool addDrums;
  bool addGuitar;
  bool addLead;

  Idea({
    required this.id,
    required this.title,
    required this.filePath,
    required this.duration,
    required this.createdAt,
    this.bpm = 120,
    this.keySig = 'C Maj',
    this.addDrums = false,
    this.addGuitar = false,
    this.addLead = false,
  });
}
