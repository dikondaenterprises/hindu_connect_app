// lib/screens/magazine/magazine_page.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../../widgets/top_bar.dart';
import '../../widgets/bottom_nav.dart';

class MagazinePage extends StatefulWidget {
  const MagazinePage({super.key, required String filePath});
  @override
  State<MagazinePage> createState() => _MagazinePageState();
}

class _MagazinePageState extends State<MagazinePage> {
  final _fs = FirebaseFirestore.instance;
  Set<String> _liked = {}, _disliked = {}, _saved = {};

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _liked = p.getStringList('magazine_likes')?.toSet() ?? {};
      _disliked = p.getStringList('magazine_dislikes')?.toSet() ?? {};
      _saved = p.getStringList('magazine_saved')?.toSet() ?? {};
    });
  }

  Future<void> _updatePrefs() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList('magazine_likes', _liked.toList());
    await p.setStringList('magazine_dislikes', _disliked.toList());
    await p.setStringList('magazine_saved', _saved.toList());
  }

  void _toggleLike(String id) {
    setState(() {
      if (_liked.contains(id)) {
        _liked.remove(id);
      } else {
        _liked.add(id);
        _disliked.remove(id);
      }
    });
    _updatePrefs();
  }

  void _toggleDislike(String id) {
    setState(() {
      if (_disliked.contains(id)) {
        _disliked.remove(id);
      } else {
        _disliked.add(id);
        _liked.remove(id);
      }
    });
    _updatePrefs();
  }

  void _toggleSave(String id) {
    setState(() {
      if (_saved.contains(id)) {
        _saved.remove(id);
      } else {
        _saved.add(id);
      }
    });
    _updatePrefs();
  }

  void _share(String id) {
    Share.share('Read: https://hinduconnect.app/magazine?doc=$id');
  }

  void _report() {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Reported')));
  }

  void _open(BuildContext ctx, String path) => Navigator.push(
      ctx,
      MaterialPageRoute(
          builder: (_) => Scaffold(
                appBar: AppBar(title: Text(path.split('/').last)),
                body: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Markdown(data: path)), // fetch real content
              )));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopBar(title: 'Magazine'),
      bottomNavigationBar: const BottomNav(),
      body: StreamBuilder<QuerySnapshot>(
        stream: _fs
            .collection('magazines')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (_, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final m = docs[i].data()! as Map<String, dynamic>;
              final id = docs[i].id;
              final isLike = _liked.contains(id);
              final isDis = _disliked.contains(id);
              final isSave = _saved.contains(id);
              final path = m['path'] as String;
              return Card(
                margin: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    ListTile(
                      title: Text(m['file']),
                      subtitle: Text(m['category'] ?? ''),
                      onTap: () => _open(context, path),
                    ),
                    OverflowBar(
                      children: [
                        IconButton(
                            icon: Icon(Icons.thumb_up,
                                color: isLike ? Colors.green : null),
                            onPressed: () => _toggleLike(id)),
                        IconButton(
                            icon: Icon(Icons.thumb_down,
                                color: isDis ? Colors.red : null),
                            onPressed: () => _toggleDislike(id)),
                        IconButton(
                            icon: Icon(isSave
                                ? Icons.bookmark
                                : Icons.bookmark_border),
                            onPressed: () => _toggleSave(id)),
                        IconButton(
                            icon: const Icon(Icons.share),
                            onPressed: () => _share(id)),
                        IconButton(
                            icon: const Icon(Icons.report), onPressed: _report),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
