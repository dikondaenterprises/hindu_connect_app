class LanguageUtils {
  // All 51 languages with display names and script codes (order preserved from Excel)
  static final List<Map<String, String>> allLanguages = [
    {'name': 'Arabic', 'code': 'Arab'},
    {'name': 'Assamese', 'code': 'Assamese'},
    {'name': 'Avestan', 'code': 'Avestan'},
    {'name': 'Bengali (Bangla)', 'code': 'Bengali'},
    {'name': 'Bhaiksuki', 'code': 'Bhaiksuki'},
    {'name': 'Brahmi', 'code': 'Brahmi'},
    {'name': 'Burmese (Myanmar)', 'code': 'Burmese'},
    {'name': 'Cyrillic (Russian)', 'code': 'RussianCyrillic'},
    {'name': 'English', 'code': 'Itrans'},
    {'name': 'Grantha', 'code': 'Grantha'},
    {'name': 'Gujarati', 'code': 'Gujarati'},
    {'name': 'Hebrew', 'code': 'Hebrew'},
    {'name': 'Hebrew (Judeo-Arabic)', 'code': 'Hebr-Ar'},
    {'name': 'Hindi', 'code': 'Devanagari'},
    {'name': 'Imperial Aramaic', 'code': 'Armi'},
    {'name': 'Japanese (Hiragana)', 'code': 'Hiragana'},
    {'name': 'Japanese (Katakana)', 'code': 'Katakana'},
    {'name': 'Javanese', 'code': 'Javanese'},
    {'name': 'Kannada', 'code': 'Kannada'},
    {'name': 'Kharoshthi', 'code': 'Kharoshthi'},
    {'name': 'Khmer (Cambodian)', 'code': 'Khmer'},
    {'name': 'Lao', 'code': 'Lao'},
    {'name': 'Malayalam', 'code': 'Malayalam'},
    {'name': 'Meetei Mayek (Manipuri)', 'code': 'MeeteiMayek'},
    {'name': 'Mongolian', 'code': 'Mongolian'},
    {'name': 'Newa (Nepal Bhasa)', 'code': 'Newa'},
    {'name': 'Old Persian', 'code': 'OldPersian'},
    {'name': 'Old South Arabian', 'code': 'Sarb'},
    {'name': 'Oriya (Odia)', 'code': 'Oriya'},
    {'name': 'Persian', 'code': 'Arab-Fa'},
    {'name': 'Phoenician', 'code': 'Phnx'},
    {'name': 'Psalter Pahlavi', 'code': 'Phlp'},
    {'name': 'Punjabi (Gurmukhi)', 'code': 'Gurmukhi'},
    {'name': 'Ranjana (Lantsa)', 'code': 'Ranjana'},
    {'name': 'Samaritan', 'code': 'Samr'},
    {'name': 'Santali (Ol Chiki)', 'code': 'Santali'},
    {'name': 'Sharada', 'code': 'Sharada'},
    {'name': 'Siddham', 'code': 'Siddham'},
    {'name': 'Sinhala', 'code': 'Sinhala'},
    {'name': 'Sogdian', 'code': 'Sogd'},
    {'name': 'Soyombo', 'code': 'Soyombo'},
    {'name': 'Syriac (Eastern)', 'code': 'Syrn'},
    {'name': 'Syriac (Estrangela)', 'code': 'Syre'},
    {'name': 'Syriac (Western)', 'code': 'Syrj'},
    {'name': 'Tamil', 'code': 'Tamil'},
    {'name': 'Tamil Brahmi', 'code': 'TamilBrahmi'},
    {'name': 'Telugu', 'code': 'Telugu'},
    {'name': 'Thaana (Dhivehi)', 'code': 'Thaana'},
    {'name': 'Thai', 'code': 'Thai'},
    {'name': 'Tibetan', 'code': 'Tibetan'},
    {'name': 'Urdu', 'code': 'Urdu'},
  ];

  // Languages with direct file access (6 folders)
  static final List<String> directAccessLanguages = [
    'Devanagari',
    'Telugu',
    'Itrans',
    'Tamil',
    'Kannada',
    'Malayalam'
  ];

  // Convert user-friendly name to Aksharamukha's script code (e.g., "Cyrillic (Russian)" → "RussianCyrillic")
  static String getAksharamukhaScriptCode(String langName) {
    // Handle special cases (Hindi/Sanskrit → Devanagari)
    final specialCases = {
      'hindi': 'Devanagari',
      'sanskrit': 'Devanagari',
      'marathi': 'Devanagari',
      'nepali': 'Devanagari',
    };

    if (specialCases.containsKey(langName.toLowerCase())) {
      return specialCases[langName.toLowerCase()]!;
    }

    // Lookup in main language list
    for (var lang in allLanguages) {
      if (lang['name']!.toLowerCase() == langName.toLowerCase()) {
        return lang[
            'code']!; // Returns the exact script identifier (e.g., "RussianCyrillic")
      }
    }

    return 'Itrans'; // Default fallback
  }

  // For UI display (e.g., profile page dropdown)
  static List<Map<String, String>> searchLanguages(String query) {
    if (query.isEmpty) return allLanguages;
    return allLanguages
        .where(
            (lang) => lang['name']!.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  static getScriptCode(contentLang) {}
}
