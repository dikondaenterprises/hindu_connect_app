import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StotrasSection extends StatefulWidget {
  const StotrasSection({super.key});
  @override
  State<StotrasSection> createState() => _StotrasSectionState();
}

class _StotrasSectionState extends State<StotrasSection> {
  final _fs = FirebaseFirestore.instance;
  String _filterLang = '';
  String _filterFile = '';
  final Set<String> _selected = {};
  String? _newLang;
  final List<String> _languages = [
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
      appBar: AppBar(title: const Text('Manage Stotras')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.language),
                    hintText: 'Filter Language',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) =>
                      setState(() => _filterLang = v.toLowerCase()),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.description),
                    hintText: 'Filter File',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) =>
                      setState(() => _filterFile = v.toLowerCase()),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.delete),
                label: Text('Delete (${_selected.length})'),
                onPressed: _selected.isEmpty ? null : _bulkDelete,
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _newLang,
                hint: const Text('New Lang'),
                items: _languages
                    .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                    .toList(),
                onChanged: (v) => setState(() => _newLang = v),
              ),
              const SizedBox(width: 4),
              ElevatedButton.icon(
                icon: const Icon(Icons.update),
                label: const Text('Update'),
                onPressed: (_selected.isEmpty || _newLang == null)
                    ? null
                    : _bulkUpdate,
              ),
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
                  return m['lang']
                          .toString()
                          .toLowerCase()
                          .contains(_filterLang) &&
                      m['file'].toString().toLowerCase().contains(_filterFile);
                }).toList();
                return SingleChildScrollView(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Select')),
                      DataColumn(label: Text('Lang')),
                      DataColumn(label: Text('File')),
                      DataColumn(label: Text('Uploaded At')),
                    ],
                    rows: docs.map((d) {
                      final m = d.data()! as Map<String, dynamic>;
                      final id = d.id;
                      final sel = _selected.contains(id);
                      final ts = (m['uploadedAt'] as Timestamp).toDate();
                      return DataRow(
                        selected: sel,
                        onSelectChanged: (v) {
                          setState(() {
                            if (v == true) {
                              _selected.add(id);
                            } else {
                              _selected.remove(id);
                            }
                          });
                        },
                        cells: [
                          DataCell(Checkbox(
                              value: sel,
                              onChanged: (v) {
                                setState(() {
                                  if (v == true) {
                                    _selected.add(id);
                                  } else {
                                    _selected.remove(id);
                                  }
                                });
                              })),
                          DataCell(Text(m['lang'])),
                          DataCell(Text(m['file'])),
                          DataCell(Text(ts.toLocal().toString())),
                        ],
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _bulkDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm delete'),
        content: Text('Delete ${_selected.length} stotras?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
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
        content:
            Text('Set language to “$_newLang” for ${_selected.length} items?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Update')),
        ],
      ),
    );
    if (ok != true || _newLang == null) return;
    final batch = _fs.batch();
    for (var id in _selected) {
      batch.update(_fs.collection('stotras').doc(id), {'lang': _newLang});
    }
    await batch.commit();
    setState(() => _selected.clear());
  }
}
