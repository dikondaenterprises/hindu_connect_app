import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/top_bar.dart';

class TemplesAdminPage extends StatefulWidget {
  const TemplesAdminPage({super.key});
  @override
  State<TemplesAdminPage> createState() => _TemplesAdminPageState();
}

class _TemplesAdminPageState extends State<TemplesAdminPage> {
  final _fs = FirebaseFirestore.instance;
  String _filterState = '', _filterName = '';
  final Set<String> _selected = {};
  String? _newState;
  final List<String> _states = [
    'AndhraPradesh',
    'Maharashtra',
    'Telangana', /*…*/
  ];

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      appBar: const TopBar(title: 'Manage Temples'),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(children: [
            Expanded(
                child: TextField(
                    decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.map), hintText: 'Filter State'),
                    onChanged: (v) =>
                        setState(() => _filterState = v.toLowerCase()))),
            const SizedBox(width: 8),
            Expanded(
                child: TextField(
                    decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.account_balance),
                        hintText: 'Filter Name'),
                    onChanged: (v) =>
                        setState(() => _filterName = v.toLowerCase()))),
            const SizedBox(width: 8),
            ElevatedButton.icon(
                icon: const Icon(Icons.delete),
                label: Text('Del(${_selected.length})'),
                onPressed: _selected.isEmpty ? null : _bulkDelete),
            const SizedBox(width: 8),
            DropdownButton<String>(
                value: _newState,
                hint: const Text('New State'),
                items: _states
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _newState = v)),
            const SizedBox(width: 4),
            ElevatedButton.icon(
                icon: const Icon(Icons.update),
                label: const Text('Upd'),
                onPressed: (_selected.isEmpty || _newState == null)
                    ? null
                    : _bulkUpdate),
          ]),
        ),
        Expanded(
            child: StreamBuilder<QuerySnapshot>(
                stream: _fs.collection('temples').orderBy('state').snapshots(),
                builder: (_, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snap.data!.docs.where((d) {
                    final m = d.data()! as Map<String, dynamic>;
                    return m['state']
                            .toString()
                            .toLowerCase()
                            .contains(_filterState) &&
                        m['name']
                            .toString()
                            .toLowerCase()
                            .contains(_filterName);
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
                        title: Text('${m['state']} → ${m['name']}'));
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
      batch.delete(_fs.collection('temples').doc(id));
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
                    Text('Set state to $_newState for ${_selected.length}?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel')),
                  ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Update')),
                ]));
    if (ok != true || _newState == null) return;
    final batch = _fs.batch();
    for (var id in _selected) {
      batch.update(_fs.collection('temples').doc(id), {'state': _newState});
    }
    await batch.commit();
    setState(() => _selected.clear());
  }
}
