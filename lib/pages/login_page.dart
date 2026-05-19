import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _selectedRole = 'student'; 

  void _login() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.red, content: Text("Email dan password harus diisi")));
      return;
    }

    setState(() => _isLoading = true);

    String? result = await AuthService().login(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      expectedRole: _selectedRole, 
    );

    setState(() => _isLoading = false);

    if (result == "success") {
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const HomePage()), (route) => false);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text(result ?? "Login gagal")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    Color activeColor = _selectedRole == 'student' ? const Color(0xFF6A11CB) : const Color(0xFF00BFA5);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  height: size.height * 0.45,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [activeColor, activeColor.withOpacity(0.7)], 
                      begin: Alignment.topLeft, 
                      end: Alignment.bottomRight
                    ),
                    borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(100)),
                  ),
                ),
                Positioned(
                  top: 0, left: 0, right: 0, bottom: 50,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // LOGO BUKU
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2), 
                            shape: BoxShape.circle, 
                            border: Border.all(color: Colors.white.withOpacity(0.5), width: 2)
                          ),
                          child: const Icon(Icons.menu_book_rounded, size: 60, color: Colors.white), 
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          "ZonaDigi", 
                          style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 2.0)
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _selectedRole == 'student' ? "Portal Siswa" : "Portal Guru", 
                          style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Transform.translate(
                offset: const Offset(0, -60),
                child: Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: const Offset(0, 10))]),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(15)),
                        child: Row(
                          children: [
                            Expanded(child: _buildRoleTab("Siswa", 'student', activeColor)),
                            Expanded(child: _buildRoleTab("Guru", 'teacher', activeColor)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      _buildInput(_emailController, "Email", Icons.email_outlined, activeColor),
                      const SizedBox(height: 20),
                      _buildInput(_passwordController, "Password", Icons.lock_outline, activeColor, isPassword: true),
                      const SizedBox(height: 25),
                      SizedBox(
                        width: double.infinity, height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(backgroundColor: activeColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                          child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("MASUK", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Belum punya akun? ", style: TextStyle(color: Colors.grey)),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterPage())),
                  child: Text("Daftar Sekarang", style: TextStyle(color: activeColor, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleTab(String title, String role, Color activeColor) {
    bool isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.grey.shade600, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String hint, IconData icon, Color activeColor, {bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade200)),
      child: TextField(
        controller: ctrl,
        obscureText: isPassword && _obscurePassword,
        decoration: InputDecoration(
          hintText: hint, border: InputBorder.none, prefixIcon: Icon(icon, color: activeColor.withOpacity(0.7)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          suffixIcon: isPassword 
            ? IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)) 
            : null,
        ),
      ),
    );
  }
}