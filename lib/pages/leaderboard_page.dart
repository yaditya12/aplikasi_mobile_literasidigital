import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE), 
      appBar: AppBar(
        title: const Text("Papan Peringkat", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color(0xFF6A11CB),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Header Dekorasi
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
            decoration: const BoxDecoration(
              color: Color(0xFF6A11CB),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: const Column(
              children: [
                Icon(Icons.emoji_events, size: 60, color: Colors.amber),
                SizedBox(height: 10),
                Text("Top Siswa Berprestasi", style: TextStyle(color: Colors.white70, fontSize: 16)),
              ],
            ),
          ),
          
          // List Peringkat
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'student') 
                  .orderBy('points', descending: true) 
                  .limit(50) 
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_off, size: 60, color: Colors.grey),
                        SizedBox(height: 10),
                        Text("Belum ada data siswa.", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    
                    String name = data['username'] ?? "Tanpa Nama";
                    int points = data['points'] ?? 0;
                    String uid = data['uid'] ?? "";
                    
                    bool isMe = (uid == currentUid);
                    int rank = index + 1;

                    return _buildRankItem(rank, name, points, isMe);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET KARTU PERINGKAT (DIPERBARUI)
  Widget _buildRankItem(int rank, String name, int points, bool isMe) {
    Color? medalColor;
    
    // Logika Warna Medali
    if (rank == 1) {
      medalColor = const Color(0xFFFFD700); // Emas
    } else if (rank == 2) {
      medalColor = const Color(0xFFC0C0C0); // Perak
    } else if (rank == 3) {
      medalColor = const Color(0xFFCD7F32); // Perunggu
    }

    return Transform.scale(
      scale: isMe ? 1.02 : 1.0, 
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFE8EAF6) : Colors.white, 
          borderRadius: BorderRadius.circular(15),
          border: isMe ? Border.all(color: const Color(0xFF6A11CB), width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // --- KOLOM PERINGKAT DENGAN ANGKA ---
            SizedBox(
              width: 50, // Lebar area peringkat
              child: medalColor != null
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        // Ikon Piala di Belakang
                        Icon(Icons.emoji_events, color: medalColor, size: 45),
                        // Angka Peringkat di Tengah Piala
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5), // Geser angka sedikit ke atas agar pas
                          child: Text(
                            "$rank",
                            style: const TextStyle(
                              color: Colors.white, 
                              fontWeight: FontWeight.bold, 
                              fontSize: 14,
                              shadows: [Shadow(blurRadius: 2, color: Colors.black26, offset: Offset(0, 1))]
                            ),
                          ),
                        ),
                      ],
                    )
                  : Text(
                      "#$rank",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
            ),
            const SizedBox(width: 10),

            // --- AVATAR & NAMA ---
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: NetworkImage(
                "https://ui-avatars.com/api/?name=$name&background=random&color=fff"
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 16,
                      color: isMe ? const Color(0xFF6A11CB) : Colors.black87
                    ),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  if (isMe) 
                    const Text("(Saya)", style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ),

            // --- POIN ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.stars, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    "$points",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}