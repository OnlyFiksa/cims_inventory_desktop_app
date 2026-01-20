import 'package:flutter/material.dart';
import 'package:cims_app/views/dashboard_view.dart';
import 'package:cims_app/services/auth_service.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _nikController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _isPasswordVisible = false;
  bool _isError = false;
  bool _isLoading = false;
  String _errorMessage = "";

  final Color vosenDarkBlue = const Color(0xFF0A2A4D);
  final Color vosenRed = const Color(0xFFD32F2F);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    bool isDesktop = screenWidth > 900;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFFF2F6F9), Color(0xFFD4E4F7)],
          ),
        ),
        child: Row(
          children: [
            if (isDesktop)
              Expanded(
                flex: 5,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(50.0),
                    child: Image.asset(
                      'assets/images/Logo_CIMS.png',
                      width: screenWidth * 0.35,
                      fit: BoxFit.contain,
                      errorBuilder: (c, e, s) => Icon(Icons.science, size: 100, color: vosenDarkBlue),
                    ),
                  ),
                ),
              ),

            Expanded(
              flex: 5,
              child: Padding(
                padding: EdgeInsets.only(top: 25, bottom: 25, right: 25, left: isDesktop ? 40 : 25),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(color: vosenDarkBlue.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 10))],
                  ),
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 50),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset('assets/images/Logo_Vosen.png', height: 60, errorBuilder: (c,e,s) => const SizedBox(height: 60)),
                          const SizedBox(height: 30),
                          Text("SELAMAT DATANG", style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: vosenDarkBlue, letterSpacing: 1.0)),
                          const SizedBox(height: 10),
                          Text("Silahkan Masukkan Data Personal Anda\nUntuk Masuk Ke Halaman Dashboard", textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.5)),
                          const SizedBox(height: 40),

                          TextField(
                            controller: _nikController,
                            decoration: InputDecoration(
                              hintText: "Masukkan Nomor Induk Karyawan",
                              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                              prefixIcon: Icon(Icons.person, color: vosenDarkBlue, size: 24),
                              filled: true,
                              fillColor: const Color(0xFFF7F8FA),
                              contentPadding: const EdgeInsets.symmetric(vertical: 28),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                            ),
                          ),
                          const SizedBox(height: 20),

                          TextField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            decoration: InputDecoration(
                              hintText: "Masukkan Password",
                              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                              prefixIcon: Icon(Icons.lock, color: vosenDarkBlue, size: 24),
                              suffixIcon: IconButton(
                                icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.black, size: 22),
                                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF7F8FA),
                              contentPadding: const EdgeInsets.symmetric(vertical: 28),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                            ),
                          ),

                          Align(alignment: Alignment.centerRight, child: Padding(padding: const EdgeInsets.only(top: 15), child: InkWell(onTap: _showForgotPasswordDialog, child: Text("Lupa password?", style: TextStyle(color: vosenDarkBlue, fontWeight: FontWeight.bold, fontSize: 14))))),

                          const SizedBox(height: 25),

                          if (_isError)
                            Padding(padding: const EdgeInsets.only(bottom: 20), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.error_rounded, color: vosenRed, size: 24), const SizedBox(width: 10), Text(_errorMessage, style: TextStyle(color: vosenRed, fontWeight: FontWeight.bold))])),

                          SizedBox(
                            width: double.infinity, height: 65,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: vosenDarkBlue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                              onPressed: _isLoading ? null : _handleLogin,
                              child: _isLoading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Sign In", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(height: 40),
                          Text("© 2026 PT Vosen Pratita Kemindo", style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    showDialog(context: context, builder: (context) => AlertDialog(title: const Text("Lupa Password?"), content: const Text("Hubungi Supervisor untuk reset password."), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))]));
  }

  Future<void> _handleLogin() async {
    if (_nikController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      setState(() { _isError = true; _errorMessage = "NIK dan Password harus diisi!"; });
      return;
    }

    setState(() { _isLoading = true; _isError = false; });

    final result = await _authService.login(_nikController.text.trim(), _passwordController.text.trim());

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      if (!mounted) return;

      // PERBAIKAN: Gunakan key 'user' bukan 'data'
      String namaUser = result['user']['name'] ?? "User";

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Selamat Datang, $namaUser"), backgroundColor: Colors.green));

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const DashboardView()));
    } else {
      setState(() { _isError = true; _errorMessage = result['message'] ?? "Gagal Login"; });
    }
  }
}