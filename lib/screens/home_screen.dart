import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/auth_storage.dart';
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
  Map<String, dynamic>? _me;
  Map<String, dynamic>? _rekomendasi;
  List<Map<String, dynamic>> _nilai = [];
  double? _avgSemesterLalu;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ApiClient(apiBaseUrl);
      final me = await api.getMe(widget.token);
      final nilaiRes = await api.getNilai(widget.token);
      final rekomRes = await api.getRekomendasi(widget.token);
      final rows = (nilaiRes['nilai'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final avg = _computeAverageSemesterTerakhir(rows);
      setState(() {
        _me = me;
        _nilai = rows;
        _rekomendasi = rekomRes['rekomendasi'] as Map<String, dynamic>?;
        _avgSemesterLalu = avg;
      });
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await AuthStorage().clear();
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
      body: _loading
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
