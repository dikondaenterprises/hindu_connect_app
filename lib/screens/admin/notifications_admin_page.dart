import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/top_bar.dart';

class NotificationsAdminPage extends StatefulWidget {
  const NotificationsAdminPage({super.key});
  @override
  State<NotificationsAdminPage> createState() => _NotificationsAdminPageState();
}

class _NotificationsAdminPageState extends State<NotificationsAdminPage> {
  final _fs = FirebaseFirestore.instance;
  String _filterTitle = '', _filterMsg = '';
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      appBar: const TopBar(title: 'Manage Notifications'),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.title), hintText: 'Filter Title'),
                onChanged: (v) =>
                    setState(() => _filterTitle = v.toLowerCase()),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.message),
                    hintText: 'Filter Message'),
                onChanged: (v) => setState(() => _filterMsg = v.toLowerCase()),
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
              return ListView(
                children: docs.map((d) {
                  final m = d.data()! as Map<String, dynamic>;
                  final id = d.id;
                  final sel = _selected.contains(id);
                  return CheckboxListTile(
                    value: sel,
                    onChanged: (_) => setState(
                        () => sel ? _selected.remove(id) : _selected.add(id)),
                    title: Text(m['title']),
                    subtitle: Text(m['message']),
                  );
                }).toList(),
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
        content: Text('Delete ${_selected.length} items?'),
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
}
