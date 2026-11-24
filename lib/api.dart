import 'dart:convert';
import 'package:http/http.dart' as http;

class Api {
  // Domain bawaan / cadangan — dipakai kalau gagal ambil dari GitHub
  static const String _defaultBaseUrl = "http://alya-market2.smasnug.web.id:2310";
  
  // 👇 Ganti link ini pakai link RAW config.json kamu nanti
  static const String _configUrl = "https://https://raw.githubusercontent.com/gajelas0196-lgtm/Zijii/main/OneCrash/config.json";
  
  static String? _cachedBaseUrl;
  
  static String get baseUrl => _cachedBaseUrl ?? _defaultBaseUrl;

  /// Panggil ini sekali saat aplikasi mulai jalan
  static Future<void> loadConfig() async {
    try {
      final res = await http.get(Uri.parse(_configUrl)).timeout(
        const Duration(seconds: 8),
      );
      
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final newUrl = data['api_base_url'] as String?;
        if (newUrl != null && newUrl.isNotEmpty) {
          _cachedBaseUrl = newUrl;
          print("✅ Domain terbaru dimuat: $_cachedBaseUrl");
          return;
        }
      }
      print("⚠️ Pakai domain bawaan");
    } catch (e) {
      print("⚠️ Gagal ambil config: $e — pakai domain bawaan");
    }
    _cachedBaseUrl = _defaultBaseUrl;
  }
}
