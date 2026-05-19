import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UploadMateriLinkPage extends StatefulWidget {
  const UploadMateriLinkPage({super.key});

  @override
  State<UploadMateriLinkPage> createState() => _UploadMateriLinkPageState();
}

class _UploadMateriLinkPageState extends State<UploadMateriLinkPage> {
  final _titleController = TextEditingController();
  final _linkController = TextEditingController();
  String _selectedType = 'Bahan Bacaan (PDF)';
  bool _isLoading = false;

  final List<String> _types = [
    'Bahan Bacaan (PDF)',
    'Presentasi (PPT/Canva)',
    'Infografis (Gambar)',
    'Video Pembelajaran'
  ];

  Future<void> _saveMateri() async {
    if (_titleController.text.isEmpty || _linkController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Judul dan Link wajib diisi!")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // --- LOGIKA GAMBAR OTOMATIS YANG BARU (LEBIH MENARIK & PROFESIONAL) ---
      String coverUrl = 'https://images.unsplash.com/photo-1456406644174-8ddd4cd52a06?q=80&w=500&auto=format&fit=crop'; // Gambar Default Edukasi
      
      if (_selectedType.contains('PDF')) {
        // Gambar Buku / Dokumen Meja Belajar
        coverUrl = 'https://images.unsplash.com/photo-1512820790803-83ca734da794?q=80&w=500&auto=format&fit=crop'; 
      } else if (_selectedType.contains('Presentasi')) {
        // Gambar Layar Presentasi / Laptop
        coverUrl = 'https://images.unsplash.com/photo-1557804506-669a67965ba0?q=80&w=500&auto=format&fit=crop';
      } else if (_selectedType.contains('Infografis')) {
        // Gambar Data / Statistik Modern
        coverUrl = 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?q=80&w=500&auto=format&fit=crop';
      } else if (_selectedType.contains('Video')) {
        // Gambar Layar Multimedia / Video
        coverUrl = 'https://images.unsplash.com/photo-1611162617474-5b21e879e113?q=80&w=500&auto=format&fit=crop';
      }

      // Menyimpan ke database Firestore
      await FirebaseFirestore.instance.collection('materi_siap_pakai').add({
        'title': _titleController.text.trim(),
        'type': _selectedType,
        'link': _linkController.text.trim(),
        'cover': coverUrl, // Menyimpan link gambar yang sudah otomatis dipilih di atas
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Materi berhasil ditambahkan!"), backgroundColor: Colors.green));
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal menyimpan: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Tambah Materi Baru", style: TextStyle(fontWeight: FontWeight.bold)), 
        backgroundColor: const Color(0xFF6A11CB), 
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(20), 
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))]
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.cloud_upload_rounded, size: 70, color: Color(0xFF6A11CB)),
              const SizedBox(height: 15),
              const Text(
                "Bagikan link materi (Google Drive, Canva, YouTube) agar bisa diakses langsung oleh siswa.", 
                textAlign: TextAlign.center, 
                style: TextStyle(color: Colors.grey, fontSize: 14)
              ),
              const SizedBox(height: 35),
              
              // Input Judul
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: "Judul Materi", 
                  prefixIcon: const Icon(Icons.title, color: Color(0xFF6A11CB)), 
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF6A11CB), width: 2)),
                ),
              ),
              const SizedBox(height: 20),
              
              // Dropdown Jenis Materi
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: "Jenis Materi (Gambar menyesuaikan otomatis)", 
                  prefixIcon: const Icon(Icons.category, color: Color(0xFF6A11CB)), 
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF6A11CB), width: 2)),
                ),
                items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (val) => setState(() => _selectedType = val!),
              ),
              const SizedBox(height: 20),
              
              // Input Link
              TextField(
                controller: _linkController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: "Link Materi (Tempel/Paste di sini)", 
                  prefixIcon: const Icon(Icons.link, color: Color(0xFF6A11CB)), 
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF6A11CB), width: 2)),
                ),
              ),
              const SizedBox(height: 40),
              
              // Tombol Simpan
              SizedBox(
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6A11CB), 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 5,
                    shadowColor: const Color(0xFF6A11CB).withOpacity(0.5)
                  ),
                  onPressed: _isLoading ? null : _saveMateri,
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : const Text("SIMPAN MATERI", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}