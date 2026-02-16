import 'package:flutter/material.dart';

import '../screens/graph_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/transcript_screen.dart';

class StudentBottomNav extends StatelessWidget {
  const StudentBottomNav({
    super.key,
    required this.activeIndex,
    required this.nilai,
    required this.kelasAktif,
  });

  final int activeIndex;
  final List<Map<String, dynamic>> nilai;
  final String kelasAktif;

  void _goHome(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _goNilai(BuildContext context) {
    if (activeIndex == 1) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TranscriptScreen(
          nilai: nilai,
          kelasAktif: kelasAktif,
        ),
      ),
    );
  }

  void _goGrafik(BuildContext context) {
    if (activeIndex == 2) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GraphScreen(
          nilai: nilai,
          kelasAktif: kelasAktif,
        ),
      ),
    );
  }

  void _goProfil(BuildContext context) {
    if (activeIndex == 3) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ProfileScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavItem(
            icon: Icons.home,
            label: 'Home',
            active: activeIndex == 0,
            onTap: () => _goHome(context),
          ),
          _NavItem(
            icon: Icons.assignment,
            label: 'Nilai',
            active: activeIndex == 1,
            onTap: () => _goNilai(context),
          ),
          _NavItem(
            icon: Icons.show_chart,
            label: 'Grafik',
            active: activeIndex == 2,
            onTap: () => _goGrafik(context),
          ),
          _NavItem(
            icon: Icons.person,
            label: 'Profil',
            active: activeIndex == 3,
            onTap: () => _goProfil(context),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF2563EB) : const Color(0xFF64748B);
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: color),
          ),
        ],
      ),
    );
  }
}
