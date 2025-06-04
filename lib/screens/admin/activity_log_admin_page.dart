import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/top_bar.dart';

class ActivityLogAdminPage extends StatefulWidget {
  const ActivityLogAdminPage({super.key});
  @override
  State<ActivityLogAdminPage> createState() => _ActivityLogAdminPageState();
}

class _ActivityLogAdminPageState extends State<ActivityLogAdminPage> {
  final _fs = FirebaseFirestore.instance;
  String _filterAdmin = '', _filterAction = '';
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      appBar: const TopBar(title: 'Activity Logs'),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(children: [
            Expanded(
                child: TextField(
                    decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.person),
                        hintText: 'Filter Admin'),
                    onChanged: (v) =>
                        setState(() => _filterAdmin = v.toLowerCase()))),
            const SizedBox(width: 8),
            Expanded(
                child: TextField(
                    decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.history),
                        hintText: 'Filter Action'),
                    onChanged: (v) =>
                        setState(() => _filterAction = v.toLowerCase()))),
            const SizedBox(width: 8),
            ElevatedButton.icon(
                icon: const Icon(Icons.delete),
                label: Text('Del(${_selected.length})'),
                onPressed: _selected.isEmpty ? null : _bulkDelete),
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
                            .contains(_filterAdmin) &&
                        m['action']
                            .toString()
                            .toLowerCase()
                            .contains(_filterAction);
                  }).toList();
                  return ListView(
                      children: docs.map((d) {
                    final m = d.data()! as Map<String, dynamic>;
                    final id = d.id;
                    final sel = _selected.contains(id);
                    return CheckboxListTile(
                        value: sel,
                        onChanged: (_) => setState(() =>
                            sel ? _selected.remove(id) : _selected.add(id)),
                        title: Text('${m['admin']} → ${m['action']}'));
                  }).toList());
                })),
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
                ]));
    if (ok != true) return;
    final batch = _fs.batch();
    for (var id in _selected) {
      batch.delete(_fs.collection('activity_logs').doc(id));
    }
    await batch.commit();
    setState(() => _selected.clear());
  }
}
