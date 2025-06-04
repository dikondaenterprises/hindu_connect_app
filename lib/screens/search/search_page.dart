import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/top_bar.dart';
import '../../widgets/bottom_nav.dart';
import '../../services/local_search_service.dart';
import '../../utils/language_utils.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, required String langCode});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _ctrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;

  Future<void> _onSearch(String q) async {
    if (q.isEmpty) {
      setState(() => _results = []);
      return;
    }

    setState(() => _loading = true);

    final prefs = await SharedPreferences.getInstance(); // ✅ Corrected
    final contentLang = (prefs.getString('lang') ?? 'English');
    final langCode = LanguageUtils.getScriptCode(contentLang);

    // First try local search
    final local = await LocalSearchService.instance.search(q, langCode);
    if (local.isNotEmpty) {
      setState(() {
        _results = local;
        _loading = false;
      });
      return;
    }

    // Check if selected language is in first category
    final useDirectAccess =
        LanguageUtils.directAccessLanguages.contains(langCode);

    if (useDirectAccess) {
      // Search for files in the selected language folder
      final snap = await FirebaseFirestore.instance
          .collection('stotras')
          .where('lang', isEqualTo: langCode.toLowerCase())
          .orderBy('file')
          .startAt([q])
          .endAt(['$q\uf8ff'])
          .limit(50)
          .get();

      setState(() {
        _results = snap.docs
            .map((d) => {
                  'id': d.id,
                  'title': d['file'],
                  'path': 'stotras/${langCode.toLowerCase()}/${d['file']}.txt',
                  'needsTransliteration': false
                })
            .toList();
        _loading = false;
      });
    } else {
      // Search devanagari files (will be transliterated later)
      final snap = await FirebaseFirestore.instance
          .collection('stotras')
          .where('lang', isEqualTo: 'devanagari')
          .orderBy('file')
          .startAt([q])
          .endAt(['$q\uf8ff'])
          .limit(50)
          .get();

      setState(() {
        _results = snap.docs
            .map((d) => {
                  'id': d.id,
                  'title': d['file'],
                  'path': 'stotras/devanagari/${d['file']}.txt',
                  'needsTransliteration': true
                })
            .toList();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopBar(title: 'Search'),
      bottomNavigationBar: const BottomNav(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _ctrl,
              decoration: const InputDecoration(
                  hintText: 'Search Stotras...',
                  prefixIcon: Icon(Icons.search)),
              onSubmitted: _onSearch,
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          Expanded(
            child: ListView.builder(
              itemCount: _results.length,
              itemBuilder: (_, i) {
                final r = _results[i];
                return ListTile(
                  title: Text(r['title'] as String),
                  subtitle: r['snippet'] != null
                      ? Text(r['snippet'] as String)
                      : null,
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/viewer',
                    arguments: {
                      'filePath': r['path'],
                      'needsTransliteration': r['needsTransliteration']
                    },
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}
