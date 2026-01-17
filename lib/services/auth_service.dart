import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  // Instance Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- FUNGSI DAFTAR (REGISTER) ---
  // Sekarang menerima parameter 'role' (teacher/student)
  Future<String> registerUser({
    required String email,
    required String password,
    required String username,
    required String role, // <--- Parameter Baru ditambahkan
  }) async {
    try {
      // 1. Buat Akun di Authentication
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Simpan Data Profil ke Firestore
      String uid = userCredential.user!.uid;

      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'username': username,
        'email': email,
        'points': 0,        // Poin awal
        'role': role,       // <--- Simpan role yang dipilih (teacher/student)
        'createdAt': FieldValue.serverTimestamp(), // Gunakan server timestamp agar akurat
      });

      return "success";
    } on FirebaseAuthException catch (e) {
      // Menangani error spesifik dari Firebase
      return e.message ?? "Gagal mendaftar";
    } catch (e) {
      return "Terjadi kesalahan: $e";
    }
  }

  // --- FUNGSI LOGIN ---
  Future<String> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return "success";
    } on FirebaseAuthException catch (e) {
      return e.message ?? "Login gagal";
    }
  }

  // --- FUNGSI LOGOUT ---
  Future<void> logout() async {
    await _auth.signOut();
  }

  // --- (OPSIONAL) FUNGSI CEK ROLE ---
  // Berguna nanti jika Anda ingin menyembunyikan tombol "Tambah Materi" untuk murid
  Future<String> getUserRole() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return doc['role'] ?? "student";
      }
    }
    return "student";
  }
}