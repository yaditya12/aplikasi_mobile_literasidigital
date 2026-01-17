import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Background Gradient
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4A47F5), Color(0xFF00B7FF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              
              // MENGAMBIL DATA DARI FIREBASE
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .orderBy('points', descending: true) // Urutkan poin tertinggi
                      .limit(50) // Batasi 50 besar agar ringan
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.white));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text("Belum ada data peringkat", style: TextStyle(color: Colors.white)));
                    }

                    final docs = snapshot.data!.docs;
                    
                    // Pisahkan Top 3 dengan Sisa List
                    // Logika: Ambil data jika ada, jika tidak ada (misal user cuma 1), return null
                    final first = docs.isNotEmpty ? docs[0] : null;
                    final second = docs.length > 1 ? docs[1] : null;
                    final third = docs.length > 2 ? docs[2] : null;
                    
                    // Ambil sisa list (mulai dari index 3 ke atas)
                    final restOfUsers = docs.length > 3 ? docs.sublist(3) : <QueryDocumentSnapshot>[];

                    return Column(
                      children: [
                        // --- BAGIAN PODIUM (TOP 3) ---
                        _buildTopThree(first, second, third),

                        const SizedBox(height: 20),

                        // --- BAGIAN LIST BAWAH (RANK 4++) ---
                        Expanded(
                          child: _buildRankingList(restOfUsers),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- HEADER ---
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 10),
          const Text(
            "Leaderboard",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // --- PODIUM WIDGET (JUARA 1, 2, 3) ---
  Widget _buildTopThree(QueryDocumentSnapshot? first, QueryDocumentSnapshot? second, QueryDocumentSnapshot? third) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end, // Agar sejajar bawah
        children: [
          // JUARA 2 (KIRI)
          if (second != null) 
            Expanded(child: _buildPodiumUser(second, "2", 80, Colors.teal)),
          if (second == null) const Spacer(), // Spacer jika data tidak ada

          // JUARA 1 (TENGAH - LEBIH BESAR)
          if (first != null) 
            Expanded(child: _buildPodiumUser(first, "1", 110, Colors.orange, isGrand: true)),
          
          // JUARA 3 (KANAN)
          if (third != null) 
            Expanded(child: _buildPodiumUser(third, "3", 80, Colors.blueAccent)),
          if (third == null) const Spacer(),
        ],
      ),
    );
  }

  Widget _buildPodiumUser(QueryDocumentSnapshot data, String rank, double size, Color badgeColor, {bool isGrand = false}) {
    final Map<String, dynamic> user = data.data() as Map<String, dynamic>;
    String name = user['username'] ?? 'User';
    int points = user['points'] ?? 0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Foto Profil (Avatar)
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                image: DecorationImage(
                  // Menggunakan UI Avatars agar dinamis sesuai nama
                  image: NetworkImage("https://ui-avatars.com/api/?name=$name&background=random&size=128"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Badge Angka (1, 2, 3)
            Transform.translate(
              offset: const Offset(0, 10),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(
                  rank,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Text(
          name,
          style: TextStyle(
            color: Colors.white, 
            fontWeight: FontWeight.bold,
            fontSize: isGrand ? 16 : 14,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        Text(
          "$points pts",
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  // --- LIST WIDGET (RANK 4 KE BAWAH) ---
  Widget _buildRankingList(List<QueryDocumentSnapshot> docs) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: docs.length,
        separatorBuilder: (context, index) => Divider(color: Colors.grey[200]),
        itemBuilder: (context, index) {
          final data = docs[index].data() as Map<String, dynamic>;
          int currentRank = index + 4; // Karena index mulai 0, dan ini rank ke-4

          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: SizedBox(
              width: 40,
              child: Text(
                "#$currentRank",
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            title: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.indigo.shade50,
                  backgroundImage: NetworkImage(
                    "https://ui-avatars.com/api/?name=${data['username']}&background=random&color=fff"
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    data['username'] ?? "User",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "${data['points']} pts",
                style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          );
        },
      ),
    );
  }
}