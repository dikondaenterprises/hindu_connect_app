import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/top_bar.dart';

class StotrasAdminPage extends StatefulWidget {
  const StotrasAdminPage({super.key});
  @override
  State<StotrasAdminPage> createState() => _StotrasAdminPageState();
}

class _StotrasAdminPageState extends State<StotrasAdminPage> {
  final _fs = FirebaseFirestore.instance;
  String _filter = '';
  final Set<String> _selected = {};
  String? _newLang;
  final List<String> _langs = [
    'Assamese',
    'Bengali',
    'Devanagari',
    'Gujarati',
    'Kannada',
    'Malayalam',
    'Oriya',
    'Punjabi',
    'English',
    'Tamil',
    'Telugu',
    'Urdu'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopBar(title: 'Manage Stotras'),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Filter file/lang'),
                onChanged: (v) => setState(() => _filter = v.toLowerCase()),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
                icon: const Icon(Icons.delete),
                label: Text('Del(${_selected.length})'),
                onPressed: _selected.isEmpty ? null : _bulkDelete),
            const SizedBox(width: 8),
            DropdownButton<String>(
                value: _newLang,
                hint: const Text('New Lang'),
                items: _langs
                    .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                    .toList(),
                onChanged: (v) => setState(() => _newLang = v)),
            const SizedBox(width: 4),
            ElevatedButton.icon(
                icon: const Icon(Icons.update),
                label: const Text('Upd'),
                onPressed: (_selected.isEmpty || _newLang == null)
                    ? null
                    : _bulkUpdate),
          ]),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _fs
                .collection('stotras')
                .orderBy('uploadedAt', descending: true)
                .snapshots(),
            builder: (_, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data!.docs.where((d) {
                final m = d.data()! as Map<String, dynamic>;
                return m['file'].toString().toLowerCase().contains(_filter) ||
                    m['lang'].toString().toLowerCase().contains(_filter);
              }).toList();
              return ListView(
                  children: docs.map((d) {
                final m = d.data()! as Map<String, dynamic>;
                final id = d.id;
                final sel = _selected.contains(id);
                return CheckboxListTile(
                  value: sel,
                  onChanged: (_) => setState(
                      () => sel ? _selected.remove(id) : _selected.add(id)),
                  title: Text('${m['lang']} → ${m['file']}'),
                );
              }).toList());
            },
          ),
        ),
      ]),
    );
  }

  Future<void> _bulkDelete() async {
    final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text('Confirm delete'),
              content: Text('Delete ${_selected.length}?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel')),
                ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Delete')),
              ],
            ));
    if (ok != true) return;
    final batch = _fs.batch();
    for (var id in _selected) {
      batch.delete(_fs.collection('stotras').doc(id));
    }
    await batch.commit();
    setState(() => _selected.clear());
  }

  Future<void> _bulkUpdate() async {
    final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text('Confirm update'),
              content: Text('Set lang to $_newLang for ${_selected.length}?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel')),
                ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Update')),
              ],
            ));
    if (ok != true || _newLang == null) return;
    final batch = _fs.batch();
    for (var id in _selected) {
      batch.update(_fs.collection('stotras').doc(id), {'lang': _newLang});
    }
    await batch.commit();
    setState(() => _selected.clear());
  }
}
