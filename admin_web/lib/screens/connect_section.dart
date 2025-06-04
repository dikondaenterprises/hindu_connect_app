import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ConnectSection extends StatefulWidget {
  const ConnectSection({super.key});
  @override
  State<ConnectSection> createState() => _ConnectSectionState();
}

class _ConnectSectionState extends State<ConnectSection> {
  final _fs = FirebaseFirestore.instance;
  String _filterTitle = '';
  String _filterCategory = '';
  final Set<String> _selected = {};
  String? _newCategory;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Videos')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search), hintText: 'Filter title'),
                onChanged: (v) =>
                    setState(() => _filterTitle = v.toLowerCase()),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.category),
                    hintText: 'Filter category'),
                onChanged: (v) =>
                    setState(() => _filterCategory = v.toLowerCase()),
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
              value: _newCategory,
              hint: const Text('New Category'),
              items: <String>['Bhajans', 'Teachings', 'Festivals', 'Mythology']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _newCategory = v),
            ),
            const SizedBox(width: 4),
            ElevatedButton.icon(
              icon: const Icon(Icons.update),
              label: const Text('Update'),
              onPressed: (_selected.isEmpty || _newCategory == null)
                  ? null
                  : _bulkUpdate,
            ),
          ]),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _fs
                .collection('videos')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (_, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data!.docs.where((d) {
                final m = d.data()! as Map<String, dynamic>;
                return m['title']
                        .toString()
                        .toLowerCase()
                        .contains(_filterTitle) &&
                    m['category']
                        .toString()
                        .toLowerCase()
                        .contains(_filterCategory);
              }).toList();
              return SingleChildScrollView(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Select')),
                    DataColumn(label: Text('Title')),
                    DataColumn(label: Text('Category')),
                    DataColumn(label: Text('Created At')),
                  ],
                  rows: docs.map((d) {
                    final m = d.data()! as Map<String, dynamic>;
                    final id = d.id;
                    final sel = _selected.contains(id);
                    final ts = (m['createdAt'] as Timestamp).toDate();
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
                        DataCell(Text(m['title'])),
                        DataCell(Text(m['category'])),
                        DataCell(Text(ts.toLocal().toString())),
                      ],
                    );
                  }).toList(),
                ),
              );
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
        content: Text('Delete ${_selected.length} videos?'),
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
      batch.delete(_fs.collection('videos').doc(id));
    }
    await batch.commit();
    setState(() => _selected.clear());
  }

  Future<void> _bulkUpdate() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm update'),
        content: Text(
            'Set category to “$_newCategory” for ${_selected.length} videos?'),
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
    if (ok != true || _newCategory == null) return;
    final batch = _fs.batch();
    for (var id in _selected) {
      batch
          .update(_fs.collection('videos').doc(id), {'category': _newCategory});
    }
    await batch.commit();
    setState(() => _selected.clear());
  }
}
