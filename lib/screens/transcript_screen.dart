import 'package:flutter/material.dart';

import '../utils/helpers.dart';
import '../widgets/student_bottom_nav.dart';

class TranscriptScreen extends StatefulWidget {
  const TranscriptScreen({
    super.key,
    required this.nilai,
    required this.kelasAktif,
  });

  final List<Map<String, dynamic>> nilai;
  final String kelasAktif;

  @override
  State<TranscriptScreen> createState() => _TranscriptScreenState();
}

class _TranscriptScreenState extends State<TranscriptScreen> {
  late String _kelas;
  late String _kelasAktif;
  int _semester = 1;

  @override
  void initState() {
    super.initState();
    _kelasAktif = _normalizeKelas(widget.kelasAktif);
    _kelas = _kelasAktif;
  }

  @override
  Widget build(BuildContext context) {
    final rows = widget.nilai
        .where((e) =>
            toInt(e['semester']) == _semester &&
            _normalizeKelas(e['kelas']?.toString() ?? '') == _kelas)
        .toList()
      ..sort((a, b) =>
          (a['mapel'] ?? '').toString().compareTo((b['mapel'] ?? '').toString()));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: const [
                  Text(
                    'Transkrip Nilai',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Spacer(),
                  Icon(Icons.notifications_none, color: Color(0xFF64748B)),
                ],
              ),
            ),
            const SizedBox(height: 6),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _FilterCard(
                title: 'Pilih Kelas',
                child: DropdownButtonFormField<String>(
                  value: _kelas,
                  items: const [
                    DropdownMenuItem(value: 'Kelas 1', child: Text('Kelas 1')),
                    DropdownMenuItem(value: 'Kelas 2', child: Text('Kelas 2')),
                    DropdownMenuItem(value: 'Kelas 3', child: Text('Kelas 3')),
                    DropdownMenuItem(value: 'Kelas 4', child: Text('Kelas 4')),
                    DropdownMenuItem(value: 'Kelas 5', child: Text('Kelas 5')),
                    DropdownMenuItem(value: 'Kelas 6', child: Text('Kelas 6')),
                  ],
                  onChanged: (value) => setState(() => _kelas = value ?? _kelas),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _FilterCard(
                title: 'Pilih Semester',
                child: DropdownButtonFormField<int>(
                  value: _semester,
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Semester 1 (Ganjil)')),
                    DropdownMenuItem(value: 2, child: Text('Semester 2 (Genap)')),
                  ],
                  onChanged: (value) => setState(() => _semester = value ?? 1),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: rows.isEmpty
                  ? const Center(
                      child: Text(
                        'Tidak ada data nilai untuk kelas/semester ini.',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      itemCount: rows.length,
                      itemBuilder: (context, index) {
                        final row = rows[index];
                        final nilaiAkhir = toDouble(row['nilai_akhir']);
                        final mapel = row['mapel']?.toString() ?? '-';
                        final grade = _gradeFromScore(nilaiAkhir);
                        final gradeColor = _gradeColor(grade);
                        return Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x11000000),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      mapel,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      '-',
                                      style: TextStyle(
                                          fontSize: 12, color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                nilaiAkhir == null ? '-' : nilaiAkhir.toStringAsFixed(0),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: gradeColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  grade,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            StudentBottomNav(
              activeIndex: 1,
              nilai: widget.nilai,
              kelasAktif: _kelasAktif,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterCard extends StatelessWidget {
  const _FilterCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

String _normalizeKelas(String raw) {
  if (raw.isEmpty) return 'Kelas 1';
  final lower = raw.toLowerCase();
  final match = RegExp(r'\d+').firstMatch(lower);
  if (match != null) {
    return 'Kelas ${match.group(0)}';
  }
  if (lower.contains('kelas')) {
    return 'Kelas 1';
  }
  return 'Kelas 1';
}



String _gradeFromScore(double? score) {
  if (score == null) return '-';
  if (score >= 90) return 'A';
  if (score >= 80) return 'B+';
  if (score >= 70) return 'B';
  if (score >= 60) return 'C';
  return 'D';
}

Color _gradeColor(String grade) {
  switch (grade) {
    case 'A':
      return const Color(0xFF22C55E);
    case 'B+':
      return const Color(0xFF14B8A6);
    case 'B':
      return const Color(0xFF3B82F6);
    case 'C':
      return const Color(0xFFF59E0B);
    case 'D':
      return const Color(0xFFEF4444);
    default:
      return const Color(0xFF94A3B8);
  }
}
