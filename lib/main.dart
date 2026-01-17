import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Auth untuk cek status login
import 'firebase_options.dart';

// Import Halaman
import 'pages/login_page.dart';
import 'pages/home_page.dart';

void main() async {
  // 1. Pastikan binding flutter terinisialisasi
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inisialisasi Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. Jalankan App (dengan DevicePreview)
  runApp(
    DevicePreview(
      enabled: true, // Ubah ke false jika build untuk rilis/HP asli
      builder: (context) => const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Literasi Digital',
      
      // Konfigurasi DevicePreview
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,

      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),

      // LOGIKA AUTO-LOGIN (PENTING)
      // StreamBuilder memantau status login secara real-time
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // A. Jika sedang memuat status login
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // B. Jika User ditemukan (Sudah Login) -> Ke HomePage
          if (snapshot.hasData) {
            return const HomePage();
          }

          // C. Jika User tidak ditemukan (Belum Login) -> Ke LoginPage
          return const LoginPage();
        },
      ),

      // Routes tetap ada untuk navigasi manual jika diperlukan
      routes: {
        "/login": (context) => const LoginPage(),
        "/home": (context) => const HomePage(),
      },
    );
  }
}