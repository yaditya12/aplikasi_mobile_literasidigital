import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'login_page.dart';
import 'edit_profile_page.dart';
import 'quiz_history_page.dart'; // Import halaman riwayat baru

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  
  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text("Anda belum login")));
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Profil Saya"),
        centerTitle: true,
        backgroundColor: const Color(0xFF6A11CB),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Data profil tidak ditemukan"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          String username = data['username'] ?? "Tanpa Nama";
          String email = data['email'] ?? currentUser.email ?? "-";
          int points = data['points'] ?? 0;
          String rank = "#5"; 

          return SingleChildScrollView(
            child: Column(
              children: [
                // HEADER PROFIL
                Container(
                  padding: const EdgeInsets.only(bottom: 30),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        backgroundImage: NetworkImage("https://ui-avatars.com/api/?name=$username&background=random&size=128&color=fff"),
                      ),
                      const SizedBox(height: 15),
                      Text(username, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text(email, style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // KARTU STATISTIK
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(Icons.stars, "$points", "Total Poin", Colors.amber),
                          Container(height: 40, width: 1, color: Colors.grey[300]),
                          _buildStatItem(Icons.emoji_events, rank, "Peringkat", Colors.orange),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // --- MENU OPSI ---
                _buildMenuItem(context, Icons.edit, "Edit Profil", () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfilePage(currentUsername: username, currentEmail: email)));
                }),
                
                // TOMBOL RIWAYAT KUIS (Pengganti Sertifikat)
                _buildMenuItem(context, Icons.history, "Riwayat Kuis", () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const QuizHistoryPage()));
                }),
                
                _buildMenuItem(context, Icons.help_outline, "Pusat Bantuan", () {}),
                
                // --- TOMBOL LOGOUT DIHAPUS DARI SINI ---
                // Sesuai permintaan, logout dihilangkan dari list ini.
                
                const SizedBox(height: 50),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Column(children: [Icon(icon, color: color, size: 30), SizedBox(height: 5), Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Text(label, style: TextStyle(color: Colors.grey, fontSize: 12))]);
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Container(padding: EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: Colors.blueAccent)),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}