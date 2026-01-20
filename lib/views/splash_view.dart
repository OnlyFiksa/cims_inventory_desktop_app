import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cims_app/views/login_view.dart'; // Pastikan path ini benar

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  final Color vosenDarkBlue = const Color(0xFF0A2A4D);

  @override
  void initState() {
    super.initState();
    _startSplashScreen();
  }

  void _startSplashScreen() {
    var duration = const Duration(seconds: 4); // Durasi Tampil Logo
    // Setelah 4 detik, langsung jalankan fungsi _navigateToLogin
    Timer(duration, _navigateToLogin);
  }

  // LOGIKA BARU: TIDAK CEK SESSION, LANGSUNG KE LOGIN
  void _navigateToLogin() {
    if (!mounted) return;

    // Selalu arahkan ke LoginView, memaksa user login setiap buka aplikasi
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginView())
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. LOGO LENGKAP
            Image.asset(
              'assets/images/Logo_CIMS.png',
              width: screenWidth > 600 ? 500 : screenWidth * 0.8,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.science, size: 100, color: vosenDarkBlue);
              },
            ),

            const SizedBox(height: 80),

            // 2. LOADING BAR BIRU
            Container(
              width: screenWidth > 600 ? 400 : screenWidth * 0.7,
              height: 4,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
              ),
              child: LinearProgressIndicator(
                backgroundColor: Colors.blue[50],
                valueColor: AlwaysStoppedAnimation<Color>(vosenDarkBlue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}