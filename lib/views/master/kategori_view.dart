import 'package:flutter/material.dart';
import 'package:cims_app/widgets/custom_sidebar.dart';
import 'package:cims_app/views/master/master_menu_view.dart';
import 'package:cims_app/services/master/kategori_service.dart';

class KategoriView extends StatefulWidget {
  const KategoriView({super.key});

  @override
  State<KategoriView> createState() => _KategoriViewState();
}

class _KategoriViewState extends State<KategoriView> {
  // --- COLORS ---
  final Color vosenDarkBlue = const Color(0xFF0A2A4D);
  final Color vosenRed = const Color(0xFFD32F2F);
  final Color bgGrey = const Color(0xFFF5F7FA);

  // --- STATE ---
  bool _isFormVisible = false;
  bool _isEditing = false;
  bool _isLoading = true;

  String? _selectedId;
  Map<String, dynamic>? _selectedItemData;

  // --- CONTROLLERS ---
  final TextEditingController _kodeController = TextEditingController();
  final TextEditingController _kategoriController = TextEditingController();
  final TextEditingController _ketController = TextEditingController();

  // --- DATA ---
  List<dynamic> _dataList = [];
  final KategoriService _service = KategoriService();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // --- LOGIC API ---
  void _fetchData() async {
    setState(() => _isLoading = true);
    final data = await _service.getKategori();
    setState(() {
      _dataList = data;
      _isLoading = false;
      _selectedId = null;
      _selectedItemData = null;
    });
  }

  // FUNGSI FORMAT KODE (1 -> KAT-001)
  String _formatKode(String id) {
    // PadLeft(3, '0') artinya jika angka cuma 1 digit, tambahkan 0 di depan sampai 3 digit
    return "KAT-${id.padLeft(3, '0')}";
  }

  void _saveData() async {
    // 1. VALIDASI WAJIB ISI
    String inputName = _kategoriController.text.trim();
    if (inputName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Nama Kategori WAJIB diisi!"), backgroundColor: Colors.red)
      );
      return;
    }

    // 2. CEK DUPLIKAT (Client Side Check)
    bool isDuplicate = false;
    for (var item in _dataList) {
      if (_isEditing && item['id'].toString() == _selectedId) continue; // Skip diri sendiri saat edit
      if (item['name'].toString().toLowerCase() == inputName.toLowerCase()) {
        isDuplicate = true;
        break;
      }
    }

