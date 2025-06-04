import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/top_bar.dart';

class RoleManager extends StatefulWidget {
  const RoleManager({super.key});
  @override
  State<RoleManager> createState() => _RoleManagerState();
}

class _RoleManagerState extends State<RoleManager> {
  final _fs = FirebaseFirestore.instance;
  String _filterName = '', _filterRole = '';
  final Set<String> _selected = {};
  final List<String> _roles = ['super', 'content', 'notification', 'viewer'];

  String? _newRole;

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      appBar: const TopBar(title: 'Role Manager'),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.person), hintText: 'Filter Name'),
                onChanged: (v) => setState(() => _filterName = v.toLowerCase()),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.admin_panel_settings),
                    hintText: 'Filter Role'),
                onChanged: (v) => setState(() => _filterRole = v.toLowerCase()),
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
              value: _newRole,
              hint: const Text('New Role'),
              items: _roles
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) => setState(() => _newRole = v),
            ),
            const SizedBox(width: 4),
            ElevatedButton.icon(
              icon: const Icon(Icons.update),
              label: const Text('Update'),
              onPressed:
                  (_selected.isEmpty || _newRole == null) ? null : _bulkUpdate,
            ),
          ]),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _fs
                .collection('admins')
                .orderBy('assignedAt', descending: true)
                .snapshots(),
            builder: (_, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data!.docs.where((d) {
                final m = d.data()! as Map<String, dynamic>;
                return m['name']
                        .toString()
                        .toLowerCase()
                        .contains(_filterName) &&
                    m['role'].toString().toLowerCase().contains(_filterRole);
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
                    title: Text(m['name']),
                    subtitle: Text(m['role']),
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
        content: Text('Delete ${_selected.length} admins?'),
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
      batch.delete(_fs.collection('admins').doc(id));
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
            Text('Set role to “$_newRole” for ${_selected.length} admins?'),
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
    if (ok != true || _newRole == null) return;
    final batch = _fs.batch();
    for (var id in _selected) {
      batch.update(_fs.collection('admins').doc(id), {'role': _newRole});
    }
    await batch.commit();
    setState(() => _selected.clear());
  }
}
