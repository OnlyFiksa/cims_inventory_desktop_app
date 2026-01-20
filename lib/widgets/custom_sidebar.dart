import 'package:flutter/material.dart';
import 'package:cims_app/views/dashboard_view.dart';
import 'package:cims_app/views/login_view.dart';
import 'package:cims_app/views/master/master_menu_view.dart';
import 'package:cims_app/views/transaction/transaction_view.dart';
import 'package:cims_app/views/user_management/user_management_view.dart';
import 'package:cims_app/views/report/report_view.dart';
import 'package:cims_app/services/auth_service.dart';

// UBAH JADI STATEFUL WIDGET (Agar bisa load data Role)
class CustomSidebar extends StatefulWidget {
  final String activeMenu;

  const CustomSidebar({super.key, required this.activeMenu});

  @override
  State<CustomSidebar> createState() => _CustomSidebarState();
}

class _CustomSidebarState extends State<CustomSidebar> {
  // STATE UNTUK MENYIMPAN ROLE
  String _userRole = "";

  @override
  void initState() {
    super.initState();
    _loadUserRole(); // Panggil fungsi load saat widget dibuat
  }

  // LOGIC AMBIL ROLE DARI SESSION
  void _loadUserRole() async {
    final authService = AuthService();
    final userData = await authService.getUserSession();
    if (mounted) {
      setState(() {
        // Paksa lowercase agar "Supervisor" terbaca sama dengan "supervisor"
        _userRole = (userData['role'] ?? "").toString().toLowerCase();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Warna Corporate
    final Color vosenDarkBlue = const Color(0xFF0A2A4D);
    final Color sidebarBg = Colors.white;

    return Container(
      width: 280,
      height: double.infinity,
      decoration: BoxDecoration(
        color: sidebarBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(4, 0),
          )
        ],
      ),
      child: Column(
        children: [
          // 1. LOGO AREA
          Padding(
            padding: const EdgeInsets.fromLTRB(30, 40, 30, 20),
            child: Image.asset(
              'assets/images/logo_CIMS.png',
              width: 180,
              errorBuilder: (c, e, s) => const Icon(Icons.science, size: 50),
            ),
          ),

          const SizedBox(height: 20),

          // 2. MENU LIST
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Label Kategori
                  Padding(
                    padding: const EdgeInsets.only(left: 15, bottom: 10),
                    child: Text(
                        "MAIN MENU",
                        style: TextStyle(
                            color: Colors.grey[400],
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            letterSpacing: 1.2
                        )
                    ),
                  ),

                  _buildMenuItem(context, Icons.grid_view_rounded, "Dashboard", "Dashboard",
                      onTap: () => _navigateTo(context, const DashboardView())
                  ),

                  // Master Management (Bisa diakses semua atau mau dibatasi juga? Default: Semua)
                  _buildMenuItem(context, Icons.inventory_2_outlined, "Master Management", "Master Management",
                      onTap: () => _navigateTo(context, const MasterMenuView())
                  ),

                  _buildMenuItem(context, Icons.swap_horiz_rounded, "Transaction", "Transaction",
                      onTap: () => _navigateTo(context, const TransactionView())
                  ),

                  // --- LOGIC HIDE MENU: HANYA UNTUK SUPERVISOR ---
                  if (_userRole.contains("supervisor"))
                    _buildMenuItem(context, Icons.people_alt_outlined, "User Management", "User Management",
                        onTap: () => _navigateTo(context, const UserManagementView())
                    ),
                  // -----------------------------------------------

                  _buildMenuItem(context, Icons.analytics_outlined, "Report", "Report",
                      onTap: () => _navigateTo(context, const ReportView())
                  ),
                ],
              ),
            ),
          ),

          // 3. LOGOUT AREA
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade100))
              ),
              padding: const EdgeInsets.only (top: 20),
              child: _buildMenuItem(context, Icons.logout_rounded, "Logout", "Logout",
                  isLogout: true,
                  onTap: () => _handleLogout(context)
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPER NAVIGATION ---
  void _navigateTo(BuildContext context, Widget page) {
    // Kalau menu yang diklik adalah menu aktif, jangan reload
    // Note: widget.activeMenu karena sekarang ada di dalam State
    if (page.runtimeType.toString() == widget.activeMenu.replaceAll(" ", "") + "View") {
      return;
    }

    Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation1, animation2) => page,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        )
    );
  }

  // --- HELPER LOGOUT ---
  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Logout"),
        content: const Text("Apakah Anda yakin ingin keluar?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F), foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(context); // Tutup Dialog

                // HAPUS SESI LOGIN
                final authService = AuthService();
                await authService.logout();

                // KEMBALI KE HALAMAN LOGIN
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (c) => const LoginView()),
                        (route) => false,
                  );
                }
              },
              child: const Text("Logout")
          ),
        ],
      ),
    );
  }

  // --- HELPER MENU ITEM DESIGN ---
  Widget _buildMenuItem(BuildContext context, IconData icon, String title, String menuCode, {VoidCallback? onTap, bool isLogout = false}) {
    // Note: widget.activeMenu
    bool isActive = widget.activeMenu == menuCode;
    final Color vosenDarkBlue = const Color(0xFF0A2A4D);
    final Color vosenRed = const Color(0xFFD32F2F);

    Color textColor = isActive ? Colors.white : Colors.grey.shade600;
    Color iconColor = isActive ? Colors.white : Colors.grey.shade500;

    if (isLogout) {
      textColor = vosenRed;
      iconColor = vosenRed;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          hoverColor: isLogout ? vosenRed.withOpacity(0.05) : vosenDarkBlue.withOpacity(0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: isActive ? vosenDarkBlue : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: isActive ? [
                BoxShadow(color: vosenDarkBlue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
              ] : [],
            ),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 22),
                const SizedBox(width: 15),
                Text(
                    title,
                    style: TextStyle(
                        color: textColor,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 15
                    )
                ),
                if (isActive) ...[
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 12)
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}