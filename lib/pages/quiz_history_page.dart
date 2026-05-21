import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QuizHistoryPage extends StatelessWidget {
  const QuizHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Kuis"),
        backgroundColor: const Color(0xFF6A11CB),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[100],
      body: user == null 
          ? const Center(child: Text("Silakan login kembali"))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('history')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Terjadi kesalahan: ${snapshot.error}"));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_edu, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 10),
                        const Text("Belum ada riwayat kuis.", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final score = data['score'] ?? 0;
                    final title = data['quizTitle'] ?? "Kuis";
                    
                    // MEMBUAT FORMAT TANGGAL MANUAL AMAN & RAPI (Tanpa package intl)
                    String date = "Waktu tidak diketahui";
                    if (data['timestamp'] != null) {
                      DateTime dt = (data['timestamp'] as Timestamp).toDate();
                      
                      // Menambahkan angka 0 di depan jika hari/bulan/jam/menit bernilai < 10 (Contoh: 05)
                      String day = dt.day.toString().padLeft(2, '0');
                      String month = dt.month.toString().padLeft(2, '0');
                      String hour = dt.hour.toString().padLeft(2, '0');
                      String minute = dt.minute.toString().padLeft(2, '0');
                      
                      date = "$day-$month-${dt.year} pukul $hour:$minute";
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 2,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check, color: Colors.green, size: 24),
                        ),
                        title: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Text(
                          "Selesai pada: $date",
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Nilai", style: TextStyle(fontSize: 10, color: Colors.grey)),
                            Text(
                              "$score",
                              style: TextStyle(
                                fontSize: 20, 
                                fontWeight: FontWeight.bold,
                                color: score >= 70 ? Colors.green : Colors.orange
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}