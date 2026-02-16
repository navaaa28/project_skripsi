import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../services/api_client.dart';
import '../services/auth_storage.dart';
import '../utils/helpers.dart';

class MinatBakatScreen extends StatelessWidget {
  const MinatBakatScreen({
    super.key,
    required this.rekomendasi,
    required this.namaSiswa,
  });

  final Map<String, dynamic>? rekomendasi;
  final String namaSiswa;

  @override
  Widget build(BuildContext context) {
    final minatList = toList(rekomendasi?['minat']);
    final bakatList = toList(rekomendasi?['bakat']);
    final analisis = rekomendasi?['analisis_tren']?.toString();
    final ringkasanNon = rekomendasi?['ringkasan_non_akademik']?.toString();
    final saran = rekomendasi?['saran_pengembangan']?.toString();
    final tanggal = rekomendasi?['tgl_analisis']?.toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Minat & Bakat',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const Spacer(),
                  if (tanggal != null)
                    Text(
                      tanggal!,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // --- Minat ---
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionTitle(
                          icon: Icons.star_rounded,
                          title: 'Minat (Top 3)',
                          color: Color(0xFF2563EB),
                        ),
                        const SizedBox(height: 12),
                        _ProgressList(items: minatList, tint: const Color(0xFF2563EB)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // --- Bakat ---
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionTitle(
                          icon: Icons.emoji_events_rounded,
                          title: 'Bakat (Top 3)',
                          color: Color(0xFFF59E0B),
                        ),
                        const SizedBox(height: 12),
                        _ProgressList(items: bakatList, tint: const Color(0xFFF59E0B)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // --- Ringkasan Akademik ---
                  _ParagraphCard(
                    icon: Icons.trending_up_rounded,
                    title: 'Ringkasan Akademik',
                    color: const Color(0xFF16A34A),
                    text: analisis,
                  ),
                  const SizedBox(height: 12),

                  // --- Ringkasan Non-Akademik ---
                  _ParagraphCard(
                    icon: Icons.groups_rounded,
                    title: 'Ringkasan Non-Akademik',
                    color: const Color(0xFF7C3AED),
                    text: ringkasanNon,
                  ),
                  const SizedBox(height: 12),

                  // --- Saran Pengembangan ---
                  _ParagraphCard(
                    icon: Icons.lightbulb_rounded,
                    title: 'Saran Pengembangan',
                    color: const Color(0xFF0EA5E9),
                    text: saran,
                  ),
                  const SizedBox(height: 20),

                  // --- Download button ---
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _downloadPdf(context, rekomendasi, namaSiswa),
                      icon: const Icon(Icons.download_rounded, color: Colors.white, size: 20),
                      label: const Text(
                        'Unduh Laporan (PDF)',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

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
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.color,
  });

  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _ProgressList extends StatelessWidget {
  const _ProgressList({required this.items, required this.tint});

  final List<Map<String, dynamic>> items;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Text('Belum ada data', style: TextStyle(color: Color(0xFF94A3B8)));
    }
    return Column(
      children: items.map((item) {
        final label = item['nama']?.toString() ?? '-';
        final pct = toDouble(item['persentase']) ?? 0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                  Text(
                    '${pct.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: tint,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct / 100,
                  minHeight: 6,
                  backgroundColor: tint.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(tint),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ParagraphCard extends StatelessWidget {
  const _ParagraphCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final String title;
  final Color color;
  final String? text;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle(icon: icon, title: title, color: color),
                    const SizedBox(height: 10),
                    ..._buildBulletPoints(text, color),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<Widget> _buildBulletPoints(String? text, Color dotColor) {
  if (text == null || text.trim().isEmpty) {
    return [const Text('-', style: TextStyle(color: Color(0xFF94A3B8)))];
  }

  // Split by ". " to create bullet points from sentences
  final sentences = text
      .split(RegExp(r'\.\s+'))
      .map((s) => s.replaceAll(RegExp(r'\.$'), '').trim())
      .where((s) => s.isNotEmpty)
      .toList();

  if (sentences.isEmpty) {
    return [Text(text, style: const TextStyle(color: Color(0xFF475569), fontSize: 13, height: 1.5))];
  }

  return sentences.map((sentence) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: dotColor.withOpacity(0.7),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$sentence.',
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }).toList();
}

Future<void> _downloadPdf(
  BuildContext context,
  Map<String, dynamic>? rekomendasi,
  String namaSiswa,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final token = await AuthStorage().getToken();
  if (token == null) {
    messenger.showSnackBar(const SnackBar(content: Text('Token tidak ditemukan. Silakan login ulang.')));
    return;
  }

  final semester = _toIntFromRek(rekomendasi);
  final api = ApiClient(apiBaseUrl);
  final res = await api.downloadRekomendasiPdf(token, semester: semester);
  if (res.statusCode != 200) {
    messenger.showSnackBar(const SnackBar(content: Text('Gagal mengunduh PDF.')));
    return;
  }

  Directory? dir;
  try {
    dir = await getTemporaryDirectory();
  } catch (_) {
    try {
      dir = await getApplicationDocumentsDirectory();
    } catch (e) {
      messenger.showSnackBar(const SnackBar(content: Text('Path penyimpanan belum siap. Coba restart aplikasi.')));
      return;
    }
  }

  final filename = _filenameFromRek(namaSiswa, semester ?? 1);
  final file = File('${dir.path}/$filename');
  await file.writeAsBytes(res.bodyBytes);
  await OpenFilex.open(file.path);
}

int? _toIntFromRek(Map<String, dynamic>? rek) {
  final raw = rek?['semester'];
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  if (raw is String) return int.tryParse(raw);
  return null;
}

String _filenameFromRek(String nama, int semester) {
  final safe = nama.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]+'), '_');
  return 'Laporan_AI_${safe}_Semester_${semester}.pdf';
}

void _showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
