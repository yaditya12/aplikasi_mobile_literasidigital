import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import 'home_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Kontroler tetap sama persis seperti milik Anda
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nisnController = TextEditingController(); 
  
  String _selectedRole = 'student'; 
  bool _isLoading = false;
  
  // Tambahan murni untuk fitur mata (tampil/sembunyi) di UI Password
  bool _obscurePassword = true; 

  // --- LOGIKA REGISTER TIDAK DIRUBAH SAMA SEKALI ---
  void _register() async {
    // 1. Validasi input dasar
    if (_usernameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.red, content: Text("Semua kolom wajib harus diisi!")));
      return;
    }

    // 2. Validasi Khusus Guru (Wajib Isi & Minimal 18 Digit)
    if (_selectedRole == 'teacher') {
      String nip = _nisnController.text.trim();
      
      if (nip.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.red, content: Text("NIP wajib diisi untuk Guru!")));
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
    // Tema warna selaras (Ungu untuk Siswa, Tosca untuk Guru)
    Color activeColor = _selectedRole == 'student' ? const Color(0xFF6A11CB) : const Color(0xFF00BFA5);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 0, // Sembunyikan appbar default agar lebih bersih
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tombol Kembali
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
            ),
            const SizedBox(height: 10),

            // Judul dan Subjudul
            Center(
              child: Column(
                children: [
                  const Text("Buat Akun Baru", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black)),
                  const SizedBox(height: 8),
                  Text("Ayo mulai perjalanan belajarmu bersama kami.", textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Colors.black54)),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Ikon Profil Premium (Berubah warna mengikuti role)
            Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: activeColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: activeColor.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.person, size: 55, color: activeColor.withOpacity(0.8)),
                    Positioned(
                      bottom: 15, right: 15,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(color: activeColor, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                        child: const Icon(Icons.add, size: 15, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 35),

            // --- INPUT DASAR ---
            _buildTextField(controller: _usernameController, hintText: "Nama Lengkap", icon: Icons.person_outline, activeColor: activeColor),
            const SizedBox(height: 16),
            _buildTextField(controller: _emailController, hintText: "Email", icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress, activeColor: activeColor),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _passwordController, hintText: "Password", icon: Icons.lock_outline, activeColor: activeColor, obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey), 
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword)
              ),
            ),
            const SizedBox(height: 30),

            // --- PILIHAN ROLE (Siswa / Guru) ---
            const Text("Daftar Sebagai:", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 15),
            Row(
              children: [
                _buildRoleOptionCard("Siswa", 'student', Icons.school_outlined, activeColor),
                const SizedBox(width: 15),
                _buildRoleOptionCard("Guru", 'teacher', Icons.person_search_outlined, activeColor),
              ],
            ),
            
            // --- KOLOM NIP (MUNCUL JIKA GURU DIPILIH) ---
            if (_selectedRole == 'teacher') ...[
              const SizedBox(height: 25),
              // Animasi muncul yang halus
              AnimatedOpacity(
                opacity: _selectedRole == 'teacher' ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(
                      controller: _nisnController, 
                      hintText: "NIP Guru (18 Digit)", 
                      icon: Icons.badge_outlined, 
                      activeColor: activeColor,
                      keyboardType: TextInputType.number,
                      maxLength: 18,
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 8, left: 10),
                      child: Text("* Masukkan 18 digit NIP resmi Anda", style: TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 35),

            // --- TOMBOL DAFTAR ---
            _buildGradientButton(activeColor),
            const SizedBox(height: 20),

            Center(child: Text("Dengan mendaftar, Anda menyetujui Ketentuan Layanan kami.", textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.5)))),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // WIDGET HELPER UNTUK DESAIN (TIDAK MERUBAH LOGIKA)
  // =========================================================================

  Widget _buildTextField({
    required TextEditingController controller, required String hintText, required IconData icon, required Color activeColor,
    TextInputType? keyboardType, bool obscureText = false, Widget? suffixIcon, int? maxLength
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller, 
        keyboardType: keyboardType, 
        obscureText: obscureText,
        maxLength: maxLength,
        inputFormatters: keyboardType == TextInputType.number ? [FilteringTextInputFormatter.digitsOnly] : [],
        decoration: InputDecoration(
          counterText: "", // Menghilangkan teks 0/18 di bawah input NIP
          hintText: hintText, 
          prefixIcon: Icon(icon, color: activeColor.withOpacity(0.7)),
          suffixIcon: suffixIcon, 
          border: InputBorder.none, 
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          hintStyle: TextStyle(color: Colors.black.withOpacity(0.3), fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildRoleOptionCard(String title, String roleValue, IconData icon, Color activeColor) {
    bool isSelected = _selectedRole == roleValue;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedRole = roleValue;
            // Logika asli Anda: Bersihkan NIP jika balik ke Siswa
            if (roleValue == 'student') {
              _nisnController.clear(); 
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: isSelected ? activeColor : Colors.grey.shade200, width: 2),
            boxShadow: [if (isSelected) BoxShadow(color: activeColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? Colors.white : activeColor, size: 22),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black87)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradientButton(Color activeColor) {
    return GestureDetector(
      onTap: _isLoading ? null : _register,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        height: 55,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: activeColor, // Solid color menyesuaikan tema (Siswa/Guru)
          boxShadow: [BoxShadow(color: activeColor.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6))],
        ),
        alignment: Alignment.center,
        child: _isLoading 
          ? const SizedBox(height: 25, width: 25, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
          : const Text("DAFTAR SEKARANG", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2)),
      ),
    );
  }
}