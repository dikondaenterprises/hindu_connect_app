import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/top_bar.dart';

class MagazineAdminPage extends StatefulWidget {
  const MagazineAdminPage({super.key});
  @override
  State<MagazineAdminPage> createState() => _MagazineAdminPageState();
}

class _MagazineAdminPageState extends State<MagazineAdminPage> {
  final _fs = FirebaseFirestore.instance;
  String _filterTitle = '', _filterCat = '';
  final Set<String> _selected = {};
  String? _newCat;
  final List<String> _cats = ['Mythology', 'Teachings', 'Festivals', 'History'];

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      appBar: const TopBar(title: 'Manage Magazine'),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(children: [
            Expanded(
                child: TextField(
                    decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.title),
                        hintText: 'Filter Title'),
                    onChanged: (v) =>
                        setState(() => _filterTitle = v.toLowerCase()))),
            const SizedBox(width: 8),
            Expanded(
                child: TextField(
                    decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.category),
                        hintText: 'Filter Category'),
                    onChanged: (v) =>
                        setState(() => _filterCat = v.toLowerCase()))),
            const SizedBox(width: 8),
            ElevatedButton.icon(
                icon: const Icon(Icons.delete),
                label: Text('Del(${_selected.length})'),
                onPressed: _selected.isEmpty ? null : _bulkDelete),
            const SizedBox(width: 8),
            DropdownButton<String>(
                value: _newCat,
                hint: const Text('New Cat'),
                items: _cats
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _newCat = v)),
            const SizedBox(width: 4),
            ElevatedButton.icon(
                icon: const Icon(Icons.update),
                label: const Text('Upd'),
                onPressed: (_selected.isEmpty || _newCat == null)
                    ? null
                    : _bulkUpdate),
          ]),
        ),
        Expanded(
            child: StreamBuilder<QuerySnapshot>(
                stream: _fs
                    .collection('magazines')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (_, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snap.data!.docs.where((d) {
                    final m = d.data()! as Map<String, dynamic>;
                    return m['file']
                            .toString()
                            .toLowerCase()
                            .contains(_filterTitle) &&
                        m['category']
                            .toString()
                            .toLowerCase()
                            .contains(_filterCat);
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
                        title: Text(m['file']),
                        subtitle: Text(m['category']));
                  }).toList());
                })),
      ]),
    );
  }

  Future<void> _bulkDelete() async {/*…*/}
  Future<void> _bulkUpdate() async {/*…*/}
}
