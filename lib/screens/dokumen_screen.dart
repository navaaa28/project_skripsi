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

    if ((file.size) > 5 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File terlalu besar. Maks 5MB.', style: TextStyle(fontSize: 16)),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
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
          content: Text('Dokumen berhasil diupload!', style: TextStyle(fontSize: 16)),
          backgroundColor: Color(0xFF22C55E),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', ''), style: const TextStyle(fontSize: 16)),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Dokumen', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        content: Text('Yakin ingin menghapus "$nama"?', style: const TextStyle(fontSize: 18)),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Hapus', style: TextStyle(fontSize: 18)),
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
          content: Text('Dokumen berhasil dihapus.', style: TextStyle(fontSize: 16)),
          backgroundColor: Color(0xFF22C55E),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', ''), style: const TextStyle(fontSize: 16)),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
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
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 60,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Pilih Jenis Dokumen',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sentuh salah satu kotak di bawah untuk mengupload',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 24),
            Flexible(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),
                shrinkWrap: true,
                itemCount: _jenisTersedia.length,
                itemBuilder: (context, index) {
                  final e = _jenisTersedia.entries.elementAt(index);
                  final sudahUpload = _dokumen.any((d) => d['jenis_dokumen'] == e.key);
                  return Material(
                    color: sudahUpload ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        _upload(e.key);
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: sudahUpload ? const Color(0xFF22C55E) : const Color(0xFFE2E8F0),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _iconForJenis(e.key),
                              size: 48,
                              color: sudahUpload ? const Color(0xFF22C55E) : const Color(0xFF6366F1),
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                e.value,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: sudahUpload ? const Color(0xFF15803D) : const Color(0xFF334155),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (sudahUpload)
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text(
                                  '(Sudah Ada)',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF16A34A), fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForJenis(String jenis) {
    switch (jenis) {
      case 'kk':
        return Icons.family_restroom_rounded;
      case 'akte':
        return Icons.child_friendly_rounded;
      case 'ijazah':
        return Icons.school_rounded;
      case 'ktp_ortu':
        return Icons.credit_card_rounded;
      case 'foto':
        return Icons.add_a_photo_rounded;
      default:
        return Icons.description_rounded;
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
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A), size: 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  const Expanded(
                    child: Text(
                      'Dokumen Saya',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 4))
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.red[50],
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.error_outline_rounded, size: 60, color: Colors.red),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 18, color: Color(0xFF64748B)),
                                ),
                                const SizedBox(height: 32),
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _load,
                                    style: ElevatedButton.styleFrom(
                                      elevation: 0,
                                      backgroundColor: const Color(0xFF6366F1),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                    child: const Text('Coba Lagi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: _dokumen.isEmpty
                              ? ListView(
                                  padding: const EdgeInsets.all(32),
                                  children: const [
                                    SizedBox(height: 60),
                                    Icon(Icons.folder_open_rounded, size: 120, color: Color(0xFFCBD5E1)),
                                    SizedBox(height: 32),
                                    Text(
                                      'Belum ada dokumen',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'Tekan tombol tambah (+) di bawah untuk mulai mengupload dokumen sekolahmu.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 18, color: Color(0xFF94A3B8), height: 1.5),
                                    ),
                                  ],
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.all(24),
                                  itemCount: _dokumen.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                                  itemBuilder: (_, i) {
                                    final doc = _dokumen[i] as Map<String, dynamic>;
                                    final isPdf = (doc['mime_type'] ?? '').toString().contains('pdf');
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.04),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () => _viewDocument(doc),
                                          borderRadius: BorderRadius.circular(20),
                                          child: Padding(
                                            padding: const EdgeInsets.all(20),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 72,
                                                  height: 72,
                                                  decoration: BoxDecoration(
                                                    color: isPdf ? const Color(0xFFFEF2F2) : const Color(0xFFEFF6FF),
                                                    borderRadius: BorderRadius.circular(16),
                                                  ),
                                                  child: (doc['url'] != null && !isPdf)
                                                      ? ClipRRect(
                                                          borderRadius: BorderRadius.circular(16),
                                                          child: Image.network(
                                                            doc['url'],
                                                            fit: BoxFit.cover,
                                                            width: 72,
                                                            height: 72,
                                                            loadingBuilder: (context, child, loadingProgress) {
                                                              if (loadingProgress == null) return child;
                                                              return Center(
                                                                child: CircularProgressIndicator(
                                                                  value: loadingProgress.expectedTotalBytes != null
                                                                      ? loadingProgress.cumulativeBytesLoaded /
                                                                          loadingProgress.expectedTotalBytes!
                                                                      : null,
                                                                  strokeWidth: 2,
                                                                ),
                                                              );
                                                            },
                                                            errorBuilder: (context, error, stackTrace) => const Icon(
                                                              Icons.broken_image_rounded,
                                                              color: Color(0xFF94A3B8),
                                                              size: 32,
                                                            ),
                                                          ),
                                                        )
                                                      : Icon(
                                                          isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                                                          color: isPdf ? const Color(0xFFEF4444) : const Color(0xFF3B82F6),
                                                          size: 36,
                                                        ),
                                                ),
                                                const SizedBox(width: 20),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        doc['label'] ?? doc['jenis_dokumen'] ?? '',
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 18,
                                                          color: Color(0xFF1E293B),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 6),
                                                      Text(
                                                        '${doc['nama_file']}',
                                                        style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        _formatSize(doc['size']),
                                                        style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 32),
                                                  padding: const EdgeInsets.all(12),
                                                  onPressed: () => _delete(doc['id'] as int, doc['label'] ?? ''),
                                                ),
                                              ],
                                            ),
                                          ),
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
          ? Container(
              width: 72,
              height: 72,
              margin: const EdgeInsets.only(bottom: 8),
              child: FloatingActionButton(
                onPressed: _uploading ? null : _showUploadPicker,
                backgroundColor: const Color(0xFF6366F1),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: _uploading
                    ? const SizedBox(width: 32, height: 32, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    : const Icon(Icons.add_rounded, color: Colors.white, size: 40),
              ),
            )
          : null,
    );
  }
}
