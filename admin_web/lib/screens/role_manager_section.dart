import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoleManagerSection extends StatefulWidget {
  const RoleManagerSection({super.key});
  @override
  State<RoleManagerSection> createState() => _RoleManagerSectionState();
}

class _RoleManagerSectionState extends State<RoleManagerSection> {
  final _fs = FirebaseFirestore.instance;
  String _filterName = '';
  String _filterRole = '';
  final Set<String> _selected = {};
  String? _newRole;
  final List<String> _roles = [
    'SuperAdmin',
    'ContentMgr',
    'NotifMgr',
    'Viewer'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Roles')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.person), hintText: 'Filter name'),
                onChanged: (v) => setState(() => _filterName = v.toLowerCase()),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.admin_panel_settings),
                    hintText: 'Filter role'),
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
            stream: _fs.collection('admins').snapshots(),
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
              return SingleChildScrollView(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Select')),
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Role')),
                    DataColumn(label: Text('Assigned At')),
                  ],
                  rows: docs.map((d) {
                    final m = d.data()! as Map<String, dynamic>;
                    final id = d.id;
                    final sel = _selected.contains(id);
                    final ts = (m['assignedAt'] as Timestamp).toDate();
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
                        DataCell(Text(m['name'])),
                        DataCell(Text(m['role'])),
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
