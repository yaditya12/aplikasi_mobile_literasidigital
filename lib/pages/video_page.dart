import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class VideoPage extends StatefulWidget {
  const VideoPage({super.key});

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? currentUser = FirebaseAuth.instance.currentUser;
  String _userRole = 'student';

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  // Mengecek apakah yang login Guru atau Siswa
  void _checkRole() async {
    if (currentUser != null) {
      var doc = await _firestore.collection('users').doc(currentUser!.uid).get();
      if (doc.exists && mounted) {
        setState(() {
          _userRole = doc.data()?['role'] ?? 'student';
        });
      }
    }
  }

  // Dialog untuk Guru Menambahkan Video Baru
  void _showAddVideoDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final linkCtrl = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.video_library, color: Colors.redAccent),
                SizedBox(width: 10),
                Text("Tambah Video", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: "Judul Video", prefixIcon: Icon(Icons.title))),
                  const SizedBox(height: 10),
                  TextField(controller: descCtrl, decoration: const InputDecoration(labelText: "Deskripsi Singkat", prefixIcon: Icon(Icons.description)), maxLines: 2),
                  const SizedBox(height: 10),
                  TextField(controller: linkCtrl, decoration: const InputDecoration(labelText: "Link YouTube (https://...)", prefixIcon: Icon(Icons.link))),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: isLoading ? null : () async {
                  if (titleCtrl.text.isEmpty || linkCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Judul dan Link wajib diisi!")));
                    return;
                  }
                  
                  setStateDialog(() => isLoading = true);
                  
                  await _firestore.collection('videos').add({
                    'title': titleCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                    'link': linkCtrl.text.trim(),
                    'createdAt': FieldValue.serverTimestamp(),
                  });

                  if (!mounted) return;
                  Navigator.pop(context);
                },
                child: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)) : const Text("Bagikan", style: TextStyle(color: Colors.white)),
              )
            ],
          );
        }
      )
    );
  }

  // Fungsi Hapus Video (Hanya Guru)
  void _deleteVideo(String docId) async {
    await _firestore.collection('videos').doc(docId).delete();
  }

  // Fungsi Membuka Link Video
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tidak dapat membuka link video")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Modul Video Interaktif", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: _userRole == 'teacher' 
        ? FloatingActionButton.extended(
            onPressed: _showAddVideoDialog,
            backgroundColor: Colors.redAccent,
            icon: const Icon(Icons.add_to_queue, color: Colors.white),
            label: const Text("Upload Video", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        : null,
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('videos').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.redAccent));
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.ondemand_video, size: 80, color: Colors.grey),
                  SizedBox(height: 15),
                  Text("Belum ada video pembelajaran.", style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              )
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              String docId = docs[index].id;

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Column(
                  children: [
                    // Tampilan Ala YouTube Thumbnail (Sederhana)
                    Container(
                      height: 120,
                      decoration: const BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
                      ),
                      child: Center(
                        child: IconButton(
                          iconSize: 60,
                          icon: const Icon(Icons.play_circle_fill, color: Colors.redAccent),
                          onPressed: () => _launchURL(data['link'] ?? ''),
                        ),
                      ),
                    ),
                    ListTile(
                      contentPadding: const EdgeInsets.all(15),
                      title: Text(data['title'] ?? 'Tanpa Judul', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(data['description'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                      ),
                      trailing: _userRole == 'teacher' 
                        ? IconButton(icon: const Icon(Icons.delete, color: Colors.grey), onPressed: () => _deleteVideo(docId))
                        : null,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}