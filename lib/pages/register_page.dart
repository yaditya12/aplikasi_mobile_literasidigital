import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nisnController = TextEditingController(); // Kontroler untuk NIP
  
  String _selectedRole = 'student'; // Default: Siswa
  bool _isLoading = false;

  void _register() async {
    // 1. Validasi input dasar
    if (_usernameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Semua kolom wajib harus diisi!")));
      return;
    }

    // 2. Validasi Khusus Guru (Wajib Isi & Minimal 18 Digit)
    if (_selectedRole == 'teacher') {
      String nip = _nisnController.text.trim();
      
      if (nip.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("NIP wajib diisi untuk Guru!")));
        return;
      }
      
      if (nip.length < 18) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.red, content: Text("NIP Guru tidak valid! Harus terdiri dari 18 digit angka.")));
        return;
      }
    }

    setState(() => _isLoading = true);

    String? result = await AuthService().register(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      username: _usernameController.text.trim(),
      role: _selectedRole,
      nisn: _selectedRole == 'teacher' ? _nisnController.text.trim() : null, // Kirim NIP hanya jika guru
    );

    setState(() => _isLoading = false);

    if (result == "success") {
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const HomePage()), (route) => false);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text(result ?? "Gagal")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Buat Akun Baru"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.person_add_alt_1, size: 80, color: Color(0xFF6A11CB)),
            const SizedBox(height: 20),
            
            // --- INPUT DASAR ---
            TextField(controller: _usernameController, decoration: const InputDecoration(labelText: "Nama Lengkap", border: OutlineInputBorder(), prefixIcon: Icon(Icons.person))),
            const SizedBox(height: 15),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder(), prefixIcon: Icon(Icons.email))),
            const SizedBox(height: 15),
            TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: "Password", border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock))),
            const SizedBox(height: 20),

            // --- PILIHAN ROLE (Siswa / Guru) ---
            const Align(alignment: Alignment.centerLeft, child: Text("Daftar Sebagai:", style: TextStyle(fontWeight: FontWeight.bold))),
            const SizedBox(height: 5),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text("Siswa"),
                    value: 'student',
                    groupValue: _selectedRole,
                    onChanged: (val) {
                      setState(() {
                        _selectedRole = val!;
                        _nisnController.clear(); // Bersihkan field NIP jika pindah ke Siswa
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text("Guru"),
                    value: 'teacher',
                    groupValue: _selectedRole,
                    onChanged: (val) {
                      setState(() {
                        _selectedRole = val!;
                      });
                    },
                  ),
                ),
              ],
            ),
            
            // --- KOLOM NIP (MUNCUL JIKA GURU DIPILIH) ---
            if (_selectedRole == 'teacher') ...[
              const SizedBox(height: 10),
              TextField(
                controller: _nisnController,
                keyboardType: TextInputType.number, // Set keyboard ke angka
                maxLength: 18, // Membatasi inputan maksimal 18 karakter
                decoration: InputDecoration(
                  labelText: "NIP Guru (18 Digit)", 
                  border: const OutlineInputBorder(), 
                  prefixIcon: const Icon(Icons.badge, color: Color(0xFF00BFA5)),
                  filled: true,
                  fillColor: const Color(0xFF00BFA5).withOpacity(0.05),
                  counterText: "", // Menghilangkan teks "0/18" di bawah kotak agar lebih rapi
                )
              ),
              const Padding(
                padding: EdgeInsets.only(top: 5, left: 5),
                child: Align(
                  alignment: Alignment.centerLeft, 
                  child: Text("* Masukkan 18 digit NIP resmi Anda", style: TextStyle(fontSize: 12, color: Colors.red))
                ),
              ),
            ],

            const SizedBox(height: 25),
            
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6A11CB), foregroundColor: Colors.white),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("DAFTAR SEKARANG", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}