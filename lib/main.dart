import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'models/idea.dart';
import 'screens/home_screen.dart';
import 'screens/refine_screen.dart';
import 'screens/recordings_screen.dart';

void main() {
  runApp(const IdeaStashApp());
}

class IdeaStashApp extends StatefulWidget {
  const IdeaStashApp({super.key});
  @override
  State<IdeaStashApp> createState() => _IdeaStashAppState();

  static _IdeaStashAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_IdeaStashAppState>()!;
}

class _IdeaStashAppState extends State<IdeaStashApp> {
  final _ideas = <Idea>[];

  void addIdea(Idea idea) {
    setState(() => _ideas.insert(0, idea));
  }

  void updateIdea(Idea idea) {
    final i = _ideas.indexWhere((e) => e.id == idea.id);
    if (i != -1) setState(() => _ideas[i] = idea);
  }

  void deleteIdea(String id) {
    setState(() {
      final idea = _ideas.firstWhere((e) => e.id == id);
      try { File(idea.filePath).deleteSync(); } catch (_) {}
      _ideas.removeWhere((e) => e.id == id);
    });
  }

  List<Idea> get ideas => List.unmodifiable(_ideas);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IdeaStash',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2A6AF0)),
        useMaterial3: true,
        fontFamily: 'SF Pro',
      ),
      routes: {
        '/': (_) => HomeScreen(onIdeaSaved: addIdea),
        '/refine': (_) => const RefineScreen(),
        '/recordings': (_) => const RecordingsScreen(),
      },
    );
  }
}
