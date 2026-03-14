import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/materi.dart'; // Jika butuh model untuk tombol Review (opsional)

class ResultPage extends StatefulWidget {
  final int score; // Jumlah jawaban benar
  final int total; // Total soal
  final MateriModel? materi; // Opsional: untuk tombol "Coba Lagi" atau "Review"

  const ResultPage({
    super.key, 
    required this.score, 
    required this.total,
    this.materi,
  });

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  int earnedPoints = 0;
  bool isUpdating = true; // Status loading update poin

  @override
  void initState() {
    super.initState();
    _calculateAndSavePoints();
  }

  // --- LOGIKA HITUNG & SIMPAN POIN ---
  void _calculateAndSavePoints() async {
    // 1. Hitung Nilai (0 - 100)
    // Jika skor 100% -> Poin 100.
    double percentage = (widget.score / widget.total) * 100;
    earnedPoints = percentage.round();

    // 2. Simpan ke Firebase (Hanya jika poin > 0)
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && earnedPoints > 0) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          // FieldValue.increment() sangat penting agar poin bertambah, bukan menimpa
          'points': FieldValue.increment(earnedPoints),
        });
      } catch (e) {
        print("Gagal update poin: $e");
      }
    }

    if (mounted) {
      setState(() {
        isUpdating = false; // Selesai update
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Gambar Piala atau Icon
              const Icon(Icons.emoji_events_rounded, size: 100, color: Colors.amber),
              const SizedBox(height: 20),
              
              const Text("Kuis Selesai!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              
              Text(
                "Skor Kamu: ${widget.score} / ${widget.total}",
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 30),

              // Kartu Poin yang Didapat
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.indigo.shade100),
                ),
                child: Column(
                  children: [
                    const Text("Poin Diperoleh", style: TextStyle(color: Colors.indigo)),
                    const SizedBox(height: 5),
                    isUpdating 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(
                          "+$earnedPoints", 
                          style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.indigo)
                        ),
                  ],
                ),
              ),

              const SizedBox(height: 50),

              // Tombol Kembali
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    // Kembali ke Halaman Utama dan Hapus semua tumpukan halaman kuis
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6A11CB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text("KEMBALI KE HOME", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}