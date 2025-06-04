// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../utils/language_utils.dart';

class ViewerPage extends StatefulWidget {
  final String filePath;
  const ViewerPage({super.key, required this.filePath});

  @override
  State<ViewerPage> createState() => _ViewerPageState();
}

class _ViewerPageState extends State<ViewerPage> {
  double _fontSize = 18.0;
  String _fileContent = '';
  String _background = 'default';
  final List<String> _backgrounds = ['default', 'bg1', 'bg2'];
  bool _isFavorite = false;
  bool _isBookmarked = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadContent();
    _loadPreferences();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadContent() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    final selectedLang = (prefs.getString('lang') ?? 'English');
    final targetScript = LanguageUtils.getAksharamukhaScriptCode(selectedLang);

    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final filePath = args?['filePath'] ?? widget.filePath;
    final needsTransliteration = args?['needsTransliteration'] ??
        !LanguageUtils.directAccessLanguages.contains(targetScript);

    if (!needsTransliteration) {
      final uri = Uri.parse('https://hinduconnect.app/$filePath');
      final response = await http.get(uri);
      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() => _fileContent = response.body);
      } else {
        setState(() => _fileContent = 'Failed to load stotram.');
      }
      return;
    }

    try {
      final devUri = Uri.parse('https://hinduconnect.app/$filePath');
      final devResponse = await http.get(devUri);
      if (!mounted) return;

      if (devResponse.statusCode != 200) {
        setState(() => _fileContent = 'Failed to load devanagari source.');
        return;
      }

      final devContent = devResponse.body;

      final converted = await _convertWithAksharamukha(
        devContent,
        source: 'devanagari',
        targetLangName: selectedLang,
      );
      if (!mounted) return;

      setState(() => _fileContent = converted ?? devContent);
    } catch (e) {
      if (!mounted) return;
      setState(() => _fileContent = 'Error: ${e.toString()}');
    }
  }

  Future<String?> _convertWithAksharamukha(String text,
      {required String source, required String targetLangName}) async {
    const api = 'http://aksharamukha-plugin.appspot.com/api/public';
    final targetScript =
        LanguageUtils.getAksharamukhaScriptCode(targetLangName);

    final response = await http.get(
      Uri.parse(
          '$api?source=$source&target=$targetScript&text=${Uri.encodeComponent(text)}'),
    );

    if (response.statusCode == 200) {
      return response.body;
    } else {
      debugPrint(
          'Aksharamukha Error: ${response.statusCode} - ${response.body}');
      return null;
    }
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fontSize = prefs.getDouble('${widget.filePath}_fontSize') ?? 18.0;
      _background =
          prefs.getString('${widget.filePath}_background') ?? 'default';
      _isFavorite = prefs.getBool('${widget.filePath}_favorite') ?? false;
      _isBookmarked = prefs.getBool('${widget.filePath}_bookmark') ?? false;
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('${widget.filePath}_fontSize', _fontSize);
    await prefs.setString('${widget.filePath}_background', _background);
    await prefs.setBool('${widget.filePath}_favorite', _isFavorite);
    await prefs.setBool('${widget.filePath}_bookmark', _isBookmarked);
  }

  void _changeFontSize(double change) {
    setState(() {
      _fontSize = (_fontSize + change).clamp(12.0, 32.0);
    });

    if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), _savePreferences);
  }

  void _resetFontSize() {
    setState(() => _fontSize = 18.0);
    _savePreferences();
  }

  void _switchBackground() {
    setState(() {
      final currentIndex = _backgrounds.indexOf(_background);
      final nextIndex = (currentIndex + 1) % _backgrounds.length;
      _background = _backgrounds[nextIndex];
    });
    _savePreferences();
  }

  void _toggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
    _savePreferences();
  }

  void _toggleBookmark() {
    setState(() => _isBookmarked = !_isBookmarked);
    _savePreferences();
  }

  void _shareDeepLink() {
    final link =
        'https://hinduconnect.app/viewer?file=${Uri.encodeComponent(widget.filePath)}';
    Share.share('Check out this stotram: $link');
  }

  void _reportIssue() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report submitted. Thank you!')),
    );
  }

  AssetImage _getBackgroundImage() {
    switch (_background) {
      case 'bg1':
        return const AssetImage('assets/images/bg1.jpg');
      case 'bg2':
        return const AssetImage('assets/images/bg2.jpg');
      default:
        return const AssetImage('assets/images/bg_default.jpg');
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileName = widget.filePath.split('/').last;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Viewer'),
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
            onPressed: _toggleFavorite,
          ),
          IconButton(
            icon: Icon(_isBookmarked ? Icons.bookmark : Icons.bookmark_border),
            onPressed: _toggleBookmark,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareDeepLink,
          ),
          IconButton(
            icon: const Icon(Icons.report),
            onPressed: _reportIssue,
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image(image: _getBackgroundImage(), fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.4)),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  fileName,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _fileContent,
                    style: TextStyle(fontSize: _fontSize, color: Colors.white),
                  ),
                ),
              ),
              Container(
                color: Colors.black54,
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon:
                          const Icon(Icons.text_decrease, color: Colors.white),
                      onPressed: () => _changeFontSize(-2),
                    ),
                    IconButton(
                      icon: const Icon(Icons.text_fields, color: Colors.white),
                      onPressed: _resetFontSize,
                    ),
                    IconButton(
                      icon:
                          const Icon(Icons.text_increase, color: Colors.white),
                      onPressed: () => _changeFontSize(2),
                    ),
                    IconButton(
                      icon: const Icon(Icons.wallpaper, color: Colors.white),
                      onPressed: _switchBackground,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
