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
  
  // --- DATA DUMMY BUKU ---
  final List<Map<String, String>> bookList = [
    {
      "title": "Dasar Keamanan",
      "author": "Dr. Budi Santoso",
      "cover": "https://img.freepik.com/free-vector/security-safety-system-report_23-2148882062.jpg",
    },
    {
      "title": "Etika Digital",
      "author": "Siti Aminah, M.Kom",
      "cover": "https://img.freepik.com/free-vector/online-education-concept_23-2148532793.jpg",
    },
    {
      "title": "Coding Pemula",
      "author": "Riko Fajar",
      "cover": "https://img.freepik.com/free-vector/programmer-working-web-development-code-engineer-programming-python-php-java-script-computer_90220-249.jpg",
    },
    {
      "title": "Jaringan Komputer",
      "author": "Tim Literasi",
      "cover": "https://img.freepik.com/free-vector/global-data-security-personal-data-security-cyber-data-security-online-concept-illustration-internet-security-information-privacy-protection_1150-37336.jpg",
    },
  ];

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
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 20),
                const Text("Buat Baru", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 15),
                ListTile(
                  leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.book, color: Colors.indigo)),
                  title: const Text("Materi & Kuis"),
                  subtitle: const Text("Buat bahan bacaan lengkap dengan kuis"),
                  onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (c) => const AddMateriPage(isQuizOnly: false))); },
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.quiz, color: Colors.orange)),
                  title: const Text("Kuis Saja (Tantangan)"),
                  subtitle: const Text("Hanya soal kuis dengan Kode Unik"),
                  onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (c) => const AddMateriPage(isQuizOnly: true))); },
                ),
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
        actions: [
          TextButton(onPressed: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (c) => AddMateriPage(materi: item, docId: docId, isQuizOnly: item.content.isEmpty))); }, child: const Text("Edit")),
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
        content: const Text("Apakah Anda yakin ingin keluar?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Tutup dialog
            child: const Text("Batal")
          ),
          TextButton(
            onPressed: () async {
              // 1. Tutup Dialog dulu
              Navigator.pop(context); 

              // 2. Panggil Logout
              await AuthService().logout(); 

              // 3. TIDAK PERLU NAVIGASI MANUAL (Navigator.push...)
              // StreamBuilder di main.dart akan mendeteksi user = null
              // dan otomatis melempar Anda ke Login Page dengan mulus.
            }, 
            child: const Text("Keluar", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
      builder: (context, userSnapshot) {
        String userRole = "student";
        String displayName = "Student";
        String photoUrl = "";
        int points = 0;

        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
          userRole = userData['role'] ?? "student";
          displayName = userData['username'] ?? "User";
          photoUrl = userData['photoUrl'] ?? "";
          points = userData['points'] ?? 0;
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),
          floatingActionButton: userRole == 'teacher' 
              ? FloatingActionButton(
                  backgroundColor: const Color(0xFF6A11CB),
                  child: const Icon(Icons.add, color: Colors.white),
                  onPressed: _showCreateOptions,
                )
              : null,

          body: CustomScrollView(
            slivers: [
              _buildSliverAppBar(displayName, points, userRole, photoUrl),
              
              // QUICK MENU
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildQuickMenu(context, Icons.add, "Join Quiz", const Color(0xFF9C27B0), () => Navigator.push(context, MaterialPageRoute(builder: (c) => const JoinQuizPage()))),
                      _buildQuickMenu(context, Icons.bar_chart, "Rank", const Color(0xFF00BFA5), () => Navigator.push(context, MaterialPageRoute(builder: (c) => const LeaderboardPage()))),
                      _buildQuickMenu(context, Icons.emoji_events, "Badge", const Color(0xFFFF7043), () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AchievementsPage()))),
                      _buildQuickMenu(context, Icons.logout, "Logout", Colors.redAccent, _showLogoutDialog),
                    ],
                  ),
                ),
              ),

              // --- JUDUL RAK BUKU ---
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Pustaka Belajar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("Lihat Semua", style: TextStyle(fontSize: 12, color: Colors.blueAccent)),
                    ],
                  ),
                ),
              ),

              // --- WIDGET RAK BUKU HORIZONTAL (TANPA TOMBOL BACA) ---
              _buildBookShelf(), 

              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 25, 20, 10),
                  child: Text("Kelas & Kuis Aktif", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),

              // STREAM 2: GRID MATERI & KUIS
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('materi').orderBy('createdAt', descending: true).snapshots(),
                builder: (context, materiSnapshot) {
                  if (!materiSnapshot.hasData) return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
                  
                  final docs = materiSnapshot.data!.docs;
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
                            id: doc.id, 
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

  // --- WIDGET RAK BUKU HORIZONTAL (UPDATED) ---
  Widget _buildBookShelf() {
    return SliverToBoxAdapter(
      child: Container(
        height: 200, // Tinggi sedikit dikurangi karena tombol hilang
        margin: const EdgeInsets.only(top: 10),
        child: ListView.builder(
          padding: const EdgeInsets.only(left: 20),
          scrollDirection: Axis.horizontal,
          itemCount: bookList.length,
          itemBuilder: (context, index) {
            final book = bookList[index];
            return Container(
              width: 120, // Lebar Buku
              margin: const EdgeInsets.only(right: 15),
              decoration: BoxDecoration(
                color: Colors.transparent, // Background transparan agar rapi
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Gambar Cover (Bagian Atas)
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6, offset: const Offset(2, 4))
                        ],
                        image: DecorationImage(
                          image: NetworkImage(book['cover']!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Judul & Penulis (Tanpa Tombol)
                  Text(
                    book['title']!,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    book['author']!,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(String name, int points, String role, String photoUrl) {
    return SliverAppBar(
      pinned: true, expandedHeight: 140, automaticallyImplyLeading: false, backgroundColor: const Color(0xFF6A11CB),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)])),
          padding: const EdgeInsets.only(top: 50, left: 20, right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const ProfilePage())), 
                  child: CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.white24, 
                    backgroundImage: (photoUrl.isNotEmpty) 
                        ? NetworkImage(photoUrl) 
                        : NetworkImage("https://ui-avatars.com/api/?name=$name&background=random&color=fff"),
                  )
                ),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [const Text("Selamat Datang!", style: TextStyle(color: Colors.white70, fontSize: 12)), Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)), Text(role == 'teacher' ? "(Guru)" : "(Siswa)", style: TextStyle(color: Colors.white70, fontSize: 11))]),
              ]),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)), child: Row(children: [const Icon(Icons.stars, color: Colors.amber, size: 18), const SizedBox(width: 4), Text("$points", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickMenu(BuildContext c, IconData i, String l, Color k, VoidCallback t) { return GestureDetector(onTap: t, child: Column(children: [Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: k, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: k.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]), child: Icon(i, color: Colors.white, size: 24)), const SizedBox(height: 8), Text(l, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600))])); }
}