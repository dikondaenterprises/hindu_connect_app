import 'dart:convert';
import 'package:http/http.dart' as http;

class ConvertApi {
  static Future<String> convert(String src, String tgt, String text) async {
    final url = Uri.parse(
        'https://us-central1-YOUR_PROJECT.cloudfunctions.net/api/convert');
    final res = await http.post(url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(
            {'sourceScript': src, 'targetScript': tgt, 'text': text}));
    if (res.statusCode != 200) throw 'Convert failed';
    return jsonDecode(res.body)['converted'] as String;
  }
}
