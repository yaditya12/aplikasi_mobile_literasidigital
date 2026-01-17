import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import '../data/materi.dart'; 
import '../services/auth_service.dart';

import 'materi_page.dart';
import 'leaderboard_page.dart'; 
import 'achievements_page.dart';
import 'add_materi_page.dart'; 
import 'profile_page.dart'; 
import 'join_quiz_page.dart'; 
import 'login_page.dart'; 

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Kita tidak perlu variabel _userRole manual lagi di sini 
  // karena kita akan mengambilnya langsung dari StreamBuilder di bawah.

  // --- MENU PILIHAN ---
  void _showCreateOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 20),
                const Text("Buat Baru", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 15),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.book, color: Colors.indigo),
                  ),
                  title: const Text("Materi & Kuis"),
                  subtitle: const Text("Buat bahan bacaan lengkap dengan kuis"),
                  onTap: () {
                    Navigator.pop(context); 
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AddMateriPage(isQuizOnly: false)));
                  },
                ),
                const SizedBox(height: 10), 
                ListTile(
                  leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.quiz, color: Colors.orange)),
                  title: const Text("Kuis Saja (Tantangan)"),
                  subtitle: const Text("Hanya soal kuis dengan Kode Unik"),
                  onTap: () {
                    Navigator.pop(context); 
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AddMateriPage(isQuizOnly: true)));
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- LOGIKA EDIT & HAPUS ---
  void _showOptionsDialog(String docId, MateriModel item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Opsi: ${item.title}"),
        content: const Text("Apa yang ingin Anda lakukan?"),
        actions: [
          TextButton(onPressed: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => AddMateriPage(materi: item, docId: docId, isQuizOnly: item.content.isEmpty))); }, child: const Text("Edit")),
          TextButton(onPressed: () { Navigator.pop(context); FirebaseFirestore.instance.collection('materi').doc(docId).delete(); }, child: const Text("Hapus", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Keluar dari aplikasi?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          TextButton(onPressed: () { Navigator.pop(context); AuthService().logout(); }, child: const Text("Keluar", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    // STREAMBUILDER UNTUK USER DATA (Agar Poin & Role Update Real-time)
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUser?.uid).snapshots(),
      builder: (context, userSnapshot) {
        // Default values jika loading/error
        String userRole = "student";
        String displayName = "Student";
        int points = 0;

        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
          userRole = userData['role'] ?? "student";
          displayName = userData['username'] ?? "User";
          points = userData['points'] ?? 0;
        }

        return Scaffold(
          backgroundColor: Colors.white,
          
          floatingActionButton: userRole == 'teacher' 
              ? FloatingActionButton(
                  backgroundColor: const Color(0xFF6A11CB),
                  child: const Icon(Icons.add, color: Colors.white),
                  onPressed: _showCreateOptions,
                )
              : null,

          body: CustomScrollView(
            slivers: [
              // --- HEADER (APP BAR) ---
              SliverAppBar(
                pinned: true, expandedHeight: 140, automaticallyImplyLeading: false, backgroundColor: const Color(0xFF6A11CB),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)])),
                    padding: const EdgeInsets.only(top: 50, left: 20, right: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              // NAVIGASI KE PROFIL
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage())),
                              child: CircleAvatar(
                                radius: 25, 
                                backgroundColor: Colors.white24, 
                                backgroundImage: NetworkImage("https://ui-avatars.com/api/?name=$displayName&background=random&color=fff"),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("Selamat Datang!", style: TextStyle(color: Colors.white70, fontSize: 12)),
                                Text(displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                Text(userRole == 'teacher' ? "(Guru)" : "(Siswa)", style: TextStyle(color: Colors.white70, fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                        // BADGE POIN (DATA ASLI)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                          child: Row(children: [
                            const Icon(Icons.stars, color: Colors.amber, size: 18), 
                            const SizedBox(width: 4), 
                            Text("$points", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)) // Poin dari DB
                          ]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // MENU 4 KOTAK
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildQuickMenu(context, Icons.add, "Join Quiz", const Color(0xFF9C27B0), () => Navigator.push(context, MaterialPageRoute(builder: (context) => const JoinQuizPage()))),
                      _buildQuickMenu(context, Icons.bar_chart, "Rank", const Color(0xFF00BFA5), () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LeaderboardPage()))),
                      _buildQuickMenu(context, Icons.emoji_events, "Badge", const Color(0xFFFF7043), () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AchievementsPage()))),
                      _buildQuickMenu(context, Icons.logout, "Logout", Colors.redAccent, _showLogoutDialog),
                    ],
                  ),
                ),
              ),

              _buildDailyQuizBanner(context),

              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 25, 20, 10),
                  child: Text("Explore Classes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),

              // GRID MATERI
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('materi').orderBy('createdAt', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
                  
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Belum ada materi."))));

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 15, crossAxisSpacing: 15, childAspectRatio: 1.4),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final doc = docs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          MateriModel item = MateriModel(
                            title: data['title'] ?? "Tanpa Judul",
                            content: data['content'] ?? "",
                            quiz: List<Map<String, dynamic>>.from(data['quiz'] ?? []),
                          );
                          bool isQuizOnly = item.content.isEmpty;

                          return InkWell(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MateriPage(materi: item))),
                            onLongPress: userRole == 'teacher' ? () => _showOptionsDialog(doc.id, item) : null,
                            child: Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: isQuizOnly ? Colors.orange.shade400 : Colors.indigo.shade300,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Stack(
                                children: [
                                  Positioned(right: -5, bottom: -10, child: Text("${index + 1}", style: TextStyle(fontSize: 60, color: Colors.white.withOpacity(0.2), fontWeight: FontWeight.bold))),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(item.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 5),
                                      Text(isQuizOnly ? "Tantangan Kuis" : "Materi & Kuis", style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 10)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: docs.length,
                      ),
                    ),
                  );
                },
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        );
      }
    );
  }

  Widget _buildDailyQuizBanner(BuildContext context) { 
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: const Color(0xFFFFE0B2), borderRadius: BorderRadius.circular(25)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Daily Quiz", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)),
            const Text("Play, earn, compete", style: TextStyle(color: Colors.orangeAccent)),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const JoinQuizPage())),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
              child: const Text("Join a quiz"),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildQuickMenu(BuildContext ctx, IconData icon, String label, Color color, VoidCallback onTap) {
     return GestureDetector(
       onTap: onTap, 
       child: Column(children: [
         Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]), child: Icon(icon, color: Colors.white, size: 24)),
         const SizedBox(height: 8),
         Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
       ])
     ); 
  }
}