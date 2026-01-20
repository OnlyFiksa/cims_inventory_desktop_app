import 'package:flutter/material.dart';
import 'package:cims_app/widgets/custom_sidebar.dart';
import 'package:cims_app/views/master/master_menu_view.dart'; // Import untuk navigasi back
import 'package:cims_app/views/master/app_code/volume_kemasan_view.dart';
import 'package:cims_app/views/master/app_code/volume_per_kemasan_view.dart';

class AppCodeView extends StatefulWidget {
  const AppCodeView({super.key});

  @override
  State<AppCodeView> createState() => _AppCodeViewState();
}

class _AppCodeViewState extends State<AppCodeView> {
  final Color vosenDarkBlue = const Color(0xFF0A2A4D);
  final Color bgGrey = const Color(0xFFF5F7FA);

  // Tab State
  String _currentSubMenu = 'KEMASAN';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CustomSidebar(activeMenu: "Master Management"),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER & TAB NAVIGASI
                  _buildHeaderAndTabs(),

                  const SizedBox(height: 30),

                  // KONTEN DINAMIS
                  if (_currentSubMenu == 'KEMASAN')
                    const VolumeKemasanView()
                  else
                    const VolumePerKemasanView(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- HEADER & TABS MODERN ---
  Widget _buildHeaderAndTabs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Header & Back Button
        Row(
          children: [
            InkWell(
              onTap: () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const MasterMenuView())
                );
              },
              borderRadius: BorderRadius.circular(50),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300)
                ),
                child: const Icon(Icons.arrow_back, color: Colors.black87),
              ),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("App Code Setting", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: vosenDarkBlue)),
                const SizedBox(height: 5),
                Text("Master Management > App Code", style: TextStyle(color: Colors.grey[500], fontSize: 14)),
              ],
            ),
          ],
        ),

        const SizedBox(height: 30),

        // 2. Tab Menu (Pill Style)
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade200)
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min, // Agar tidak full width
            children: [
              _buildTabButton("Volume Kemasan", 'KEMASAN'),
              const SizedBox(width: 10),
              _buildTabButton("Volume per Kemasan", 'PER_KEMASAN'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton(String label, String code) {
    bool isActive = _currentSubMenu == code;
    return InkWell(
      onTap: () => setState(() => _currentSubMenu = code),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? vosenDarkBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
              color: isActive ? Colors.white : Colors.grey[600],
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              fontSize: 14
          ),
        ),
      ),
    );
  }
}