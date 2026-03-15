import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageSimulationPage extends StatefulWidget {
  const ManageSimulationPage({super.key});

  @override
  State<ManageSimulationPage> createState() => _ManageSimulationPageState();
}

class _ManageSimulationPageState extends State<ManageSimulationPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Form Controllers
  final _typeController = TextEditingController();
  final _contentController = TextEditingController();
  final _explanationController = TextEditingController();
  bool _isSafe = false;

  // Fungsi untuk memunculkan Popup Form Tambah Kasus
  void _showAddDialog() {
    _typeController.clear();
    _contentController.clear();
    _explanationController.clear();
    _isSafe = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)), // Ujung melengkung modern
            backgroundColor: Colors.white,
            title: const Column(
              children: [
                Icon(Icons.security, size: 50, color: Color(0xFF00BFA5)),
                SizedBox(height: 10),
                Text("Tambah Kasus Baru", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Lengkapi form di bawah ini untuk membuat soal simulasi literasi digital.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 20),
                  
                  // INPUT JENIS
                  _buildInput(_typeController, "Jenis (Misal: Email, SMS)", Icons.category_outlined),
                  const SizedBox(height: 15),
                  
                  // INPUT KONTEN
                  _buildInput(_contentController, "Isi Pesan/Konten Simulasi", Icons.message_outlined, maxLines: 3),
                  const SizedBox(height: 15),
                  
                  // KOTAK SAKELAR AMAN/BAHAYA (ANTI OVERFLOW)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: _isSafe ? Colors.green.shade50 : Colors.red.shade50,
                      border: Border.all(color: _isSafe ? Colors.green.shade300 : Colors.red.shade300, width: 2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: SwitchListTile(
                      title: const Text("Status Konten", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        _isSafe ? "AMAN (Fakta/Resmi)" : "BAHAYA (Hoaks/Phishing)", 
                        style: TextStyle(color: _isSafe ? Colors.green.shade700 : Colors.red.shade700, fontWeight: FontWeight.bold)
                      ),
                      value: _isSafe,
                      activeColor: Colors.green,
                      inactiveThumbColor: Colors.red,
                      inactiveTrackColor: Colors.red.shade200,
                      onChanged: (val) => setStateDialog(() => _isSafe = val),
                    ),
                  ),

                  const SizedBox(height: 15),
                  
                  // INPUT PENJELASAN
                  _buildInput(_explanationController, "Penjelasan Lengkap Jawaban", Icons.info_outline, maxLines: 3),
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
            actionsAlignment: MainAxisAlignment.spaceEvenly,
            actions: [
              // TOMBOL BATAL
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: const BorderSide(color: Colors.grey),
                ),
                child: const Text("Batal", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
              // TOMBOL SIMPAN
              ElevatedButton(
                onPressed: () async {
                  if (_typeController.text.isEmpty || _contentController.text.isEmpty || _explanationController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Harap lengkapi semua kolom!"), backgroundColor: Colors.red));
                    return; 
                  }
                  
                  // Simpan ke Firebase Database
                  await _firestore.collection('simulations').add({
                    'type': _typeController.text.trim(),
                    'content': _contentController.text.trim(),
                    'isSafe': _isSafe,
                    'explanation': _explanationController.text.trim(),
                    'createdAt': FieldValue.serverTimestamp(),
                  });

                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kasus berhasil ditambahkan!"), backgroundColor: Colors.green));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00BFA5),
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("SIMPAN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        }
      ),
    );
  }

  // Fungsi Hapus Kasus
  void _deleteCase(String docId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Kasus?"),
        content: const Text("Tindakan ini tidak bisa dibatalkan."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _firestore.collection('simulations').doc(docId).delete();
            }, 
            child: const Text("Hapus", style: TextStyle(color: Colors.red))
          ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Kelola Simulasi Kasus", style: TextStyle(fontWeight: FontWeight.bold)), 
        backgroundColor: const Color(0xFF00BFA5),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: const Color(0xFF00BFA5),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Tambah Kasus", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('simulations').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFF00BFA5)));
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.network("https://img.freepik.com/free-vector/no-data-concept-illustration_114360-536.jpg", height: 200),
                  const SizedBox(height: 20),
                  const Text("Belum ada kasus simulasi.", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const Text("Klik tombol tambah di bawah untuk membuat.", style: TextStyle(color: Colors.grey)),
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
              bool isSafe = data['isSafe'] ?? false;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(15),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: isSafe ? Colors.green.shade50 : Colors.red.shade50, shape: BoxShape.circle),
                    child: Icon(isSafe ? Icons.gpp_good : Icons.warning_amber_rounded, color: isSafe ? Colors.green : Colors.red, size: 28),
                  ),
                  title: Text(data['type'] ?? 'Tanpa Judul', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text('"${data['content']}"', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontStyle: FontStyle.italic)),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _deleteCase(docId),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- WIDGET HELPER UNTUK MEMBUAT KOTAK INPUT TEXT ---
  Widget _buildInput(TextEditingController controller, String label, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: maxLines > 1,
        prefixIcon: Icon(icon, color: const Color(0xFF00BFA5)),
        filled: true,
        fillColor: Colors.grey.shade50,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF00BFA5), width: 2)),
      ),
    );
  }
}