    if (isDuplicate) {
      showDialog(
          context: context,
          builder: (c) => AlertDialog(
            title: Row(children: [Icon(Icons.warning_amber, color: Colors.orange), SizedBox(width: 10), Text("Duplikat")]),
            content: Text("Nama kategori '$inputName' sudah ada."),
            actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("OK"))],
          )
      );
      return;
    }

    // 3. KIRIM DATA KE BACKEND
    Map<String, String> formData = {
      "name": inputName,
      "description": _ketController.text.trim(),
    };

    bool success;
    if (_isEditing && _selectedId != null) {
      formData['id'] = _selectedId!;
      success = await _service.updateKategori(formData);
    } else {
      success = await _service.addKategori(formData);
    }

    if (success) {
      _fetchData();
      _resetForm();
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Berhasil disimpan!"), backgroundColor: Colors.green));
    } else {
      // Jika masih gagal, kemungkinan API PHP error / Database mati
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal menyimpan. Cek koneksi XAMPP!"), backgroundColor: Colors.red));
    }
  }

  void _deleteItem() async {
    if (_selectedId == null) return;
    // ... (Sama seperti sebelumnya) ...
    // Untuk mempersingkat, saya fokuskan di build UI
    bool success = await _service.deleteKategori(_selectedId!);
    if(success) {
      _fetchData(); _resetForm();
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Data dihapus"), backgroundColor: Colors.green));
    }
  }

  // --- LOGIC UI ---
  void _onRowTap(Map<String, dynamic> item) {
    setState(() {
      _selectedId = item['id'].toString();
      _selectedItemData = item;
      if (_isFormVisible && _isEditing) {
        _fillFormWithSelection();
      }
    });
  }

  void _onEditPressed() {
    if (_selectedId == null) return;
    setState(() {
      _isFormVisible = true;
      _isEditing = true;
      _fillFormWithSelection();
    });
  }

  void _fillFormWithSelection() {
    if (_selectedItemData != null) {
      // Saat Edit, tampilkan kode yang sudah diformat (KAT-00X)
      _kodeController.text = _formatKode(_selectedItemData!['id'].toString());
      _kategoriController.text = _selectedItemData!['name'];
      _ketController.text = _selectedItemData!['description'] ?? '';
    }
  }

  void _onAddPressed() {
    _resetForm();
    setState(() {
      _isFormVisible = true;
      _kodeController.text = "AUTO"; // Saat Tambah Baru, tulis AUTO
    });
  }

  void _resetForm() {
    _kodeController.clear();
    _kategoriController.clear();
    _ketController.clear();
    setState(() {
      _isFormVisible = false;
      _isEditing = false;
      _selectedId = null;
      _selectedItemData = null;
    });
  }

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
                  _buildHeaderNav(),
                  const SizedBox(height: 30),
                  if (_isFormVisible) ...[
                    _buildFormCard(),
                    const SizedBox(height: 30),
                  ],
                  _buildTableCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS ---
  Widget _buildHeaderNav() {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MasterMenuView())),
          borderRadius: BorderRadius.circular(50),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300)),
            child: const Icon(Icons.arrow_back, color: Colors.black87),
          ),
        ),
        const SizedBox(width: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Data Kategori", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: vosenDarkBlue)),
            const SizedBox(height: 5),
            Text("Master Management > Kategori", style: TextStyle(color: Colors.grey[500], fontSize: 14)),
          ],
        ),
      ],
    );
  }

  Widget _buildTableCard() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: vosenDarkBlue.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 5))]),
      padding: const EdgeInsets.all(30),
      child: Column(
        children: [
          // TOOLBAR
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 45,
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(color: bgGrey, borderRadius: BorderRadius.circular(10)),
                  child: const Row(children: [Icon(Icons.search, color: Colors.grey), SizedBox(width: 10), Expanded(child: TextField(decoration: InputDecoration(border: InputBorder.none, hintText: "Cari kategori...", isCollapsed: true)))]),
                ),
              ),
              const SizedBox(width: 20),

              if (_selectedId != null) ...[
                ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: vosenRed.withOpacity(0.1), foregroundColor: vosenRed, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    onPressed: _deleteItem, icon: const Icon(Icons.delete_outline, size: 20), label: const Text("Hapus")
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.withOpacity(0.1), foregroundColor: Colors.orange[800], elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    onPressed: _onEditPressed, icon: const Icon(Icons.edit_outlined, size: 20), label: const Text("Edit")
                ),
                const SizedBox(width: 10),
              ],

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: vosenDarkBlue, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: _onAddPressed, icon: const Icon(Icons.add, size: 20), label: const Text("Tambah"),
              ),
            ],
          ),
          const SizedBox(height: 25),

          // TABEL HEADER
          Container(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
            decoration: BoxDecoration(color: bgGrey, borderRadius: BorderRadius.circular(10)),
            child: const Row(
              children: [
                Expanded(flex: 1, child: Text("KODE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                Expanded(flex: 2, child: Text("NAMA KATEGORI", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                Expanded(flex: 3, child: Text("KETERANGAN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // TABEL LIST (REAL DATA)
          _isLoading
              ? const Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator())
              : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _dataList.length,
            itemBuilder: (context, index) {
              final item = _dataList[index];
              final isSelected = _selectedId == item['id'].toString();

              // FORMAT KODE: ID 1 -> KAT-001
              String displayCode = _formatKode(item['id'].toString());

              return InkWell(
                onTap: () => _onRowTap(item),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 5),
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                  decoration: BoxDecoration(color: isSelected ? Colors.blue.withOpacity(0.05) : Colors.white, borderRadius: BorderRadius.circular(10), border: isSelected ? Border.all(color: Colors.blue.withOpacity(0.3)) : Border(bottom: BorderSide(color: Colors.grey.shade100))),
                  child: Row(
                    children: [
                      // TAMPILKAN KODE YANG SUDAH DIFORMAT
                      Expanded(flex: 1, child: Text(displayCode, style: TextStyle(fontWeight: FontWeight.bold, color: vosenDarkBlue))),
                      Expanded(flex: 2, child: Text(item['name'])),
                      Expanded(flex: 3, child: Text(item['description'] ?? '-', style: TextStyle(color: Colors.grey[600]))),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: vosenDarkBlue.withOpacity(0.1)), boxShadow: [BoxShadow(color: vosenDarkBlue.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 5))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_isEditing ? "Edit Kategori" : "Tambah Kategori Baru", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: vosenDarkBlue)),
          const SizedBox(height: 20),
          Row(
            children: [
              // Kolom Kode (READ ONLY & AUTO)
              Expanded(flex: 1, child: _buildTextField("Kode (Otomatis)", _kodeController, readOnly: true)),
              const SizedBox(width: 20),
              // Kolom Nama Kategori (WAJIB)
              Expanded(flex: 2, child: _buildTextField("Nama Kategori", _kategoriController, isMandatory: true)),
            ],
          ),
          const SizedBox(height: 20),
          // Kolom Keterangan (OPTIONAL)
          _buildTextField("Keterangan", _ketController, maxLines: 2),

          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: _resetForm, child: Text("Batal", style: TextStyle(color: Colors.grey[600]))),
              const SizedBox(width: 10),
              ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: vosenDarkBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), onPressed: _saveData, child: Text(_isEditing ? "Update Data" : "Simpan Data")),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool readOnly = false, int maxLines = 1, bool isMandatory = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      RichText(text: TextSpan(text: label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54), children: [if (isMandatory) const TextSpan(text: " *", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))])),
      const SizedBox(height: 8),
      TextField(
          controller: controller,
          readOnly: readOnly,
          maxLines: maxLines,
          decoration: InputDecoration(
              filled: true,
              fillColor: readOnly ? Colors.grey[200] : const Color(0xFFF7F8FA),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15)
          )
      )
    ]);
  }
}