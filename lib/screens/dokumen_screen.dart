import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../services/api_client.dart';
import '../services/auth_storage.dart';

class DokumenScreen extends StatefulWidget {
  const DokumenScreen({super.key});

  @override
  State<DokumenScreen> createState() => _DokumenScreenState();
}

class _DokumenScreenState extends State<DokumenScreen> {
  final _api = ApiClient(apiBaseUrl);
  List<dynamic> _dokumen = [];
  Map<String, String> _jenisTersedia = {};
  bool _loading = true;
  bool _uploading = false;
  String? _error;

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
      if (token == null) return;
      final data = await _api.getDokumen(token);
      setState(() {
        _jenisTersedia = Map<String, String>.from(data['jenis_tersedia'] ?? {});
        _dokumen = data['dokumen'] as List<dynamic>? ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _upload(String jenis) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.path == null) return;

    // Check size (max 2MB)
    if ((file.size) > 2 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File terlalu besar. Maks 2MB.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _uploading = true);

    try {
      final token = await AuthStorage().getToken();
      if (token == null) return;
      await _api.uploadDokumen(
        token,
        jenisDokumen: jenis,
        filePath: file.path!,
        fileName: file.name,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dokumen berhasil diupload!'),
          backgroundColor: Color(0xFF22C55E),
        ),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _delete(int id, String nama) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Dokumen'),
        content: Text('Yakin ingin menghapus "$nama"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final token = await AuthStorage().getToken();
      if (token == null) return;
      await _api.deleteDokumen(token, id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dokumen berhasil dihapus.'),
          backgroundColor: Color(0xFF22C55E),
        ),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _viewDocument(Map<String, dynamic> doc) async {
    final url = doc['url'] as String?;
    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL dokumen tidak ditemukan'), backgroundColor: Colors.red),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final filename = doc['nama_file'] ?? 'document';
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$filename');

      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) throw Exception('Gagal mendownload file');

      await file.writeAsBytes(response.bodyBytes);

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      await OpenFilex.open(file.path);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuka dokumen: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showUploadPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih Jenis Dokumen',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            ..._jenisTersedia.entries.map((e) {
              final sudahUpload = _dokumen.any((d) => d['jenis_dokumen'] == e.key);
              return ListTile(
                leading: Icon(
                  _iconForJenis(e.key),
                  color: sudahUpload ? const Color(0xFF22C55E) : const Color(0xFF6366F1),
                ),
                title: Text(e.value),
                subtitle: sudahUpload ? const Text('Sudah diupload', style: TextStyle(color: Color(0xFF22C55E), fontSize: 12)) : null,
                trailing: sudahUpload
                    ? const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 20)
                    : const Icon(Icons.upload_file, color: Color(0xFF94A3B8), size: 20),
                onTap: () {
                  Navigator.pop(ctx);
                  _upload(e.key);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  IconData _iconForJenis(String jenis) {
    switch (jenis) {
      case 'kk':
        return Icons.family_restroom;
      case 'akte':
        return Icons.baby_changing_station;
      case 'ijazah':
        return Icons.school;
      case 'ktp_ortu':
        return Icons.credit_card;
      case 'foto':
        return Icons.photo_camera;
      default:
        return Icons.description;
    }
  }

  String _formatSize(dynamic size) {
    final bytes = size is int ? size : int.tryParse(size.toString()) ?? 0;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Dokumen Saya',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_error!, style: const TextStyle(color: Colors.red)),
                              const SizedBox(height: 8),
                              ElevatedButton(onPressed: _load, child: const Text('Coba Lagi')),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: _dokumen.isEmpty
                              ? ListView(
                                  children: [
                                    const SizedBox(height: 80),
                                    const Icon(Icons.folder_open, size: 64, color: Color(0xFFD1D5DB)),
                                    const SizedBox(height: 12),
                                    const Center(
                                      child: Text(
                                        'Belum ada dokumen',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Center(
                                      child: Text(
                                        'Tekan tombol + untuk mengupload dokumen',
                                        style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                                      ),
                                    ),
                                  ],
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                                  itemCount: _dokumen.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                                  itemBuilder: (_, i) {
                                    final doc = _dokumen[i] as Map<String, dynamic>;
                                    final isPdf = (doc['mime_type'] ?? '').toString().contains('pdf');
                                    return Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: const [
                                          BoxShadow(color: Color(0x11000000), blurRadius: 6, offset: Offset(0, 2)),
                                        ],
                                      ),
                                      child: InkWell(
                                        onTap: () => _viewDocument(doc),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: isPdf ? const Color(0xFFFEE2E2) : const Color(0xFFDBEAFE),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                isPdf ? Icons.picture_as_pdf : Icons.image,
                                                color: isPdf ? const Color(0xFFDC2626) : const Color(0xFF2563EB),
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    doc['label'] ?? doc['jenis_dokumen'] ?? '',
                                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    '${doc['nama_file']} • ${_formatSize(doc['size'])}',
                                                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
                                              onPressed: () => _delete(doc['id'] as int, doc['label'] ?? ''),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
            ),
          ],
        ),
      ),

      // FAB
      floatingActionButton: (!_loading && _error == null)
          ? FloatingActionButton(
              onPressed: _uploading ? null : _showUploadPicker,
              backgroundColor: const Color(0xFF6366F1),
              child: _uploading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}
