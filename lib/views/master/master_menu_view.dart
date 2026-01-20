import 'package:flutter/material.dart';
import 'package:cims_app/widgets/custom_sidebar.dart';

// --- IMPORT HALAMAN MASTER BERDASARKAN STRUKTUR FILE ANDA ---
import 'package:cims_app/views/master/jenis_item_view.dart';
import 'package:cims_app/views/master/kategori_view.dart';
import 'package:cims_app/views/master/manufacture_view.dart';
import 'package:cims_app/views/master/supplier_view.dart';
import 'package:cims_app/views/master/pemilik_view.dart';
import 'package:cims_app/views/master/item_master_view.dart';

// Khusus App Code (Karena di gambar terlihat sebagai folder)
// Jika error, cek apakah nama filenya benar 'app_code_view.dart'
import 'package:cims_app/views/master/app_code/app_code_view.dart';

class MasterMenuView extends StatelessWidget {
  const MasterMenuView({super.key});

  final Color vosenDarkBlue = const Color(0xFF0A2A4D);
  final Color bgGrey = const Color(0xFFF5F7FA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. SIDEBAR
          const CustomSidebar(activeMenu: "Master Management"),

          // 2. MAIN CONTENT
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER
                  Text(
                      "Master Management",
                      style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: vosenDarkBlue
                      )
                  ),
                  const SizedBox(height: 8),
                  Text(
                      "Pilih menu di bawah untuk mengelola data referensi.",
                      style: TextStyle(color: Colors.grey[500], fontSize: 16)
                  ),
                  const SizedBox(height: 30),

                  // MENU GRID
                  Expanded(
                    child: _buildMenuGrid(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- MENU GRID (5 KOLOM) ---
  Widget _buildMenuGrid(BuildContext context) {
    // Daftar Menu & Halaman Tujuannya
    final List<Map<String, dynamic>> menuItems = [
      {
        "title": "Jenis Item",
        "icon": Icons.category_rounded,
        "color": Colors.blue,
        "page": const JenisItemView() // Pastikan nama Class di file jenis_item_view.dart adalah JenisItemView
      },
      {
        "title": "Kategori",
        "icon": Icons.account_tree_rounded,
        "color": Colors.orange,
        "page": const KategoriView()
      },
      {
        "title": "Manufacture",
        "icon": Icons.factory_rounded,
        "color": Colors.red,
        "page": const ManufactureView()
      },
      {
        "title": "Supplier",
        "icon": Icons.local_shipping_rounded,
        "color": Colors.green,
        "page": const SupplierView()
      },
      {
        "title": "Pemilik",
        "icon": Icons.person_pin_rounded,
        "color": Colors.purple,
        "page": const PemilikView()
      },
      {
        "title": "App Code",
        "icon": Icons.qr_code_rounded,
        "color": Colors.teal,
        "page": const AppCodeView()
      },
      {
        "title": "Item Master",
        "icon": Icons.inventory_2_rounded,
        "color": Colors.indigo,
        "page": const ItemMasterView()
      },
    ];

    return GridView.builder(
      itemCount: menuItems.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,       // 5 Kolom per baris
        childAspectRatio: 0.85,  // Rasio Card
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      itemBuilder: (context, index) {
        final item = menuItems[index];
        return _buildMenuCard(
          title: item['title'],
          icon: item['icon'],
          color: item['color'],
          onTap: () {
            // NAVIGASI KE HALAMAN ASLI
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => item['page'])
            );
          },
        );
      },
    );
  }

  // --- CARD DESIGN ---
  Widget _buildMenuCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 8)
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey[300], size: 16)
              ],
            ),

            const Spacer(),

            Text(
                title,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: vosenDarkBlue,
                    height: 1.2
                )
            ),
            const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }
}