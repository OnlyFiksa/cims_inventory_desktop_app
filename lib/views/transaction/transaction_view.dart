import 'package:flutter/material.dart';
import 'package:cims_app/widgets/custom_sidebar.dart';
import 'package:cims_app/services/auth_service.dart';

// Import View Tab (Pastikan path sesuai)
import 'package:cims_app/views/transaction/stock_in_list_view.dart';
import 'package:cims_app/views/transaction/stock_out_list_view.dart';
import 'package:cims_app/views/transaction/verification_list_view.dart';
import 'package:cims_app/views/transaction/stock_adjustment_list_view.dart';

class TransactionView extends StatefulWidget {
  const TransactionView({super.key});

  @override
  State<TransactionView> createState() => _TransactionViewState();
}

class _TransactionViewState extends State<TransactionView> {
  // STATE
  String _userRole = "staff";
  bool _isLoadingRole = true;
  String _currentTab = 'STOK_BARANG';

  // COLORS
  final Color vosenDarkBlue = const Color(0xFF0A2A4D);
  final Color bgGrey = const Color(0xFFF5F6FA);

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  void _loadUserRole() async {
    final authService = AuthService();
    final userData = await authService.getUserSession();
    if (mounted) {
      setState(() {
        _userRole = (userData['role'] ?? "staff").toString().toLowerCase();
        _isLoadingRole = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingRole) {
      return Scaffold(
        backgroundColor: bgGrey,
        body: Center(child: CircularProgressIndicator(color: vosenDarkBlue)),
      );
    }

    bool isSupervisor = _userRole.contains("supervisor");

    return Scaffold(
      backgroundColor: bgGrey,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CustomSidebar(activeMenu: "Transaction"),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Menu Transaksi", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: vosenDarkBlue)),
                          const SizedBox(height: 5),
                          Text("Akses: ${_userRole.toUpperCase()}", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Spacer(),
                      _buildTabButton("Stok Barang", 'STOK_BARANG'),
                      const SizedBox(width: 10),
                      _buildTabButton("Stok Masuk", 'MASUK'),
                      const SizedBox(width: 10),
                      _buildTabButton("Stok Keluar", 'KELUAR'),
                      if (isSupervisor) ...[
                        const SizedBox(width: 10),
                        _buildTabButton("Verifikasi", 'VERIFIKASI'),
                      ]
                    ],
                  ),
                  const SizedBox(height: 30),
                  _buildContent(isSupervisor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isSupervisor) {
    switch (_currentTab) {
      case 'STOK_BARANG':
        return StockAdjustmentListView(userRole: _userRole);
      case 'MASUK':
        return StockInListView(userRole: _userRole);
      case 'KELUAR':
        return const StockOutListView();
      case 'VERIFIKASI':
        if (isSupervisor) {
          return const VerificationListView();
        }
        return const Center(child: Text("Anda tidak memiliki akses."));
      default:
        return const Center(child: Text("Menu tidak ditemukan"));
    }
  }

  Widget _buildTabButton(String label, String code) {
    bool isActive = _currentTab == code;
    return InkWell(
      onTap: () => setState(() => _currentTab = code),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
        decoration: BoxDecoration(
          color: isActive ? vosenDarkBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isActive ? null : Border.all(color: Colors.grey.shade300),
          boxShadow: isActive ? [BoxShadow(color: vosenDarkBlue.withOpacity(0.3), blurRadius: 5, offset: const Offset(0, 3))] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? Colors.white : vosenDarkBlue,
          ),
        ),
      ),
    );
  }
}