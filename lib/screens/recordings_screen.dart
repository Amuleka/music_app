import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../main.dart';
import '../models/idea.dart';

class RecordingsScreen extends StatefulWidget {
  const RecordingsScreen({super.key});

  @override
  State<RecordingsScreen> createState() => _RecordingsScreenState();
}

class _RecordingsScreenState extends State<RecordingsScreen> {
  final _player = AudioPlayer();
  StreamSubscription<PlayerState>? _playerSub;
  String? _playingId;

  @override
  void initState() {
    super.initState();
    // Keep UI in sync with playback state and clear when a track finishes.
    _playerSub = _player.playerStateStream.listen((state) {
      if (!mounted) return;
      if (state.processingState == ProcessingState.completed) {
        // Reset to start and clear the playing marker.
        _player.seek(Duration.zero);
        _player.pause();
        setState(() => _playingId = null);
      } else {
        // For other transitions (buffering/ready/paused), rebuild if needed.
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    // Cancel stream first to avoid callbacks firing after widget is gone.
    _playerSub?.cancel();
    _playerSub = null;
    _player.stop();
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay(Idea idea) async {
    try {
      // If this item is already playing, pause it.
      if (_playingId == idea.id && _player.playing) {
        await _player.pause();
        if (!mounted) return;
        setState(() {}); // reflect paused icon
        return;
      }

      // If another item was playing, stop first.
      if (_playingId != null && _playingId != idea.id) {
        await _player.stop();
      }

      // Load and play this idea's file.
      await _player.setFilePath(idea.filePath);
      await _player.play();

      if (!mounted) return;
      setState(() => _playingId = idea.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not play: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ideas = IdeaStashApp.of(context).ideas;
    return Scaffold(
      appBar: AppBar(title: const Text('Recordings')),
      body: ideas.isEmpty
          ? const Center(child: Text('No recordings yet'))
          : ListView.builder(
        itemCount: ideas.length,
        itemBuilder: (_, i) {
          final idea = ideas[i];
          final isThisPlaying =
              (_playingId == idea.id) && _player.playing;

          return Dismissible(
            key: ValueKey(idea.id),
            background: Container(color: Colors.redAccent),
            onDismissed: (_) async {
              // If we delete the one that's playing, stop cleanly.
              if (_playingId == idea.id) {
                await _player.stop();
                if (mounted) {
                  setState(() => _playingId = null);
                }
              }
              IdeaStashApp.of(context).deleteIdea(idea.id);
            },
            child: ListTile(
              title: Text(idea.title),
              subtitle: Text(
                '${_fmtDate(idea.createdAt)} • ${_fmtDur(idea.duration)} • ${idea.bpm} BPM • ${idea.keySig}',
              ),
              trailing: IconButton(
                icon: Icon(
                  isThisPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_fill,
                ),
                onPressed: () => _togglePlay(idea),
              ),
              onTap: () => _togglePlay(idea),
            ),
          );
        },
      ),
    );
  }

  String _fmtDur(Duration d) =>
      '${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  String _fmtDate(DateTime dt) {
    final date =
        '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    final time =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }
}
