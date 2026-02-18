import 'dart:convert';

import 'package:http/http.dart' as http;

const String apiBaseUrl = 'https://project-skripsi-production-a25e.up.railway.app';

class ApiClient {
  ApiClient(this.baseUrl);

  final String baseUrl;

  Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/api/mobile/login');
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (res.statusCode != 200) {
      final msg = _extractMessage(res.body) ?? 'Login gagal.';
      throw Exception(msg);
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getMe(String token) async {
    final url = Uri.parse('$baseUrl/api/mobile/me');
    final res = await http.get(url, headers: _authHeaders(token));
    if (res.statusCode != 200) {
      throw Exception('Gagal mengambil profil.');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getRekomendasi(String token) async {
    final url = Uri.parse('$baseUrl/api/mobile/rekomendasi');
    final res = await http.get(url, headers: _authHeaders(token));
    if (res.statusCode != 200) {
      throw Exception('Gagal mengambil rekomendasi.');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getNilai(String token, {int? semester}) async {
    final uri = semester == null
        ? Uri.parse('$baseUrl/api/mobile/nilai')
        : Uri.parse('$baseUrl/api/mobile/nilai?semester=$semester');
    final res = await http.get(uri, headers: _authHeaders(token));
    if (res.statusCode != 200) {
      throw Exception('Gagal mengambil nilai.');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<http.Response> downloadRekomendasiPdf(String token, {int? semester}) async {
    final uri = semester == null
        ? Uri.parse('$baseUrl/api/mobile/rekomendasi/pdf')
        : Uri.parse('$baseUrl/api/mobile/rekomendasi/pdf?semester=$semester');
    final res = await http.get(uri, headers: _authHeaders(token));
    return res;
  }

  Future<Map<String, dynamic>> getDokumen(String token) async {
    final url = Uri.parse('$baseUrl/api/mobile/dokumen');
    final res = await http.get(url, headers: _authHeaders(token));
    if (res.statusCode != 200) {
      throw Exception('Gagal mengambil dokumen.');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> uploadDokumen(
    String token, {
    required String jenisDokumen,
    required String filePath,
    required String fileName,
  }) async {
    final url = Uri.parse('$baseUrl/api/mobile/dokumen');
    final req = http.MultipartRequest('POST', url)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['jenis_dokumen'] = jenisDokumen
      ..files.add(await http.MultipartFile.fromPath('file', filePath, filename: fileName));

    final streamed = await req.send();
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode != 201) {
      final msg = _extractMessage(body) ?? 'Gagal mengupload dokumen.';
      throw Exception(msg);
    }
    return jsonDecode(body) as Map<String, dynamic>;
  }

  Future<void> deleteDokumen(String token, int id) async {
    final url = Uri.parse('$baseUrl/api/mobile/dokumen/$id');
    final res = await http.delete(url, headers: _authHeaders(token));
    if (res.statusCode != 200) {
      throw Exception('Gagal menghapus dokumen.');
    }
  }

  Map<String, String> _authHeaders(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  String? _extractMessage(String body) {
    try {
      final data = jsonDecode(body);
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
    } catch (_) {}
    return null;
  }
}
