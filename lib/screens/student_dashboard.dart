import 'package:flutter/material.dart';

import 'graph_screen.dart';
import 'info_sekolah_screen.dart';
import 'transcript_screen.dart';
import '../widgets/student_bottom_nav.dart';
import 'minat_bakat_screen.dart';
class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen({
    super.key,
    required this.namaSiswa,
    required this.rataRata,
    required this.nilai,
    required this.kelasAktif,
    required this.rekomendasi,
    this.onRefresh,
  });

  final String namaSiswa;
  final double? rataRata;
  final List<Map<String, dynamic>> nilai;
  final String kelasAktif;
  final Map<String, dynamic>? rekomendasi;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
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
                    'Dashboard Siswa',
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
            Expanded(
              child: RefreshIndicator(
                onRefresh: onRefresh ?? () async {},
                child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  _GreetingCard(namaSiswa: namaSiswa),
                  const SizedBox(height: 16),
                  _AverageCard(rataRata: rataRata),
                  const SizedBox(height: 18),
                  _MenuRow(
                    children: [
                      _MenuTile(
                        icon: Icons.assignment_outlined,
                        label: 'Lihat Nilai\n(Transkrip)',
                        color: Color(0xFF3B82F6),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => TranscriptScreen(
                                nilai: nilai,
                                kelasAktif: kelasAktif,
                              ),
                            ),
                          );
                        },
                      ),
                      _MenuTile(
                        icon: Icons.show_chart,
                        label: 'Grafik\nPerkembangan',
                        color: Color(0xFF22C55E),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => GraphScreen(
                                nilai: nilai,
                                kelasAktif: kelasAktif,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _MenuRow(
                    children: [
                      _MenuTile(
                        icon: Icons.emoji_objects_outlined,
                        label: 'Minat &\nBakat AI',
                        color: Color(0xFFF59E0B),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => MinatBakatScreen(
                                rekomendasi: rekomendasi,
                                namaSiswa: namaSiswa,
                              ),
                            ),
                          );
                        },
                      ),
                      _MenuTile(
                        icon: Icons.info_outline,
                        label: 'Info\nSekolah',
                        color: Color(0xFF6366F1),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const InfoSekolahScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              ),
            ),
            StudentBottomNav(
              activeIndex: 0,
              nilai: nilai,
              kelasAktif: kelasAktif,
            ),
          ],
        ),
      ),
    );
  }
}

class _GreetingCard extends StatelessWidget {
  const _GreetingCard({required this.namaSiswa});

  final String namaSiswa;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white,
            child: Icon(Icons.school, color: Color(0xFF2563EB)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Halo, $namaSiswa!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AverageCard extends StatelessWidget {
  const _AverageCard({required this.rataRata});

  final double? rataRata;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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
      child: Column(
        children: [
          Text(
            rataRata == null ? '-' : rataRata!.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Rata-rata Nilai Semester Lalu',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: children
          .map((child) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: child,
                ),
              ))
          .toList(),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withOpacity(0.4)),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
