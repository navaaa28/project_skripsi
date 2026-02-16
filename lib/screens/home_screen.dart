import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/auth_storage.dart';
import '../services/local_cache.dart';
import '../utils/helpers.dart';
import 'login_screen.dart';
import 'student_dashboard.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.token});

  final String token;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _cache = LocalCache();

  Map<String, dynamic>? _me;
  Map<String, dynamic>? _rekomendasi;
  List<Map<String, dynamic>> _nilai = [];
  double? _avgSemesterLalu;
  String? _error;
  bool _loading = true;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _isOffline = false;
    });
    try {
      // Try fetching from API
      final api = ApiClient(apiBaseUrl);
      final me = await api.getMe(widget.token);
      final nilaiRes = await api.getNilai(widget.token);
      final rekomRes = await api.getRekomendasi(widget.token);
      final rows = (nilaiRes['nilai'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final avg = _computeAverageSemesterTerakhir(rows);

      // Save to local cache for offline use
      await _cache.save('me', me);
      await _cache.save('nilai', nilaiRes);
      await _cache.save('rekomendasi', rekomRes);

      setState(() {
        _me = me;
        _nilai = rows;
        _rekomendasi = rekomRes['rekomendasi'] as Map<String, dynamic>?;
        _avgSemesterLalu = avg;
      });
    } catch (e) {
      // API failed — try loading from cache
      final cachedMe = await _cache.load('me');
      final cachedNilai = await _cache.load('nilai');
      final cachedRekom = await _cache.load('rekomendasi');

      if (cachedMe != null) {
        final rows = (cachedNilai?['nilai'] as List?)
                ?.cast<Map<String, dynamic>>() ??
            [];
        final avg = _computeAverageSemesterTerakhir(rows);
        setState(() {
          _me = cachedMe;
          _nilai = rows;
          _rekomendasi =
              cachedRekom?['rekomendasi'] as Map<String, dynamic>?;
          _avgSemesterLalu = avg;
          _isOffline = true;
        });
      } else {
        // No cache available either
        setState(
            () => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await AuthStorage().clear();
    await _cache.clear();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final siswa = _me?['siswa'] as Map<String, dynamic>?;
    return Scaffold(
      appBar: AppBar(
        title: const Text('SMART CICADAS'),
        actions: const [],
      ),
      body: Column(
        children: [
          if (_isOffline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              color: const Color(0xFFFEF3C7),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off, size: 14, color: Color(0xFF92400E)),
                  SizedBox(width: 6),
                  Text(
                    'Mode Offline — menampilkan data tersimpan',
                    style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : StudentDashboardScreen(
                        namaSiswa: siswa?['nama_siswa'] ?? '-',
                        rataRata: _avgSemesterLalu,
                        nilai: _nilai,
                        kelasAktif: siswa?['kelas'] ?? '-',
                        rekomendasi: _rekomendasi,
                        onRefresh: _load,
                      ),
          ),
        ],
      ),
    );
  }
}

double? _computeAverageSemesterTerakhir(List<Map<String, dynamic>> rows) {
  if (rows.isEmpty) return null;
  final semesters = rows
      .map((e) => toInt(e['semester']))
      .whereType<int>()
      .toSet()
      .toList()
    ..sort();
  if (semesters.isEmpty) return null;
  final last = semesters.last;
  final nilaiAkhir = rows
      .where((e) => toInt(e['semester']) == last)
      .map((e) => toDouble(e['nilai_akhir']))
      .whereType<double>()
      .toList();
  if (nilaiAkhir.isEmpty) return null;
  final sum = nilaiAkhir.fold<double>(0, (a, b) => a + b);
  return sum / nilaiAkhir.length;
}
