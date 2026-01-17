import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/materi.dart';

class ResultPage extends StatefulWidget {
  final int score;
  final int total;
  final MateriModel? materi; // Pastikan parameter ini ada

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
  int finalScore = 0; // Nilai skala 0-100
  bool isUpdating = true;

  @override
  void initState() {
    super.initState();
    _calculateAndSaveData();
  }

  void _calculateAndSaveData() async {
    // 1. Hitung Nilai (Skala 100)
    double percentage = (widget.score / widget.total) * 100;
    finalScore = percentage.round();
    earnedPoints = finalScore; // Bisa disesuaikan rumusnya

    final user = FirebaseAuth.instance.currentUser;
    
    if (user != null) {
      try {
        final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

        // 2. Update Poin Total User
        if (earnedPoints > 0) {
          await userRef.update({
            'points': FieldValue.increment(earnedPoints),
          });
        }

        // 3. SIMPAN RIWAYAT KUIS (BARU)
        // Kita simpan ke sub-collection 'history' agar rapi
        await userRef.collection('history').add({
          'quizTitle': widget.materi?.title ?? "Kuis Tanpa Judul",
          'score': finalScore,
          'correct': widget.score,
          'totalQuestions': widget.total,
          'timestamp': FieldValue.serverTimestamp(), // Waktu pengerjaan
        });

      } catch (e) {
        debugPrint("Gagal simpan data: $e");
      }
    }

    if (mounted) {
      setState(() {
        isUpdating = false;
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
              const Icon(Icons.check_circle, size: 100, color: Colors.green), // Ikon Centang Besar
              const SizedBox(height: 20),
              
              const Text("Kuis Selesai!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              
              Text(
                "Nilai Kamu: $finalScore",
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.indigo),
              ),
              Text(
                "Benar ${widget.score} dari ${widget.total} soal",
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 30),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  children: [
                    const Text("Poin Diperoleh", style: TextStyle(color: Colors.indigo)),
                    const SizedBox(height: 5),
                    isUpdating 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text("+$earnedPoints", style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.indigo)),
                  ],
                ),
              ),

              const SizedBox(height: 50),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    // Kembali ke Home dan hapus history tumpukan page
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