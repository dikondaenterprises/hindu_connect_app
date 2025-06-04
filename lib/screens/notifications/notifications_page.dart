// lib/screens/notifications/notifications_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../widgets/top_bar.dart';
import '../../widgets/bottom_nav.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});
  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _fs = FirebaseFirestore.instance;
  final Set<String> _selected = {};

  void _toggle(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  Future<void> _deleteSelected() async {
    if (_selected.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete selected?'),
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
    for (var id in _selected) {
      await _fs.collection('notifications').doc(id).delete();
    }
    _selected.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopBar(title: 'Notifications'),
      bottomNavigationBar: const BottomNav(),
      body: Column(
        children: [
          if (_selected.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.delete),
                label: Text('Delete Selected (${_selected.length})'),
                onPressed: _deleteSelected,
              ),
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
                final docs = snap.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text('No notifications.'));
                }
                return ListView(
                  children: docs.map((d) {
                    final m = d.data()! as Map<String, dynamic>;
                    final id = d.id;
                    final sel = _selected.contains(id);
                    final ts = (m['timestamp'] as Timestamp).toDate();
                    return CheckboxListTile(
                      value: sel,
                      onChanged: (_) => _toggle(id),
                      title: Text(m['title'] ?? ''),
                      subtitle: Text('${m['message']}\n${ts.toLocal()}'),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
