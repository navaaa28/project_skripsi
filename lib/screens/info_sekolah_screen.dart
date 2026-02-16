import 'package:flutter/material.dart';

class InfoSekolahScreen extends StatelessWidget {
  const InfoSekolahScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Info Sekolah',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _HeaderCard(),
            const SizedBox(height: 12),
            _InfoCard(
              title: 'Informasi Umum',
              items: const [
                _Item(Icons.school, 'Nama Sekolah', 'SDN CICADAS'),
                _Item(Icons.pin_drop, 'Alamat', 'Jl. Cicadas, Bandung'),
                _Item(Icons.phone, 'Telepon', '(022) xxxxxxx'),
                _Item(Icons.email, 'Email', 'sdn.cicadas@email.com'),
              ],
            ),
            const SizedBox(height: 12),
            _InfoCard(
              title: 'Visi',
              description:
                  'Menjadi sekolah dasar yang unggul dalam prestasi akademik dan non-akademik, '
                  'berbasis teknologi, serta membentuk karakter siswa yang berakhlak mulia.',
            ),
            const SizedBox(height: 12),
            _InfoCard(
              title: 'Misi',
              bulletPoints: const [
                'Menyelenggarakan pendidikan berkualitas berbasis kurikulum nasional.',
                'Mengembangkan potensi minat dan bakat siswa melalui kegiatan ekstrakurikuler.',
                'Memanfaatkan teknologi informasi untuk mendukung proses pembelajaran.',
                'Membentuk lingkungan sekolah yang aman, nyaman, dan kondusif.',
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white,
            child: Icon(Icons.account_balance, color: Color(0xFF6366F1)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'SDN CICADAS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Sekolah Dasar Negeri',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    this.items,
    this.description,
    this.bulletPoints,
  });

  final String title;
  final List<_Item>? items;
  final String? description;
  final List<String>? bulletPoints;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          if (description != null)
            Text(
              description!,
              style: const TextStyle(color: Color(0xFF475569), height: 1.5),
            ),
          if (items != null)
            ...items!.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(item.icon, size: 16, color: const Color(0xFF6366F1)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.label,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                          Text(
                            item.value,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (bulletPoints != null)
            ...bulletPoints!.map(
              (point) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Icon(Icons.circle, size: 6, color: Color(0xFF6366F1)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        point,
                        style: const TextStyle(color: Color(0xFF475569), height: 1.5),
                      ),
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

class _Item {
  const _Item(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;
}
