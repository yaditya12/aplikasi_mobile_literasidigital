import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_profile_page.dart';
import 'quiz_history_page.dart';
import 'help_center_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  
  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return const Scaffold(body: Center(child: Text("Anda belum login")));

    return Scaffold(
      backgroundColor: Colors.white, // Background Putih Bersih
      appBar: AppBar(
        title: const Text("Profil Saya", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: Text("Data tidak ditemukan"));

          final data = snapshot.data!.data() as Map<String, dynamic>;
          String username = data['username'] ?? "User";
          String email = data['email'] ?? "-";
          String? photoUrl = data['photoUrl'];
          int myPoints = data['points'] ?? 0;
          
          return FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'student').where('points', isGreaterThan: myPoints).get(),
            builder: (context, rankSnapshot) {
              String rankStr = "...";
              if (rankSnapshot.hasData) {
                rankStr = "#${rankSnapshot.data!.docs.length + 1}";
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // --- FOTO PROFIL BESAR ---
                    Container(
                      padding: const EdgeInsets.all(4), 
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade200, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey.shade100,
                        backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) 
                            ? NetworkImage(photoUrl)
                            : NetworkImage("https://ui-avatars.com/api/?name=$username&background=random&size=128&color=fff"),
                      ),
                    ),
                    const SizedBox(height: 15),
                    
                    // --- NAMA & EMAIL ---
                    Text(username, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                    Text(email, style: const TextStyle(color: Colors.grey, fontSize: 14)),

                    const SizedBox(height: 30),

                    // --- KARTU STATISTIK BERWARNA ---
                    Row(
                      children: [
                        Expanded(
                          child: _buildColorCard(
                            "Total Poin", 
                            "$myPoints", 
                            Icons.stars_rounded, 
                            const Color(0xFFFFF3E0), // Background Oranye Muda
                            Colors.orange // Warna Ikon/Teks
                          )
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildColorCard(
                            "Peringkat", 
                            rankStr, 
                            Icons.emoji_events_rounded, 
                            const Color(0xFFEDE7F6), // Background Ungu Muda
                            const Color(0xFF6A11CB) // Warna Ikon/Teks
                          )
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),
                    const Divider(),
                    const SizedBox(height: 10),

                    // --- MENU SETTINGS (TANPA LOGOUT) ---
                    _buildSettingsTile(context, "Edit Profil", Icons.edit_outlined, Colors.blue, () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfilePage(currentUsername: username, currentEmail: email, currentPhotoUrl: photoUrl)));
                    }),
                    _buildSettingsTile(context, "Riwayat Kuis", Icons.history_edu, Colors.purple, () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const QuizHistoryPage()));
                    }),
                   _buildSettingsTile(context, "Pusat Bantuan", Icons.support_agent, Colors.green, () {
  Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpCenterPage()));
}),
                  ],
                ),
              );
            }
          );
        },
      ),
    );
  }

  // Widget Kartu Statistik Berwarna
  Widget _buildColorCard(String label, String value, IconData icon, Color bgColor, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, color: accentColor, size: 32),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: accentColor)),
          Text(label, style: TextStyle(fontSize: 12, color: accentColor.withOpacity(0.8), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // Widget Menu List Tile
  Widget _buildSettingsTile(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black87)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
    );
  }
}