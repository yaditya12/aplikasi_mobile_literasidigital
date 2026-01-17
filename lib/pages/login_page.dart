import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  
  // Variable to store the selected role (Default: student)
  String _selectedRole = "student"; 

  void _submit() async {
    // 1. Validate Input
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.orange,
          content: Text("Email and Password cannot be empty"),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    String result;

    // 2. Logic Branching
    if (_isLogin) {
      // --- LOGIN ---
      // Login doesn't need to send role, it will be checked after login
      result = await AuthService().loginUser(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } else {
      // --- REGISTER ---
      if (_usernameController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Username is required")),
        );
        setState(() => _isLoading = false);
        return;
      }

      // Call registerUser WITH the selected role
      result = await AuthService().registerUser(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        username: _usernameController.text.trim(),
        role: _selectedRole, // <--- IMPORTANT: Sending the role (teacher/student)
      );
    }

    if (mounted) setState(() => _isLoading = false);

    // 3. Handle Result
    if (result == "success") {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text(_isLogin ? "Login Successful!" : "Account $_selectedRole Created!"),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(result),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon Changes Based on Role
              Icon(
                _selectedRole == "teacher" ? Icons.school_rounded : Icons.person_rounded, 
                size: 80, 
                color: _selectedRole == "teacher" ? Colors.orange : Colors.indigo
              ),
              const SizedBox(height: 20),

              Text(
                _isLogin ? "Welcome Back" : "Create New Account",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: _selectedRole == "teacher" ? Colors.orange : Colors.indigo,
                ),
              ),
              const SizedBox(height: 10),
              
              // --- ROLE SELECTION (Teacher / Student) ---
              // Only appears during Registration
              if (!_isLogin)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      // Student Button
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedRole = "student"),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedRole == "student" ? Colors.indigo : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              "Student",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _selectedRole == "student" ? Colors.white : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Teacher Button
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedRole = "teacher"),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedRole == "teacher" ? Colors.orange : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              "Teacher",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _selectedRole == "teacher" ? Colors.white : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (!_isLogin)
                Column(
                  children: [
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: "Full Name",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 15),
                  ],
                ),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedRole == "teacher" ? Colors.orange : Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _isLogin ? "LOGIN" : "REGISTER",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isLogin ? "Don't have an account? " : "Already have an account? ",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isLogin = !_isLogin;
                        _usernameController.clear();
                        _emailController.clear();
                        _passwordController.clear();
                      });
                    },
                    child: Text(
                      _isLogin ? "Register Now" : "Login",
                      style: TextStyle(
                        color: _selectedRole == "teacher" ? Colors.orange : Colors.indigo,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}