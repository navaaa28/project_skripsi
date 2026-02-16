import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../utils/helpers.dart';
import '../widgets/student_bottom_nav.dart';

class GraphScreen extends StatefulWidget {
  const GraphScreen({
    super.key,
    required this.nilai,
    required this.kelasAktif,
  });

  final List<Map<String, dynamic>> nilai;
  final String kelasAktif;

  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  static const _allLabel = 'Semua';
  late String _selectedMapel;

  @override
  void initState() {
    super.initState();
    _selectedMapel = _allLabel;
  }

  @override
  Widget build(BuildContext context) {
    final mapelList = _getMapelList(widget.nilai);
    final available = [_allLabel, ...mapelList];
    if (!available.contains(_selectedMapel)) {
      _selectedMapel = _allLabel;
    }

    final spots = _buildSpots(widget.nilai, _selectedMapel);
    final maxX = spots.isEmpty ? 6.0 : spots.last.x;

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
                    'Grafik Perkembangan',
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
            SizedBox(
              height: 44,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: available.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final label = available[index];
                  final active = label == _selectedMapel;
                  return ChoiceChip(
                    label: Text(label),
                    selected: active,
                    onSelected: (_) => setState(() => _selectedMapel = label),
                    selectedColor: const Color(0xFF2563EB),
                    labelStyle: TextStyle(
                      color: active ? Colors.white : const Color(0xFF0F172A),
                      fontWeight: FontWeight.w600,
                    ),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Tren Nilai per Semester',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 220,
                padding: const EdgeInsets.all(12),
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
                child: spots.isEmpty
                    ? const Center(
                        child: Text(
                          'Belum ada data grafik.',
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                      )
                    : LineChart(
                        LineChartData(
                          minY: 0,
                          maxY: 100,
                          minX: 1,
                          maxX: maxX < 6 ? 6 : maxX,
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 20,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: const Color(0xFFE2E8F0),
                              strokeWidth: 1,
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles:
                                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 20,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    value.toInt().toString(),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF64748B),
                                    ),
                                  );
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 1,
                                getTitlesWidget: (value, meta) {
                                  if (value < 1 || value > 6) return const SizedBox.shrink();
                                  return Text(
                                    value.toInt().toString(),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF64748B),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              color: const Color(0xFF2563EB),
                              barWidth: 3,
                              dotData: FlDotData(show: true),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Sentuh titik pada grafik untuk melihat detail nilai.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const Spacer(),
            StudentBottomNav(
              activeIndex: 2,
              nilai: widget.nilai,
              kelasAktif: widget.kelasAktif,
            ),
          ],
        ),
      ),
    );
  }
}

List<String> _getMapelList(List<Map<String, dynamic>> rows) {
  final set = <String>{};
  for (final row in rows) {
    final mapel = row['mapel']?.toString();
    if (mapel != null && mapel.isNotEmpty) {
      set.add(mapel);
    }
  }
  final list = set.toList();
  list.sort();
  return list;
}

List<FlSpot> _buildSpots(List<Map<String, dynamic>> rows, String mapel) {
  final filtered = rows.where((e) {
    if (mapel == 'Semua') return true;
    return e['mapel']?.toString() == mapel;
  }).toList();

  final bySemester = <int, List<double>>{};
  for (final row in filtered) {
    final semester = toInt(row['semester']);
    final nilai = toDouble(row['nilai_akhir']);
    if (semester == null || nilai == null) continue;
    bySemester.putIfAbsent(semester, () => []).add(nilai);
  }

  final semesters = bySemester.keys.toList()..sort();
  return semesters.map((s) {
    final list = bySemester[s]!;
    final avg = list.reduce((a, b) => a + b) / list.length;
    return FlSpot(s.toDouble(), avg);
  }).toList();
}


