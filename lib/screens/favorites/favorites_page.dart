// lib/screens/favorites/favorites_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../../widgets/top_bar.dart';
import '../../widgets/bottom_nav.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});
  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<FileSystemEntity> _files = [];
  final Set<String> _selected = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final dir = await getApplicationDocumentsDirectory();
    final all = dir.listSync().where(
        (f) => f.path.contains('_stotra_') || f.path.contains('_temple_'));
    setState(() {
      _files = all.toList();
      _loading = false;
    });
  }

  void _toggleSelect(String path) {
    setState(() {
      if (_selected.contains(path)) {
        _selected.remove(path);
      } else {
        _selected.add(path);
      }
    });
  }

  Future<void> _deleteSelected() async {
    if (_selected.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete selected?'),
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
    for (var path in _selected) {
      try {
        await File(path).delete();
      } catch (_) {}
    }
    _selected.clear();
    _loadFavorites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopBar(title: 'Favorites'),
      bottomNavigationBar: const BottomNav(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
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
                  child: ListView.builder(
                    itemCount: _files.length,
                    itemBuilder: (_, i) {
                      final file = _files[i];
                      final name = file.path.split('/').last;
                      final sel = _selected.contains(file.path);
                      return CheckboxListTile(
                        value: sel,
                        onChanged: (_) => _toggleSelect(file.path),
                        title: Text(name),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
