// lib/screens/connect/connect_page.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/top_bar.dart';
import '../../widgets/bottom_nav.dart';

class ConnectPage extends StatefulWidget {
  const ConnectPage({super.key, required String filePath});
  @override
  State<ConnectPage> createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage> {
  final _fs = FirebaseFirestore.instance;
  Set<String> _liked = {}, _disliked = {}, _saved = {};
  List<String> _history = [];

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _liked = p.getStringList('video_likes')?.toSet() ?? {};
      _disliked = p.getStringList('video_dislikes')?.toSet() ?? {};
      _saved = p.getStringList('video_saved')?.toSet() ?? {};
      _history = p.getStringList('video_history') ?? [];
    });
  }

  Future<void> _updatePrefs() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList('video_likes', _liked.toList());
    await p.setStringList('video_dislikes', _disliked.toList());
    await p.setStringList('video_saved', _saved.toList());
    await p.setStringList('video_history', _history);
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
    Share.share('Watch: https://hinuconnect.app/connect?video=$id');
  }

  void _report(String id) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Reported')));
  }

  void _recordWatch(String id) {
    setState(() {
      _history.remove(id);
      _history.insert(0, id);
      if (_history.length > 50) _history.removeLast();
    });
    _updatePrefs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopBar(title: 'Connect'),
      bottomNavigationBar: const BottomNav(),
      body: StreamBuilder<QuerySnapshot>(
        stream: _fs
            .collection('videos')
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
              final d = docs[i].data()! as Map<String, dynamic>;
              final id = docs[i].id;
              final isLike = _liked.contains(id);
              final isDis = _disliked.contains(id);
              final isSave = _saved.contains(id);
              return Card(
                margin: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    ListTile(
                      leading: Image.network(
                          'https://img.youtube.com/vi/${d['videoId']}/0.jpg'),
                      title: Text(d['title'] ?? ''),
                      subtitle: Text(d['category'] ?? ''),
                      onTap: () => _recordWatch(id),
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
                            icon: const Icon(Icons.report),
                            onPressed: () => _report(id)),
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
