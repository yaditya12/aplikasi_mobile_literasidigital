import 'dart:async'; // <-- Tambahan import untuk fungsi Timeout
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
  bool _sedangMenghapus = false;
  
  // --- FUNGSI 1: MUNCULKAN POP-UP KONFIRMASI ---
  void _tampilkanKonfirmasiHapus(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text("Hapus Akun?"),
          ],
        ),
        content: const Text(
          "Apakah Anda yakin ingin menghapus akun ini secara permanen? Semua data poin dan riwayat Anda akan hilang total.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context); // Tutup pop-up konfirmasi
              _hapusAkunPermanen(context); // Eksekusi penghapusan
            },
            child: const Text("Ya, Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- FUNGSI 2: PROSES HAPUS FIREBASE ---
  Future<void> _hapusAkunPermanen(BuildContext context) async {
    // Capture navigator & messenger SEBELUM await, agar aman dari context yang
    // mungkin sudah tidak valid setelah authStateChanges memicu rebuild.
    final navigator = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.of(context);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      navigator.pushNamedAndRemoveUntil('/login', (route) => false);
      return;
    }

    setState(() {
      _sedangMenghapus = true;
    });

    try {
      // 1. Hapus dokumen Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .delete()
          .timeout(const Duration(seconds: 5));

      // 2. Hapus akun Autentikasi Firebase
      await user.delete().timeout(const Duration(seconds: 5));

      // 3. Pastikan benar-benar signed out (kadang user.delete() perlu dibarengi signOut)
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}

      // 4. Navigate eksplisit ke LoginPage dan bersihkan seluruh stack.
      //    Tidak mengandalkan StreamBuilder rebuild agar tidak ada race condition.
      if (mounted) {
        navigator.pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      String pesanEror = "Terjadi kesalahan. Silakan coba lagi.";

      if (e is FirebaseAuthException) {
        if (e.code == 'requires-recent-login') {
          // Sesi login terlalu lama, paksa logout demi keamanan
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            navigator.pushNamedAndRemoveUntil('/login', (route) => false);
          }
          pesanEror =
              'Demi keamanan, silakan Login kembali lalu ulangi proses Hapus Akun.';
        } else {
          pesanEror = e.message ?? "Gagal menghapus autentikasi akun.";
        }
      } else if (e is FirebaseException) {
        pesanEror =
            "Firestore Diblokir: ${e.message}\n(Periksa Firestore Rules Anda!)";
      } else if (e is TimeoutException) {
        pesanEror = "Koneksi lambat/habis. Periksa jaringan internet Anda.";
      }

      // Matikan loading hanya jika widget masih ada (belum di-pop)
      if (mounted) {
        setState(() {
          _sedangMenghapus = false;
        });
        messenger.showSnackBar(
          SnackBar(
            content: Text(pesanEror),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_sedangMenghapus) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.red),
              SizedBox(height: 20),
              Text(
                "Menghapus akun Anda...\nMohon tunggu sebentar.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
        ),
      );
    }

    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      // Auth sudah hilang (mis. selesai hapus akun). Arahkan ke LoginPage.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context, rootNavigator: true)
              .pushNamedAndRemoveUntil('/login', (route) => false);
        }
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
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
                    
                    Text(username, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                    Text(email, style: const TextStyle(color: Colors.grey, fontSize: 14)),

                    const SizedBox(height: 30),

                    Row(
                      children: [
                        Expanded(
                          child: _buildColorCard(
                            "Total Poin", 
                            "$myPoints", 
                            Icons.stars_rounded, 
                            const Color(0xFFFFF3E0), 
                            Colors.orange 
                          )
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildColorCard(
                            "Peringkat", 
                            rankStr, 
                            Icons.emoji_events_rounded, 
                            const Color(0xFFEDE7F6), 
                            const Color(0xFF6A11CB) 
                          )
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),
                    const Divider(),
                    const SizedBox(height: 10),

                    _buildSettingsTile(context, "Edit Profil", Icons.edit_outlined, Colors.blue, () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfilePage(currentUsername: username, currentEmail: email, currentPhotoUrl: photoUrl)));
                    }),
                    _buildSettingsTile(context, "Riwayat Kuis", Icons.history_edu, Colors.purple, () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const QuizHistoryPage()));
                    }),
                    _buildSettingsTile(context, "Pusat Bantuan", Icons.support_agent, Colors.green, () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpCenterPage()));
                    }),
                    
                    const SizedBox(height: 20),
                    _buildSettingsTile(context, "Hapus Akun", Icons.person_off_rounded, Colors.red, () {
                      _tampilkanKonfirmasiHapus(context);
                    }),
                    const SizedBox(height: 30),
                  ],
                ),
              );
            }
          );
        },
      ),
    );
  }

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
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: color == Colors.red ? Colors.red : Colors.black87)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
    );
  }
}