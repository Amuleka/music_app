import 'package:flutter/material.dart';
import '../models/idea.dart';
import '../main.dart';
import '../services/transcribe_service.dart';
import '../services/midi_native.dart'; // MIDI MethodChannel

class RefineScreen extends StatefulWidget {
  const RefineScreen({super.key});

  @override
  State<RefineScreen> createState() => _RefineScreenState();
}

class _RefineScreenState extends State<RefineScreen> {
  // -------- state --------
  Idea? idea;
  final TextEditingController _title = TextEditingController();
  bool _initialized = false;

  int _bpm = 120;
  String _key = 'C Maj';
  bool _drums = false, _guitar = false, _lead = false;

  final _keys = const [
    'C Maj','G Maj','D Maj','A Maj','E Maj','F Maj','Bb Maj',
    'A Min','E Min','D Min','C Min'
  ];

  final _svc = TranscribeService();

  // 👉 paste current ngrok URL here
  static const String _apiBase =
      'https://apocopic-senselessly-manuel.ngrok-free.dev';

  bool _saving = false;

  // MIDI preview (path to the AI-generated MIDI)
  String? _midiPath;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Idea) {
      idea = args;
      _title.text = idea!.title;
      _bpm = idea!.bpm;
      _key = idea!.keySig;
      _drums = idea!.addDrums;
      _guitar = idea!.addGuitar;
      _lead = idea!.addLead;
    }
    _initialized = true;
  }

  @override
  void dispose() {
    _title.dispose();
    // make sure preview audio stops if user leaves the screen
    midiStop().ignore();
    super.dispose();
  }

  Future<void> _save() async {
    if (idea == null) return;

    setState(() => _saving = true);

    // 1) Call AI (non-fatal if it fails)
    String? midiPath;
    try {
      midiPath = await _svc.transcribeToMidi(
        apiBase: _apiBase,
        audioPath: idea!.filePath,
        bpm: _bpm,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI transcribe failed: $e')),
      );
    }

    // 2) Persist UI edits
    idea!
      ..title = _title.text.trim().isEmpty ? idea!.title : _title.text.trim()
      ..bpm = _bpm
      ..keySig = _key
      ..addDrums = _drums
      ..addGuitar = _guitar
      ..addLead = _lead;

    if (midiPath != null && mounted) {
      _midiPath = midiPath;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('MIDI saved: $midiPath')),
      );
      // If your Idea model supports it:
      // idea!.midiPath = midiPath;
    }

    IdeaStashApp.of(context).updateIdea(idea!);

    if (!mounted) return;
    setState(() => _saving = false);

    // If no MIDI to preview, navigate back like before
    if (_midiPath == null) {
      Navigator.popUntil(context, ModalRoute.withName('/'));
    }
  }

  Widget _previewRow() {
    if (_midiPath == null) return const SizedBox.shrink();
    return Row(
      children: [
        FilledButton.icon(
          onPressed: () async {
            try {
              final ok = await midiLoad(midiPath: _midiPath!);
              if (!mounted) return;
              if (ok) {
                await midiPlay();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to load MIDI')),
                );
              }
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('MIDI error: $e')),
              );
            }
          },
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Play MIDI'),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: () => midiStop(),
          icon: const Icon(Icons.stop_rounded),
          label: const Text('Stop'),
        ),
        const Spacer(),
        TextButton(
          onPressed: () =>
              Navigator.popUntil(context, ModalRoute.withName('/')),
          child: const Text('Done'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ideaLocal = idea;
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: const Text('Refine your idea')),
          body: ideaLocal == null
              ? const Center(child: Text('No idea loaded'))
              : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _title,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('BPM', style: TextStyle(fontSize: 16)),
                  Expanded(
                    child: Slider(
                      value: _bpm.toDouble(),
                      min: 60,
                      max: 180,
                      divisions: 120,
                      label: '$_bpm',
                      onChanged: (v) =>
                          setState(() => _bpm = v.round()),
                    ),
                  ),
                  SizedBox(
                    width: 64,
                    child: Text('$_bpm', textAlign: TextAlign.right),
                  )
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _key,
                items: _keys
                    .map(
                      (k) => DropdownMenuItem(
                    value: k,
                    child: Text(k),
                  ),
                )
                    .toList(),
                onChanged: (v) => setState(() => _key = v!),
                decoration: const InputDecoration(
                  labelText: 'Key',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Add instruments',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SwitchListTile(
                title: const Text('Drums'),
                value: _drums,
                onChanged: (v) => setState(() => _drums = v),
              ),
              SwitchListTile(
                title: const Text('Guitar'),
                value: _guitar,
                onChanged: (v) => setState(() => _guitar = v),
              ),
              SwitchListTile(
                title: const Text('Lead'),
                value: _lead,
                onChanged: (v) => setState(() => _lead = v),
              ),
              const SizedBox(height: 16),
              _previewRow(),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Save'),
              ),
            ],
          ),
        ),

        if (_saving)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black38,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text(
                      'Transcribing with AI…',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
