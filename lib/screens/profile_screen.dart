import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/auth_storage.dart';
import '../widgets/student_bottom_nav.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _me;
  List<Map<String, dynamic>> _nilai = [];
  String _kelasAktif = '-';
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
      final token = await AuthStorage().getToken();
      if (token == null) {
        setState(() => _error = 'Token tidak ditemukan. Silakan login ulang.');
        return;
      }
      final api = ApiClient(apiBaseUrl);
      final me = await api.getMe(token);
      final nilaiRes = await api.getNilai(token);
      final rows = (nilaiRes['nilai'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final siswa = me['siswa'] as Map<String, dynamic>?;
      setState(() {
        _me = me;
        _nilai = rows;
        _kelasAktif = siswa?['kelas']?.toString() ?? '-';
      });
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

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
                    'Profil',
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
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!))
                      : _ProfileBody(
                          me: _me,
                          onLogout: _logout,
                        ),
            ),
            StudentBottomNav(
              activeIndex: 3,
              nilai: _nilai,
              kelasAktif: _kelasAktif,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    await AuthStorage().clear();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.me, required this.onLogout});

  final Map<String, dynamic>? me;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final user = me?['user'] as Map<String, dynamic>?;
    final siswa = me?['siswa'] as Map<String, dynamic>?;
    final nama = siswa?['nama_siswa']?.toString() ?? '-';
    final kelas = siswa?['kelas']?.toString() ?? '-';
    final nipd = siswa?['nipd']?.toString() ?? '-';
    final nisn = siswa?['nisn']?.toString() ?? '-';
    final rombel = siswa?['rombel_saat_ini']?.toString() ?? '-';
    final username = user?['username']?.toString() ?? '-';
    final role = user?['role']?.toString() ?? '-';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _ProfileHeader(
          nama: nama,
          kelas: kelas,
          rombel: rombel,
        ),
        const SizedBox(height: 12),
        _QuickStats(
          leftLabel: 'NIPD',
          leftValue: nipd,
          rightLabel: 'NISN',
          rightValue: nisn,
        ),
        const SizedBox(height: 12),
        _InfoCard(
          title: 'Data Siswa',
          items: [
            _InfoItem('NIPD', nipd),
            _InfoItem('NISN', nisn),
            _InfoItem('Rombel Saat Ini', rombel),
          ],
        ),
        const SizedBox(height: 12),
        _InfoCard(
          title: 'Akun',
          items: [
            _InfoItem('Username', username),
            _InfoItem('Role', role),
          ],
        ),
        const SizedBox(height: 12),
        _InfoCard(
          title: 'Pengaturan',
          items: const [
            _InfoItem('Notifikasi', 'Aktif'),
            _InfoItem('Bahasa', 'Indonesia'),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 46,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => _confirmLogout(context, onLogout),
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text(
              'Logout',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

Future<void> _confirmLogout(BuildContext context, VoidCallback onLogout) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Konfirmasi Logout'),
      content: const Text('Anda yakin ingin keluar dari akun ini?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Logout'),
        ),
      ],
    ),
  );
  if (ok == true) {
    onLogout();
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.nama,
    required this.kelas,
    required this.rombel,
  });

  final String nama;
  final String kelas;
  final String rombel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF60A5FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: Color(0xFF2563EB)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nama,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kelas $kelas',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rombel: $rombel',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Aktif',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStats extends StatelessWidget {
  const _QuickStats({
    required this.leftLabel,
    required this.leftValue,
    required this.rightLabel,
    required this.rightValue,
  });

  final String leftLabel;
  final String leftValue;
  final String rightLabel;
  final String rightValue;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(label: leftLabel, value: leftValue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(label: rightLabel, value: rightValue),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.items});

  final String title;
  final List<_InfoItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.label,
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                  ),
                  Text(
                    item.value,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem {
  const _InfoItem(this.label, this.value);

  final String label;
  final String value;
}
