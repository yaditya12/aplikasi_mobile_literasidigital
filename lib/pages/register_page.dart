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
  
  // Variabel untuk Pilihan Role
  String _selectedRole = 'student'; // Default: Siswa

  bool _isLoading = false;

  void _register() async {
    if (_usernameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Semua kolom harus diisi")));
      return;
    }

    setState(() => _isLoading = true);

    String? result = await AuthService().register(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      username: _usernameController.text.trim(),
      role: _selectedRole, // Kirim role yang dipilih
    );

    setState(() => _isLoading = false);

    if (result == "success") {
      if (!mounted) return;
      // Berhasil, langsung masuk ke Home
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const HomePage()), (route) => false);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text(result ?? "Gagal")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Buat Akun Baru")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.person_add_alt_1, size: 80, color: Color(0xFF6A11CB)),
            const SizedBox(height: 20),
            
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
                    onChanged: (val) => setState(() => _selectedRole = val!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text("Guru"),
                    value: 'teacher',
                    groupValue: _selectedRole,
                    onChanged: (val) => setState(() => _selectedRole = val!),
                  ),
                ),
              ],
            ),
            
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