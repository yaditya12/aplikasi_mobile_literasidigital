import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AchievementsPage extends StatelessWidget {
  const AchievementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Ambil ID pengguna saat ini
    final String? uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      // Gunakan StreamBuilder agar badge ter-update realtime sesuai poin
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, snapshot) {
          // 1. Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.orange));
          }

          // 2. Data Processing
          int currentPoints = 0;
          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            currentPoints = data['points'] ?? 0;
          }

          // 3. Logika Membuka Badge Berdasarkan Poin
          // (Anda bisa sesuaikan logika ini nanti)
          final List<Map<String, dynamic>> achievements = [
            {
              "title": "Newbie",
              "desc": "Daftar akun pertama kali",
              "icon": Icons.person_add,
              "unlocked": true // Selalu terbuka
            },
            {
              "title": "Quick Learner",
              "desc": "Dapatkan 500 poin pertama",
              "icon": Icons.bolt,
              "unlocked": currentPoints >= 500
            },
            {
              "title": "High Scorer",
              "desc": "Capai 5.000 poin",
              "icon": Icons.star,
              "unlocked": currentPoints >= 5000
            },
            {
              "title": "Top Rank",
              "desc": "Capai 10.000 poin",
              "icon": Icons.emoji_events,
              "unlocked": currentPoints >= 10000
            },
            {
              "title": "Master",
              "desc": "Capai 20.000 poin",
              "icon": Icons.psychology,
              "unlocked": currentPoints >= 20000
            },
            {
              "title": "Legend",
              "desc": "Capai 50.000 poin",
              "icon": Icons.workspace_premium,
              "unlocked": currentPoints >= 50000
            },
          ];

          // Hitung berapa yang sudah terbuka
          int unlockedCount = achievements.where((e) => e['unlocked'] == true).length;

          return Column(
            children: [
              _buildHeader(context, unlockedCount, achievements.length),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: achievements.length,
                  itemBuilder: (context, index) {
                    final item = achievements[index];
                    return _buildBadgeCard(
                      item['title'],
                      item['desc'],
                      item['icon'],
                      item['unlocked'],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Header dengan Gradien Oranye
  Widget _buildHeader(BuildContext context, int unlocked, int total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(25, 60, 25, 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF7043), Color(0xFFFFB74D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(height: 20),
          const Text(
            "My Achievements",
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            "$unlocked dari $total tantangan selesai",
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          // Progress Bar Kecil
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: unlocked / total,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 6,
            ),
          )
        ],
      ),
    );
  }

  // Card untuk setiap item achievement
  Widget _buildBadgeCard(String title, String desc, IconData icon, bool isUnlocked) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ikon dengan lingkaran
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isUnlocked ? Colors.orange.withOpacity(0.1) : Colors.grey[100],
            ),
            child: Icon(
              icon,
              color: isUnlocked ? Colors.orange : Colors.grey[400],
              size: 30,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isUnlocked ? Colors.black87 : Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 10),
          // Indikator Status (Teks Terkunci/Terbuka)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isUnlocked ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              isUnlocked ? "Unlocked" : "Locked",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isUnlocked ? Colors.green : Colors.grey,
              ),
            ),
          )
        ],
      ),
    );
  }
}