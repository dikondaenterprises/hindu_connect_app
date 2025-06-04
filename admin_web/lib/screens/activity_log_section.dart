import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityLogSection extends StatefulWidget {
  const ActivityLogSection({super.key});
  @override
  State<ActivityLogSection> createState() => _ActivityLogSectionState();
}

class _ActivityLogSectionState extends State<ActivityLogSection> {
  final _fs = FirebaseFirestore.instance;
  String _filterUser = '';
  String _filterAction = '';
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activity Logs')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.person), hintText: 'Filter admin'),
                onChanged: (v) => setState(() => _filterUser = v.toLowerCase()),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.history), hintText: 'Filter action'),
                onChanged: (v) =>
                    setState(() => _filterAction = v.toLowerCase()),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete),
              label: Text('Delete (${_selected.length})'),
              onPressed: _selected.isEmpty ? null : _bulkDelete,
            ),
          ]),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _fs
                .collection('activity_logs')
                .orderBy('time', descending: true)
                .snapshots(),
            builder: (_, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data!.docs.where((d) {
                final m = d.data()! as Map<String, dynamic>;
                return m['admin']
                        .toString()
                        .toLowerCase()
                        .contains(_filterUser) &&
                    m['action']
                        .toString()
                        .toLowerCase()
                        .contains(_filterAction);
              }).toList();
              return SingleChildScrollView(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Select')),
                    DataColumn(label: Text('Admin')),
                    DataColumn(label: Text('Action')),
                    DataColumn(label: Text('Time')),
                  ],
                  rows: docs.map((d) {
                    final m = d.data()! as Map<String, dynamic>;
                    final id = d.id;
                    final sel = _selected.contains(id);
                    final ts = (m['time'] as Timestamp).toDate();
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
                        DataCell(Text(m['admin'])),
                        DataCell(Text(m['action'])),
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
        content: Text('Delete ${_selected.length} logs?'),
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
      batch.delete(_fs.collection('activity_logs').doc(id));
    }
    await batch.commit();
    setState(() => _selected.clear());
  }
}
