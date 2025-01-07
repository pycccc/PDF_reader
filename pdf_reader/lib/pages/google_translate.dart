import 'dart:convert';
import 'package:http/http.dart' as http;

class GoogleTranslateService {
  final String apiKey; // Google Translate API 金鑰

  GoogleTranslateService(this.apiKey);

  /// 調用 Google Translate API 翻譯文字
  Future<String> translate(String text, String targetLanguage) async {
    final String url =
        'https://translation.googleapis.com/language/translate/v2?key=$apiKey';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'q': text, // 要翻譯的文字
          'target': targetLanguage, // 目標語言代碼，例如 'zh' 為中文
          'format': 'text',
          'key': apiKey,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final translatedText =
            jsonResponse['data']['translations'][0]['translatedText'];
        return translatedText;
      } else {
        print('翻譯失敗: ${response.body}');
        return '翻譯失敗';
      }
    } catch (e) {
      print('發生錯誤: $e');
      return '翻譯錯誤';
    }
  }
}
