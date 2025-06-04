import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';

class OfflineSyncPage extends StatefulWidget {
  final String langCode;
  const OfflineSyncPage({super.key, required this.langCode});
  @override
  State<OfflineSyncPage> createState() => _OfflineSyncPageState();
}

class _OfflineSyncPageState extends State<OfflineSyncPage> {
  List<Map<String, dynamic>> _files = [];
  final Set<String> _downloading = {};
  Set<String> _downloaded = {};

  @override
  void initState() {
    super.initState();
    _loadList();
    _loadDownloaded();
  }

  Future<void> _loadList() async {
    final snap = await FirebaseFirestore.instance
        .collection('stotras')
        .where('lang', isEqualTo: widget.langCode)
        .get();
    setState(() {
      _files = snap.docs.map((d) => {'id': d.id, 'file': d['file']}).toList();
    });
  }

  Future<void> _loadDownloaded() async {
    final dir = await getApplicationDocumentsDirectory();
    final all = dir.listSync().map((e) => e.path.split('/').last).toSet();
    setState(() => _downloaded = all);
  }

  Future<void> _download(String file) async {
    final dir = await getApplicationDocumentsDirectory();
    final url = 'https://<PROJECT>.web.app/stotras/${widget.langCode}/$file';
    final res =
        await HttpClient().getUrl(Uri.parse(url)).then((r) => r.close());
    final content = await res.transform(const Utf8Decoder()).join();
    final f = File('${dir.path}/$file');
    await f.writeAsString(content);
    setState(() {
      _downloaded.add(file);
      _downloading.remove(file);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offline Sync')),
      body: ListView.builder(
        itemCount: _files.length,
        itemBuilder: (_, i) {
          final file = _files[i]['file'] as String;
          final loading = _downloading.contains(file);
          final done = _downloaded.contains(file);
          return ListTile(
            title: Text(file),
            trailing: done
                ? const Icon(Icons.check, color: Colors.green)
                : loading
                    ? const CircularProgressIndicator()
                    : IconButton(
                        icon: const Icon(Icons.download),
                        onPressed: () {
                          setState(() => _downloading.add(file));
                          _download(file);
                        },
                      ),
          );
        },
      ),
    );
  }
}
