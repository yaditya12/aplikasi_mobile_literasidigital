import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- FUNGSI LOGIN (SUDAH ADA PARAMETER expectedRole) ---
  Future<String?> login({
    required String email, 
    required String password,
    required String expectedRole, // <-- Ini parameter yang sebelumnya hilang
  }) async {
    try {
      // 1. Cek Email & Password di Firebase Auth
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);

      // 2. Ambil data user dari Firestore untuk mengecek rolenya
      DocumentSnapshot doc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
      
      if (doc.exists) {
        String actualRole = doc['role'] ?? 'student';
        
        // 3. Cek apakah role yang dipilih di layar login sesuai dengan database
        if (actualRole != expectedRole) {
          await _auth.signOut(); // Keluarkan paksa jika salah pintu
          String roleName = expectedRole == 'teacher' ? 'Guru' : 'Siswa';
          return "Akses ditolak! Akun ini bukan terdaftar sebagai $roleName.";
        }
      } else {
        await _auth.signOut();
        return "Data pengguna tidak ditemukan di sistem.";
      }

      return "success";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return "Email tidak terdaftar.";
      if (e.code == 'wrong-password') return "Password salah.";
      return e.message;
    } catch (e) {
      return "Terjadi kesalahan: $e";
    }
  }

  // --- FUNGSI REGISTER ---
  Future<String?> register({
    required String email, 
    required String password, 
    required String username,
    required String role, 
    String? nisn, 
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Menyimpan data ke Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'username': username,
        'email': email,
        'role': role, 
        'nisn': nisn ?? "", 
        'points': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'photoUrl': "", 
      });

      return "success";
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Gagal mendaftar: $e";
    }
  }

  // --- FUNGSI LOGOUT ---
  Future<void> logout() async {
    await _auth.signOut();
  }
}