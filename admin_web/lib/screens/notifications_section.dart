import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationsSection extends StatefulWidget {
  const NotificationsSection({super.key});
  @override
  State<NotificationsSection> createState() => _NotificationsSectionState();
}

class _NotificationsSectionState extends State<NotificationsSection> {
  final _fs = FirebaseFirestore.instance;
  String _filterTitle = '';
  String _filterMsg = '';
  final Set<String> _selected = {};
  String? _newTitle;
  String? _newMsg;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Notifications')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.title), hintText: 'Filter title'),
                onChanged: (v) =>
                    setState(() => _filterTitle = v.toLowerCase()),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.message),
                    hintText: 'Filter message'),
                onChanged: (v) => setState(() => _filterMsg = v.toLowerCase()),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete),
              label: Text('Delete (${_selected.length})'),
              onPressed: _selected.isEmpty ? null : _bulkDelete,
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.update),
              label: const Text('Update Title'),
              onPressed: (_selected.isEmpty || _newTitle == null)
                  ? null
                  : _bulkUpdateTitle,
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.update),
              label: const Text('Update Msg'),
              onPressed: (_selected.isEmpty || _newMsg == null)
                  ? null
                  : _bulkUpdateMsg,
            ),
          ]),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _fs
                .collection('notifications')
                .orderBy('timestamp', descending: true)
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
                    m['message'].toString().toLowerCase().contains(_filterMsg);
              }).toList();
              return SingleChildScrollView(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Select')),
                    DataColumn(label: Text('Title')),
                    DataColumn(label: Text('Message')),
                    DataColumn(label: Text('Timestamp')),
                  ],
                  rows: docs.map((d) {
                    final m = d.data()! as Map<String, dynamic>;
                    final id = d.id;
                    final sel = _selected.contains(id);
                    final ts = (m['timestamp'] as Timestamp).toDate();
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
                        DataCell(Text(m['message'])),
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
        content: Text('Delete ${_selected.length} notifications?'),
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
      batch.delete(_fs.collection('notifications').doc(id));
    }
    await batch.commit();
    setState(() => _selected.clear());
  }

  Future<void> _bulkUpdateTitle() async {
    final title = await _promptInput('New Title');
    if (title == null) return;
    final batch = _fs.batch();
    for (var id in _selected) {
      batch.update(_fs.collection('notifications').doc(id), {'title': title});
    }
    await batch.commit();
    setState(() => _selected.clear());
  }

  Future<void> _bulkUpdateMsg() async {
    final msg = await _promptInput('New Message');
    if (msg == null) return;
    final batch = _fs.batch();
    for (var id in _selected) {
      batch.update(_fs.collection('notifications').doc(id), {'message': msg});
    }
    await batch.commit();
    setState(() => _selected.clear());
  }

  Future<String?> _promptInput(String label) {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(label),
        content: TextField(controller: ctrl),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, ctrl.text),
              child: const Text('OK')),
        ],
      ),
    );
  }
}
