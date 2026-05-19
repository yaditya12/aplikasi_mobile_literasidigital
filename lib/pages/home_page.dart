import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart'; 

import '../data/materi.dart'; 
import '../services/auth_service.dart';

import 'materi_page.dart';
import 'leaderboard_page.dart'; 
import 'achievements_page.dart';
import 'add_materi_page.dart'; 
import 'profile_page.dart'; 
import 'join_quiz_page.dart'; 
import 'login_page.dart'; 

import 'simulation_page.dart';
import 'manage_simulation_page.dart';
import 'video_page.dart'; 
import 'upload_materi_link_page.dart'; 

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  // --- MENU PILIHAN BUAT BARU ---
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
                const Text("Buat Kelas / Kuis Baru", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 15),
                
                ListTile(
                  leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.book, color: Colors.indigo)),
                  title: const Text("Teks Materi & Kuis"),
                  subtitle: const Text("Ketik bahan bacaan dan kuis di aplikasi"),
                  onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (c) => const AddMateriPage(isQuizOnly: false))); },
                ),
                const Divider(),

                ListTile(
                  leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.quiz, color: Colors.orange)),
                  title: const Text("Kuis Saja (Tantangan)"),
                  subtitle: const Text("Hanya buat kuis dengan Kode Unik"),
                  onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (c) => const AddMateriPage(isQuizOnly: true))); },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- LOGIKA EDIT & HAPUS MATERI INTERNAL ---
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

  // --- LOGOUT ---
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Apakah Anda yakin ingin keluar?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); 
              await AuthService().logout(); 
            }, 
            child: const Text("Keluar", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }

  // --- POPUP BUKA LINK MATERI (GOOGLE DRIVE/PDF) ---
  void _showMateriDialog(String docId, String title, String type, String userRole, String coverUrl, String link) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.network(
                coverUrl.isNotEmpty ? coverUrl : 'https://img.freepik.com/free-vector/online-education-concept_23-2148532793.jpg', 
                height: 160, width: double.infinity, fit: BoxFit.cover
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(10)),
                    child: Text(type, style: TextStyle(color: Colors.indigo.shade700, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    userRole == 'teacher' ? "Anda dapat memproyeksikan materi ini di kelas atau menghapusnya." : "Materi ini akan dibuka di browser/aplikasi Anda.",
                    textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 25),
                  Row(
                    children: [
                      if (userRole == 'teacher') ...[
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: const BorderSide(color: Colors.redAccent)),
                            onPressed: () {
                              Navigator.pop(context);
                              FirebaseFirestore.instance.collection('materi_siap_pakai').doc(docId).delete();
                            }, 
                            child: const Text("Hapus", style: TextStyle(color: Colors.redAccent))
                          )
                        ),
                        const SizedBox(width: 10),
                      ],
                      if (userRole != 'teacher') ...[
                         Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            onPressed: () => Navigator.pop(context), 
                            child: const Text("Batal", style: TextStyle(color: Colors.grey))
                          )
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: userRole == 'teacher' ? const Color(0xFF00BFA5) : const Color(0xFF6A11CB), 
                            padding: const EdgeInsets.symmetric(vertical: 12), 
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                          ),
                          onPressed: () async {
                            Navigator.pop(context); 
                            final Uri url = Uri.parse(link);
                            if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tidak dapat membuka link tersebut")));
                            }
                          },
                          child: Text(userRole == 'teacher' ? "Buka Materi" : "Buka", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        )
                      ),
                    ],
                  )
                ],
              ),
            )
          ],
        )
      )
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

        // --- WARNA DINAMIS MENYESUAIKAN ROLE ---
        Color primaryColor = userRole == 'teacher' ? const Color(0xFF00BFA5) : const Color(0xFF6A11CB);
        Color gradientEndColor = userRole == 'teacher' ? const Color(0xFF00897B) : const Color(0xFF2575FC);

        return Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),
          floatingActionButton: userRole == 'teacher' 
              ? FloatingActionButton(
                  backgroundColor: primaryColor,
                  child: const Icon(Icons.add, color: Colors.white),
                  onPressed: _showCreateOptions,
                )
              : null,

          body: CustomScrollView(
            slivers: [
              // APP BAR DENGAN JARAK YANG LEBIH RAPI & LEGA
              _buildSliverAppBar(displayName, points, userRole, photoUrl, primaryColor, gradientEndColor),
              
              // --- QUICK MENU ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 25),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildQuickMenu(context, Icons.add, "Join Quiz", const Color(0xFF9C27B0), () => Navigator.push(context, MaterialPageRoute(builder: (c) => const JoinQuizPage()))),
                        const SizedBox(width: 15),
                        _buildQuickMenu(context, Icons.bar_chart, "Rank", const Color(0xFF00BFA5), () => Navigator.push(context, MaterialPageRoute(builder: (c) => const LeaderboardPage()))),
                        const SizedBox(width: 15),
                        _buildQuickMenu(context, Icons.emoji_events, "Badge", const Color(0xFFFF7043), () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AchievementsPage()))),
                        const SizedBox(width: 15),
                        _buildQuickMenu(context, Icons.security, "Simulasi", Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (c) => const SimulationPage()))),
                        const SizedBox(width: 15),
                        _buildQuickMenu(context, Icons.play_circle_fill, "Video", Colors.redAccent, () => Navigator.push(context, MaterialPageRoute(builder: (c) => const VideoPage()))),
                        
                        if (userRole == 'teacher') ...[
                          const SizedBox(width: 15),
                          _buildQuickMenu(context, Icons.edit_document, "Kelola", Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (c) => const ManageSimulationPage()))),
                        ],
                        
                        const SizedBox(width: 15),
                        _buildQuickMenu(context, Icons.logout, "Logout", Colors.redAccent, _showLogoutDialog),
                      ],
                    ),
                  ),
                ),
              ),

              // --- JUDUL RUANG GURU ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(userRole == 'teacher' ? "Ruang Guru: Materi Eksternal" : "Materi Literasi Tambahan", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),

              // --- WIDGET RAK MATERI DARI DATABASE ---
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('materi_siap_pakai').orderBy('createdAt', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
                  
                  final docs = snapshot.hasData ? snapshot.data!.docs : [];

                  if (docs.isEmpty && userRole != 'teacher') {
                    return const SliverToBoxAdapter(
                      child: SizedBox(
                        height: 150,
                        child: Center(child: Text("Belum ada materi tambahan dari guru.", style: TextStyle(color: Colors.grey))),
                      ),
                    );
                  }

                  int itemCount = userRole == 'teacher' ? docs.length + 1 : docs.length;

                  return SliverToBoxAdapter(
                    child: Container(
                      height: 220, 
                      margin: const EdgeInsets.only(top: 10),
                      child: ListView.builder(
                        padding: const EdgeInsets.only(left: 20),
                        scrollDirection: Axis.horizontal,
                        itemCount: itemCount,
                        itemBuilder: (context, index) {
                          
                          if (userRole == 'teacher' && index == 0) {
                            return GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const UploadMateriLinkPage())),
                              child: Container(
                                width: 130, 
                                margin: const EdgeInsets.only(right: 15),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(color: primaryColor, width: 1.5, style: BorderStyle.solid),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_circle, size: 45, color: primaryColor),
                                    const SizedBox(height: 10),
                                    Text("Tambah\nMateri Baru", textAlign: TextAlign.center, style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 13)),
                                  ],
                                ),
                              ),
                            );
                          }

                          int dataIndex = userRole == 'teacher' ? index - 1 : index;
                          var materi = docs[dataIndex].data() as Map<String, dynamic>;
                          String docId = docs[dataIndex].id;
                          
                          return GestureDetector(
                            onTap: () => _showMateriDialog(docId, materi['title'] ?? 'Tanpa Judul', materi['type'] ?? 'Materi', userRole, materi['cover'] ?? '', materi['link'] ?? ''),
                            child: Container(
                              width: 130, 
                              margin: const EdgeInsets.only(right: 15),
                              decoration: const BoxDecoration(color: Colors.transparent),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6, offset: const Offset(2, 4))],
                                        image: DecorationImage(image: NetworkImage(materi['cover'] ?? 'https://img.freepik.com/free-vector/online-education-concept_23-2148532793.jpg'), fit: BoxFit.cover),
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withOpacity(0.6), Colors.transparent])
                                        ),
                                        alignment: Alignment.bottomCenter,
                                        padding: const EdgeInsets.all(8),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.link, color: Colors.white, size: 14),
                                            const SizedBox(width: 4),
                                            Expanded(child: Text(materi['type'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(materi['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),

              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 25, 20, 10),
                  child: Text("Kelas & Kuis Interaktif", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),

              // --- STREAM 2: GRID MATERI INTERNAL & KUIS ---
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('materi').orderBy('createdAt', descending: true).snapshots(),
                builder: (context, materiSnapshot) {
                  if (!materiSnapshot.hasData) return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
                  
                  final docs = materiSnapshot.data!.docs;
                  if (docs.isEmpty) return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Belum ada materi kelas."))));

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

  // ===========================================================================
  // WIDGET APP BAR BARU DENGAN IDENTITAS (BUKU) & JARAK YANG LEGA
  // ===========================================================================
  Widget _buildSliverAppBar(String name, int points, String role, String photoUrl, Color primaryColor, Color gradientEnd) {
    return SliverAppBar(
      pinned: true, 
      // 1. Tinggi diperbesar dari 170 ke 200 agar ada ruang lega
      expandedHeight: 200, 
      automaticallyImplyLeading: false, 
      backgroundColor: primaryColor,
      
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            // MENGGANTI IKON ROKET MENJADI BUKU DI SINI
            child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Text(
            "ZonaDigi",
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Colors.white, letterSpacing: 1.2),
          ),
        ],
      ),
      centerTitle: false,

      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, gradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          ),
          // 2. Padding atas (top) diturunkan dari 95 ke 125 agar profil menjauh dari logo
          padding: const EdgeInsets.only(top: 125, left: 20, right: 20), 
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Selamat Datang!", style: TextStyle(color: Colors.white70, fontSize: 12)), 
                    Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)), 
                    Text(role == 'teacher' ? "(Guru)" : "(Siswa)", style: const TextStyle(color: Colors.white70, fontSize: 11))
                  ]
                ),
              ]),
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), 
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)), 
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars, color: Colors.amber, size: 18), 
                    const SizedBox(width: 4), 
                    Text("$points", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                  ]
                )
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickMenu(BuildContext c, IconData i, String l, Color k, VoidCallback t) { 
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: t, 
      child: SizedBox(
        width: 65,
        child: Column(
          children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: k, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: k.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]), child: Icon(i, color: Colors.white, size: 24)), 
            const SizedBox(height: 8), 
            Text(l, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis)
          ]
        ),
      )
    ); 
  }
}