import 'package:flutter/material.dart';

class ProjectionPage extends StatelessWidget {
  final String title;
  final String coverUrl;

  const ProjectionPage({super.key, required this.title, required this.coverUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Latar gelap agar fokus ke materi (layaknya proyektor)
      body: Stack(
        children: [
          // Gambar/Materi di Tengah Layar
          Center(
            child: InteractiveViewer( // Bisa di-zoom (cubit layar) oleh guru
              child: Image.network(coverUrl, fit: BoxFit.contain),
            ),
          ),
          
          // Tombol Silang untuk Menutup Presentasi (di Kiri Atas)
          Positioned(
            top: 50,
            left: 20,
            child: Container(
              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // Label Judul Materi (di Bawah Tengah)
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24)
                ),
                child: Text(
                  "Sedang Memproyeksikan:\n$title",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}