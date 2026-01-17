import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditProfilePage extends StatefulWidget {
  final String currentUsername;
  final String currentEmail;

  const EditProfilePage({
    super.key, 
    required this.currentUsername, 
    required this.currentEmail
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Isi form dengan data lama yang dikirim dari halaman sebelumnya
    _usernameController = TextEditingController(text: widget.currentUsername);
    _emailController = TextEditingController(text: widget.currentEmail);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // Fungsi Simpan Perubahan
  void _saveProfile() async {
    if (_usernameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Username tidak boleh kosong")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;

      // Update data di Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'username': _usernameController.text.trim(),
        // Email biasanya tidak diupdate di sini karena butuh verifikasi ulang auth
        // Jadi kita hanya update username saja
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.green, content: Text("Profil berhasil diperbarui!")),
      );

      Navigator.pop(context); // Kembali ke halaman profil

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text("Gagal update: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Edit Profil"),
        backgroundColor: const Color(0xFF6A11CB),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Avatar Preview (Akan berubah real-time saat mengetik jika mau, tapi ini statis dulu)
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.indigo.shade50,
              backgroundImage: NetworkImage(
                "https://ui-avatars.com/api/?name=${_usernameController.text}&background=random&size=128&color=fff"
              ),
            ),
            const SizedBox(height: 30),

            // Input Username
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: "Username",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.person, color: Colors.indigo),
              ),
            ),
            const SizedBox(height: 20),

            // Input Email (Read Only / Tidak bisa diedit sembarangan)
            TextField(
              controller: _emailController,
              readOnly: true, // Email dikunci
              style: const TextStyle(color: Colors.grey),
              decoration: InputDecoration(
                labelText: "Email (Tidak dapat diubah)",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.email, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
            
            const SizedBox(height: 40),

            // Tombol Simpan
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00BFA5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("SIMPAN PERUBAHAN", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}