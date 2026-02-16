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
    final minatUtama = _firstLabel(minatList);
    final bakatUtama = _firstLabel(bakatList);
    final minatPct = _firstPct(minatList);
    final bakatPct = _firstPct(bakatList);
    final confidence = toDouble(rekomendasi?['confidence_score']);
    final analisis = rekomendasi?['analisis_tren']?.toString();
    final ringkasanNon = rekomendasi?['ringkasan_non_akademik']?.toString();
    final saran = rekomendasi?['saran_pengembangan']?.toString();
    final tanggal = rekomendasi?['tgl_analisis']?.toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _HeaderCard(
              namaSiswa: namaSiswa,
              tanggal: tanggal,
              confidence: confidence,
            ),
            const SizedBox(height: 12),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle(
                    icon: Icons.star,
                    title: 'Minat (Top 3)',
                    color: Color(0xFF2563EB),
                  ),
                  const SizedBox(height: 8),
                  _ChipWrap(items: minatList, tint: const Color(0xFF2563EB)),
                  const SizedBox(height: 12),
                  const _SectionTitle(
                    icon: Icons.emoji_events,
                    title: 'Bakat (Top 3)',
                    color: Color(0xFFF59E0B),
                  ),
                  const SizedBox(height: 8),
                  _ChipWrap(items: bakatList, tint: const Color(0xFFF59E0B)),
                  const SizedBox(height: 16),
                  _HighlightRow(
                    label: 'Minat Utama',
                    value: minatUtama ?? '-',
                    suffix: minatPct == null ? null : '${minatPct.toStringAsFixed(0)}%',
                  ),
                  const SizedBox(height: 8),
                  _HighlightRow(
                    label: 'Bakat Potensial',
                    value: bakatUtama ?? '-',
                    suffix: bakatPct == null ? null : '${bakatPct.toStringAsFixed(0)}%',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle(
                    icon: Icons.trending_up,
                    title: 'Ringkasan Akademik',
                    color: Color(0xFF16A34A),
                  ),
                  const SizedBox(height: 8),
                  Text(analisis ?? '-', style: const TextStyle(color: Color(0xFF475569))),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle(
                    icon: Icons.group,
                    title: 'Ringkasan Non-Akademik',
                    color: Color(0xFF7C3AED),
                  ),
                  const SizedBox(height: 8),
                  Text(ringkasanNon ?? '-', style: const TextStyle(color: Color(0xFF475569))),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle(
                    icon: Icons.lightbulb,
                    title: 'Saran Pengembangan (AI)',
                    color: Color(0xFF0EA5E9),
                  ),
                  const SizedBox(height: 8),
                  Text(saran ?? '-', style: const TextStyle(color: Color(0xFF475569))),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _downloadPdf(context, rekomendasi, namaSiswa),
                child: const Text(
                  'Unduh Laporan Lengkap (PDF)',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Laporan berisi detail nilai, observasi non-akademik,\n'
              'dan hasil analisis AI',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
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

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.namaSiswa,
    required this.tanggal,
    required this.confidence,
  });

  final String namaSiswa;
  final String? tanggal;
  final double? confidence;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF60A5FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                child: Icon(Icons.school, color: Color(0xFF2563EB)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Hasil Analisis Minat & Bakat',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Halo, $namaSiswa!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  confidence == null ? 'Keyakinan -' : 'Keyakinan ${confidence!.toStringAsFixed(0)}%',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              if (tanggal != null)
                Text(
                  '• $tanggal',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
            ],
          ),
        ],
      ),
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

class _HighlightRow extends StatelessWidget {
  const _HighlightRow({
    required this.label,
    required this.value,
    this.suffix,
  });

  final String label;
  final String value;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        if (suffix != null) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              suffix!,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ],
    );
  }
}

class _ChipWrap extends StatelessWidget {
  const _ChipWrap({required this.items, required this.tint});

  final List<Map<String, dynamic>> items;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Text('-', style: TextStyle(color: Color(0xFF64748B)));
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final label = item['nama']?.toString() ?? '-';
        final pct = toDouble(item['persentase']);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: tint.withOpacity(0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: tint.withOpacity(0.3)),
          ),
          child: Text(
            pct == null ? label : '$label  ${pct.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: tint,
            ),
          ),
        );
      }).toList(),
    );
  }
}

String? _firstLabel(List<Map<String, dynamic>> list) {
  if (list.isNotEmpty) {
    return list.first['nama']?.toString();
  }
  return null;
}

double? _firstPct(List<Map<String, dynamic>> list) {
  if (list.isNotEmpty) {
    return toDouble(list.first['persentase']);
  }
  return null;
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
