// lib/screens/temple/temple_viewer_page.dart
// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class TempleViewerPage extends StatefulWidget {
  final String filePath;
  const TempleViewerPage({super.key, required this.filePath});
  @override
  State<TempleViewerPage> createState() => _TempleViewerPageState();
}

class _TempleViewerPageState extends State<TempleViewerPage> {
  String _content = '';
  bool _loading = true, _error = false;
  double _fontSize = 16;
  String _background = 'default';
  bool _isFavorite = false, _isBookmarked = false;
  final _bgOptions = ['default', 'bg1', 'bg2'];

  @override
  void initState() {
    super.initState();
    _loadContent();
    _loadPrefs();
  }

  Future<void> _loadContent() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final cacheFile =
          File('${dir.path}/${widget.filePath.replaceAll("/", "_")}');
      if (await cacheFile.exists()) {
        final encrypted = await cacheFile.readAsString();
        _content = encrypted; // assume encryption handled elsewhere
      } else {
        final url = 'https://<PROJECT>.web.app/${widget.filePath}';
        final res = await http.get(Uri.parse(url));
        if (res.statusCode == 200) {
          _content = res.body;
          await cacheFile.writeAsString(_content);
        } else {
          _error = true;
        }
      }
    } catch (_) {
      _error = true;
    }
    setState(() => _loading = false);
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fontSize = prefs.getDouble('${widget.filePath}_font') ?? 16;
      _background = prefs.getString('${widget.filePath}_bg') ?? 'default';
      _isFavorite = prefs.getBool('${widget.filePath}_fav') ?? false;
      _isBookmarked = prefs.getBool('${widget.filePath}_bm') ?? false;
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble('${widget.filePath}_font', _fontSize);
    prefs.setString('${widget.filePath}_bg', _background);
    prefs.setBool('${widget.filePath}_fav', _isFavorite);
    prefs.setBool('${widget.filePath}_bm', _isBookmarked);
  }

  void _changeFont(double delta) {
    setState(() => _fontSize = (_fontSize + delta).clamp(12.0, 30.0));
    _savePrefs();
  }

  void _resetFont() {
    setState(() => _fontSize = 16);
    _savePrefs();
  }

  void _switchBg() {
    final idx = _bgOptions.indexOf(_background);
    setState(() => _background = _bgOptions[(idx + 1) % _bgOptions.length]);
    _savePrefs();
  }

  void _toggleFav() {
    setState(() => _isFavorite = !_isFavorite);
    _savePrefs();
  }

  void _toggleBm() {
    setState(() => _isBookmarked = !_isBookmarked);
    _savePrefs();
  }

  void _shareLink() {
    final link =
        'https://hinduconnect.app/temple?file=${Uri.encodeComponent(widget.filePath)}';
    Share.share('Explore this temple: $link');
  }

  void _report() {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Report submitted')));
  }

  AssetImage _bgImage() {
    switch (_background) {
      case 'bg1':
        return const AssetImage('assets/images/temple_bg1.jpg');
      case 'bg2':
        return const AssetImage('assets/images/temple_bg2.jpg');
      default:
        return const AssetImage('assets/images/temple_default.jpg');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Failed to load temple')),
      );
    }
    final title = widget.filePath
        .split('/')
        .last
        .replaceAll('.md', '')
        .replaceAll('-', ' ');
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
              icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
              onPressed: _toggleFav),
          IconButton(
              icon:
                  Icon(_isBookmarked ? Icons.bookmark : Icons.bookmark_border),
              onPressed: _toggleBm),
          IconButton(icon: const Icon(Icons.share), onPressed: _shareLink),
          IconButton(icon: const Icon(Icons.report), onPressed: _report),
        ],
      ),
      body: Stack(children: [
        Image(
            image: _bgImage(),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity),
        Container(color: Colors.black.withOpacity(0.3)),
        Column(children: [
          Expanded(
            child: Markdown(
              data: _content,
              styleSheet:
                  MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                p: TextStyle(fontSize: _fontSize, color: Colors.white),
              ),
            ),
          ),
          Container(
            color: Colors.black54,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                      icon:
                          const Icon(Icons.text_decrease, color: Colors.white),
                      onPressed: () => _changeFont(-2)),
                  IconButton(
                      icon: const Icon(Icons.text_fields, color: Colors.white),
                      onPressed: _resetFont),
                  IconButton(
                      icon:
                          const Icon(Icons.text_increase, color: Colors.white),
                      onPressed: () => _changeFont(2)),
                  IconButton(
                      icon: const Icon(Icons.wallpaper, color: Colors.white),
                      onPressed: _switchBg),
                ]),
          ),
        ]),
      ]),
    );
  }
}
