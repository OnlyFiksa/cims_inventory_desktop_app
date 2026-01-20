import 'package:flutter/material.dart';
import 'package:cims_app/views/splash_view.dart'; // IMPORT SPLASH VIEW DI SINI
import 'package:cims_app/views/login_view.dart'; // Import LoginView

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CIMS PT Vosen',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0A2A4D)),
        useMaterial3: true,
        // Mengatur font default aplikasi (opsional, biar lebih mirip desain)
        fontFamily: 'Roboto',
      ),
      // GANTI HOME MENJADI SPLASHVIEW
      home: const SplashView(),
    );
  }
}