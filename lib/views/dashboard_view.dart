import 'package:flutter/material.dart';
import 'package:cims_app/widgets/custom_sidebar.dart';
import 'package:cims_app/services/auth_service.dart';
import 'package:cims_app/services/dashboard_service.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  // COLORS
  final Color vosenDarkBlue = const Color(0xFF0A2A4D);
  final Color bgGrey = const Color(0xFFF5F7FA);

  // DATA STATE
  String _namaUser = "User";
  String _roleUser = "Staff";
  bool _isLoadingData = true;

  Map<String, dynamic> _stats = {
    "total_items": 0,
    "low_stock": 0,
    "expired": 0,
    "out_of_stock": 0
  };
  List<dynamic> _inventoryList = [];

  // FILTER CATEGORY DYNAMIC
  List<String> _categoryOptions = ["All"]; // Default awal hanya All

  // FILTER STATE
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategoryFilter = "All";
  String _selectedSort = "Default";
  int _currentPage = 1;
  final int _itemsPerPage = 7;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadDashboardData();
  }

  void _loadUserData() async {
    final authService = AuthService();
    final userData = await authService.getUserSession();
    if (mounted) {
      setState(() {
        _namaUser = userData['name'] ?? "User";
        String r = userData['role'] ?? "staff";
        _roleUser = r.isNotEmpty ? "${r[0].toUpperCase()}${r.substring(1)}" : r;
      });
    }
  }

  void _loadDashboardData() async {
    final dashboardService = DashboardService();
    final data = await dashboardService.getDashboardData();

    if (mounted) {
      if (data['success'] == true) {
        // AMBIL KATEGORI DARI API
        List<dynamic> catsFromApi = data['categories'] ?? [];
        List<String> loadedCats = ["All"];
        for (var cat in catsFromApi) {
          loadedCats.add(cat.toString());
        }

        setState(() {
          _stats = data['stats'];
          _inventoryList = data['list'];
          _categoryOptions = loadedCats; // Update Dropdown Options
          _isLoadingData = false;
        });
      } else {
        setState(() => _isLoadingData = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal memuat data: ${data['message']}")));
      }
    }
  }

  // --- LOGIC FILTER ---
  List<dynamic> get filteredData {
    List<dynamic> data = _inventoryList;

    // 1. Search
    if (_searchController.text.isNotEmpty) {
      data = data.where((item) => item['name'].toString().toLowerCase().contains(_searchController.text.toLowerCase())).toList();
    }

    // 2. Filter Category (Sekarang Dinamis)
    if (_selectedCategoryFilter != "All") {
      data = data.where((item) => item['cat'] == _selectedCategoryFilter).toList();
    }

    // 3. Sort
    if (_selectedSort == "Terbaru") {
      data.sort((a, b) => _parseDate(b['in']).compareTo(_parseDate(a['in'])));
    } else if (_selectedSort == "Terlama") {
      data.sort((a, b) => _parseDate(a['in']).compareTo(_parseDate(b['in'])));
    } else if (_selectedSort == "Expired Dekat") {
      data.sort((a, b) => _parseDate(a['exp']).compareTo(_parseDate(b['exp'])));
    }

    return data;
  }

  DateTime _parseDate(String dateStr) {
    try {
      var parts = dateStr.split('/');
      return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
    } catch (e) { return DateTime.now(); }
  }

  List<dynamic> get paginatedData {
    int start = (_currentPage - 1) * _itemsPerPage;
    int end = start + _itemsPerPage;
    if (start >= filteredData.length) return [];
    return filteredData.sublist(start, end > filteredData.length ? filteredData.length : end);
  }

  int get totalPages => (filteredData.length / _itemsPerPage).ceil();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CustomSidebar(activeMenu: "Dashboard"),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 30),

                  if (_isLoadingData)
                    SizedBox(height: 400, child: Center(child: CircularProgressIndicator(color: vosenDarkBlue)))
                  else ...[
                    _buildStatCards(),
                    const SizedBox(height: 30),
                    _buildInventoryTable(),
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Dashboard Overview", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: vosenDarkBlue)),
          const SizedBox(height: 5),
          Text("Selamat datang kembali, pantau inventaris Anda hari ini.", style: TextStyle(color: Colors.grey[600], fontSize: 15)),
        ]),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(50), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
          child: Row(children: [
            CircleAvatar(radius: 20, backgroundColor: vosenDarkBlue, child: const Icon(Icons.person, color: Colors.white, size: 20)),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_namaUser, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: vosenDarkBlue)),
              Text(_roleUser, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
            ]),
            const SizedBox(width: 5),
          ]),
        )
      ],
    );
  }

  Widget _buildStatCards() {
    return Row(
      children: [
        _statCard("Total Items", _stats['total_items'].toString(), "Item Terdaftar", Icons.inventory_2_rounded, Colors.blue),
        const SizedBox(width: 20),
        _statCard("Low Stock", _stats['low_stock'].toString(), "Perlu Restock", Icons.warning_amber_rounded, Colors.orange),
        const SizedBox(width: 20),
        _statCard("Expired", _stats['expired'].toString(), "Item Kadaluwarsa", Icons.event_busy_rounded, Colors.red),
        const SizedBox(width: 20),
        _statCard("Out of Stock", _stats['out_of_stock'].toString(), "Stok Kosong", Icons.remove_shopping_cart_rounded, Colors.grey),
      ],
    );
  }

  Widget _statCard(String title, String count, String sub, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey[600])),
              const SizedBox(height: 5),
              Text(count, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: vosenDarkBlue)),
            ]),
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 22))
          ]),
          const SizedBox(height: 10),
          Row(children: [Icon(Icons.info_outline, size: 14, color: color), const SizedBox(width: 5), Text(sub, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600))]),
        ]),
      ),
    );
  }

  Widget _buildInventoryTable() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)]),
      padding: const EdgeInsets.all(30),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text("Overview Stok Terkini", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          Row(children: [
            // Search
            Container(
              width: 250, height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(color: bgGrey, borderRadius: BorderRadius.circular(20)),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _currentPage = 1),
                decoration: const InputDecoration(hintText: "Cari barang...", border: InputBorder.none, icon: Icon(Icons.search, size: 18, color: Colors.grey)),
              ),
            ),
            const SizedBox(width: 10),

            // SORT
            _buildDropdownAction("Sort", ["Default", "Terbaru", "Terlama", "Expired Dekat"], _selectedSort, (v) => setState(() { _selectedSort = v; _currentPage = 1; })),

            const SizedBox(width: 10),

            // FILTER (SEKARANG MENGGUNAKAN LIST DINAMIS DARI DATABASE)
            _buildDropdownAction("Kategori", _categoryOptions, _selectedCategoryFilter, (v) => setState(() { _selectedCategoryFilter = v; _currentPage = 1; })),
          ]),
        ]),
        const SizedBox(height: 30),

        // HEADER TABLE
        Container(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
          decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
          child: Row(children: [
            Expanded(flex: 3, child: Text("NAMA BARANG", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey[600]))),
            Expanded(flex: 2, child: Text("KATEGORI", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey[600]))),
            Expanded(flex: 2, child: Text("TGL. MASUK", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey[600]))),
            Expanded(flex: 2, child: Text("EXPIRED", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey[600]))),
            Expanded(flex: 2, child: Center(child: Text("STATUS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey[600])))),
          ]),
        ),
        const SizedBox(height: 10),

        if (paginatedData.isEmpty)
          Padding(padding: const EdgeInsets.all(50), child: Center(child: Column(children: [Icon(Icons.inbox_rounded, size: 50, color: Colors.grey[300]), const SizedBox(height: 10), Text("Tidak ada data", style: TextStyle(color: Colors.grey[400]))]))),

        ...paginatedData.map((item) => _tableRow(item['name'], item['cat'], item['in'], item['exp'], item['status'])).toList(),

        const SizedBox(height: 25),

        if (filteredData.isNotEmpty)
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            Text("Page $_currentPage of $totalPages", style: TextStyle(color: Colors.grey[500], fontSize: 13)),
            const SizedBox(width: 15),
            IconButton(icon: const Icon(Icons.chevron_left), onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null),
            IconButton(icon: const Icon(Icons.chevron_right), onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null),
          ])
      ]),
    );
  }

  // Helper Dropdown
  Widget _buildDropdownAction(String label, List<String> items, String selected, Function(String) onSelect) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 45),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      onSelected: onSelect,
      itemBuilder: (context) => items.map((opt) => PopupMenuItem(value: opt, child: Text(opt, style: TextStyle(fontWeight: selected == opt ? FontWeight.bold : FontWeight.normal)))).toList(),
      child: Container(
        height: 40, padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
            color: selected != (items[0]) && label != "Sort" ? vosenDarkBlue.withOpacity(0.1) : bgGrey,
            borderRadius: BorderRadius.circular(20)
        ),
        child: Row(children: [
          Text(selected == items[0] ? label : selected, style: TextStyle(color: selected != items[0] && label != "Sort" ? vosenDarkBlue : Colors.black87, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(width: 5),
          Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey[600])
        ]),
      ),
    );
  }

  Widget _tableRow(String name, String cat, String dateIn, String dateExp, String status) {
    Color badgeColor = Colors.green; Color badgeBg = Colors.green.shade50;
    if (status == "Expired") { badgeColor = Colors.red; badgeBg = Colors.red.shade50; }
    else if (status == "Out of Stock") { badgeColor = Colors.grey; badgeBg = Colors.grey.shade100; }
    else if (status == "Low Stock") { badgeColor = Colors.orange; badgeBg = Colors.orange.shade50; }

    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
      decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
      child: Row(children: [
        Expanded(flex: 3, child: Text(name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: vosenDarkBlue))),
        Expanded(flex: 2, child: Text(cat, style: TextStyle(fontSize: 14, color: Colors.grey[800]))),
        Expanded(flex: 2, child: Text(dateIn, style: TextStyle(fontSize: 14, color: Colors.grey[800]))),
        Expanded(flex: 2, child: Text(dateExp, style: TextStyle(fontSize: 14, color: Colors.grey[800]))),
        Expanded(flex: 2, child: Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(20)), child: Text(status, textAlign: TextAlign.center, style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 11))))),
      ]),
    );
  }
}