import 'package:flutter/material.dart';
import '../models/idea.dart';
import '../main.dart';

class RefineScreen extends StatefulWidget {
  const RefineScreen({super.key});

  @override
  State<RefineScreen> createState() => _RefineScreenState();
}

class _RefineScreenState extends State<RefineScreen> {
  late Idea idea;
  late final TextEditingController _title;
  int _bpm = 120;
  String _key = 'C Maj';
  bool _drums = false, _guitar = false, _lead = false;

  final _keys = const [
    'C Maj','G Maj','D Maj','A Maj','E Maj','F Maj','Bb Maj',
    'A Min','E Min','D Min','C Min'
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    idea = ModalRoute.of(context)!.settings.arguments as Idea;
    _title = TextEditingController(text: idea.title);
    _bpm = idea.bpm;
    _key = idea.keySig;
    _drums = idea.addDrums;
    _guitar = idea.addGuitar;
    _lead = idea.addLead;
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _save() {
    idea
      ..title = _title.text.trim().isEmpty ? idea.title : _title.text.trim()
      ..bpm = _bpm
      ..keySig = _key
      ..addDrums = _drums
      ..addGuitar = _guitar
      ..addLead = _lead;
    IdeaStashApp.of(context).updateIdea(idea);
    Navigator.popUntil(context, ModalRoute.withName('/'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Refine your idea')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _title,
            decoration: const InputDecoration(
                labelText: 'Title', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('BPM', style: TextStyle(fontSize: 16)),
              Expanded(
                child: Slider(
                  value: _bpm.toDouble(),
                  min: 60, max: 180, divisions: 120,
                  label: '$_bpm',
                  onChanged: (v) => setState(() => _bpm = v.round()),
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
            items: _keys.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
            onChanged: (v) => setState(() => _key = v!),
            decoration: const InputDecoration(
                labelText: 'Key', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          const Text('Add instruments', style: TextStyle(fontWeight: FontWeight.w600)),
          SwitchListTile(
              title: const Text('Drums'),
              value: _drums, onChanged: (v) => setState(() => _drums = v)),
          SwitchListTile(
              title: const Text('Guitar'),
              value: _guitar, onChanged: (v) => setState(() => _guitar = v)),
          SwitchListTile(
              title: const Text('Lead'),
              value: _lead, onChanged: (v) => setState(() => _lead = v)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check_rounded),
            label: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
