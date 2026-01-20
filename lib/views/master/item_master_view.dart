import 'package:flutter/material.dart';
import 'package:cims_app/widgets/custom_sidebar.dart';
import 'package:cims_app/views/master/master_menu_view.dart';
import 'package:cims_app/services/master/item_service.dart';

class ItemMasterView extends StatefulWidget {
  const ItemMasterView({super.key});

  @override
  State<ItemMasterView> createState() => _ItemMasterViewState();
}

class _ItemMasterViewState extends State<ItemMasterView> {
  final Color vosenDarkBlue = const Color(0xFF0A2A4D);
  final Color vosenRed = const Color(0xFFD32F2F);
  final Color bgGrey = const Color(0xFFF5F7FA);

  bool _isFormVisible = false;
  bool _isEditing = false;

  String? _selectedId;
  Map<String, dynamic>? _selectedItem;

  // Controllers
  final _kodeController = TextEditingController();
  final _namaBarangController = TextEditingController();
  final _minStockController = TextEditingController();
  final _keteranganController = TextEditingController();

  // Dropdown IDs
  String? _selectedKategoriId;
  String? _selectedPemilikId;
  String? _selectedJenisId;
  String? _selectedManufactureId;
  String? _selectedSupplierId;
  String? _selectedPackagingId;

  // Data
  List<dynamic> _itemsList = [];
  Map<String, List<dynamic>> _dropdowns = {};

  final ItemService _service = ItemService();

  @override
  void initState() {
    super.initState();
    _fetchData();
    _fetchDropdowns();
  }

  void _fetchData() async {
    final data = await _service.getItems();
    if(mounted) setState(() { _itemsList = data; });
  }

  void _fetchDropdowns() async {
    final data = await _service.getDropdowns();
    if(mounted) setState(() => _dropdowns = data);
  }

  // --- [FIXED] LOGIC KODE ASYNC ---
  Future<void> _generateItemCode() async {
    if (!_isEditing) return;

    // 1. KODE PEMILIK (2 Digit)
    String codePemilik = "XX";
    if (_selectedPemilikId != null && _dropdowns['owners'] != null) {
      var item = _dropdowns['owners']!.firstWhere((e) => e['id'].toString() == _selectedPemilikId, orElse: () => null);
      if (item != null) codePemilik = item['code'] ?? "XX";
    }

    // 2. KODE JENIS ITEM (1 Digit)
    String codeJenis = "X";
    if (_selectedJenisId != null && _dropdowns['types'] != null) {
      var item = _dropdowns['types']!.firstWhere((e) => e['id'].toString() == _selectedJenisId, orElse: () => null);
      if (item != null) codeJenis = item['code'] ?? "X";
    }

    // 3. [FIXED] NOMOR URUT BARANG (Ambil dari Server)
    // Menggunakan API agar menghitung Total (termasuk Deleted)
    int nextSeq = await _service.getNextSequence();
    String urutan = nextSeq.toString().padLeft(3, '0');

    // 4. ID MANUFAKTUR (2 Digit)
    String codeManuf = _selectedManufactureId?.padLeft(2, '0') ?? "00";

    // 5. ID SUPPLIER (2 Digit)
    String codeSupp = _selectedSupplierId?.padLeft(2, '0') ?? "00";

    // 6. SUFFIX
    String suffix = "a";

    // RUMUS FINAL: PK R - 001 - 01 01 - a
    if (mounted) {
      setState(() {
        _kodeController.text = "$codePemilik$codeJenis-$urutan-$codeManuf$codeSupp-$suffix";
      });
    }
  }

  void _saveData() async {
    if (_namaBarangController.text.isEmpty ||
        _selectedKategoriId == null ||
        _selectedPemilikId == null ||
        _selectedJenisId == null ||
        _selectedManufactureId == null ||
        _selectedSupplierId == null ||
        _selectedPackagingId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lengkapi semua kolom bertanda *!"), backgroundColor: Colors.red));
      return;
    }

    Map<String, String> data = {
      "code": _kodeController.text,
      "name": _namaBarangController.text,
      "min_stock": _minStockController.text,
      "description": _keteranganController.text,
      "category_id": _selectedKategoriId!,
      "owner_id": _selectedPemilikId!,
      "type_id": _selectedJenisId!,
      "manufacturer_id": _selectedManufactureId!,
      "supplier_id": _selectedSupplierId!,
      "packaging_id": _selectedPackagingId!,
    };

    bool success;
    if (_isEditing && _selectedId != null) {
      data['id'] = _selectedId!;
      success = await _service.updateItem(data);
    } else {
      success = await _service.addItem(data);
    }

    if (success) {
      _fetchData();
      _resetForm();
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Berhasil disimpan"), backgroundColor: Colors.green));
    } else {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal menyimpan"), backgroundColor: Colors.red));
    }
  }

  void _deleteItem() async {
    if (_selectedId == null) return;
    showDialog(context: context, builder: (c) => AlertDialog(
        title: const Text("Hapus Item?"), content: const Text("Yakin ingin menghapus item ini?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("Batal")),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: vosenRed, foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(c);
                if (await _service.deleteItem(_selectedId!)) { _fetchData(); _resetForm(); }
              }, child: const Text("Hapus"))
        ]
    ));
  }

  void _openAddForm() {
    _resetFormState();
    setState(() {
      _isFormVisible = true;
      _isEditing = true;
      _kodeController.text = "Loading..."; // Feedback user
    });
    _generateItemCode(); // Auto generate saat buka form
  }

  void _openDetailForm(Map<String, dynamic> item) {
    setState(() {
      _isFormVisible = true;
      _isEditing = false;
      _selectedId = item['id'].toString();
      _selectedItem = item;

      _kodeController.text = item['code'];
      _namaBarangController.text = item['name'];
      _minStockController.text = item['min_stock'].toString();
      _keteranganController.text = item['description'] ?? '';

      _selectedKategoriId = item['category_id']?.toString();
      _selectedPemilikId = item['owner_id']?.toString();
      _selectedJenisId = item['type_id']?.toString();
      _selectedManufactureId = item['manufacturer_id']?.toString();
      _selectedSupplierId = item['supplier_id']?.toString();
      _selectedPackagingId = item['packaging_id']?.toString();
    });
  }

  void _resetForm() {
    _resetFormState();
    setState(() { _isFormVisible = false; });
  }

  void _resetFormState() {
    _kodeController.clear(); _namaBarangController.clear(); _minStockController.clear(); _keteranganController.clear();
    _selectedKategoriId = null; _selectedPemilikId = null; _selectedJenisId = null;
    _selectedManufactureId = null; _selectedSupplierId = null; _selectedPackagingId = null;
    _selectedId = null; _selectedItem = null; _isEditing = false;
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
                  if (_isFormVisible) _buildFormCard() else _buildTableCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderNav() {
    return Row(children: [
      InkWell(
          onTap: () {
            if (_isFormVisible) _resetForm(); else Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const MasterMenuView()));
          },
          borderRadius: BorderRadius.circular(50),
          child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300)), child: const Icon(Icons.arrow_back, color: Colors.black87))
      ),
      const SizedBox(width: 20),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_isFormVisible ? (_isEditing && _selectedId == null ? "Tambah Item Baru" : "Detail Item") : "Data Item Master", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: vosenDarkBlue)),
        const SizedBox(height: 5),
        Text("Master Management > Item Master", style: TextStyle(color: Colors.grey[500], fontSize: 14)),
      ]),
    ]);
  }

  Widget _buildTableCard() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: vosenDarkBlue.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 5))]),
      padding: const EdgeInsets.all(30),
      child: Column(children: [
        Row(children: [
          Expanded(child: Container(height: 45, padding: const EdgeInsets.symmetric(horizontal: 15), decoration: BoxDecoration(color: bgGrey, borderRadius: BorderRadius.circular(10)), child: const Row(children: [Icon(Icons.search, color: Colors.grey), SizedBox(width: 10), Expanded(child: TextField(decoration: InputDecoration(border: InputBorder.none, hintText: "Cari nama barang...", isCollapsed: true)))]))),
          const SizedBox(width: 20),
          ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: vosenDarkBlue, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), onPressed: _openAddForm, icon: const Icon(Icons.add, size: 20), label: const Text("Tambah")),
        ]),
        const SizedBox(height: 25),

        Container(padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15), decoration: BoxDecoration(color: bgGrey, borderRadius: BorderRadius.circular(10)), child: const Row(children: [
          Expanded(flex: 2, child: Text("KODE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          Expanded(flex: 3, child: Text("NAMA BARANG", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          Expanded(flex: 2, child: Text("KATEGORI", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          Expanded(flex: 2, child: Text("STOK MIN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
        ])),
        const SizedBox(height: 10),

        ListView.builder(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _itemsList.length, itemBuilder: (context, index) {
          final item = _itemsList[index];
          return InkWell(onTap: () => _openDetailForm(item), borderRadius: BorderRadius.circular(10), child: Container(
            margin: const EdgeInsets.only(bottom: 5), padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
            child: Row(children: [
              Expanded(flex: 2, child: Text(item['code'] ?? '-', style: TextStyle(fontWeight: FontWeight.bold, color: vosenDarkBlue))),
              Expanded(flex: 3, child: Text(item['name'] ?? '-')),
              Expanded(flex: 2, child: Text(item['category_name'] ?? '-')),
              Expanded(flex: 2, child: Text(item['min_stock'].toString())),
            ]),
          ));
        },
        ),
      ]),
    );
  }

  Widget _buildFormCard() {
    bool isReadOnly = !_isEditing;
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: vosenDarkBlue.withOpacity(0.1)), boxShadow: [BoxShadow(color: vosenDarkBlue.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 5))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text("Informasi Barang", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: vosenDarkBlue)),
          if (_selectedId != null && !_isEditing)
            Row(children: [
              OutlinedButton.icon(onPressed: _deleteItem, icon: const Icon(Icons.delete, size: 18, color: Colors.red), label: const Text("Hapus", style: TextStyle(color: Colors.red))),
              const SizedBox(width: 10),
              ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white), onPressed: () => setState(() => _isEditing = true), icon: const Icon(Icons.edit, size: 18), label: const Text("Edit")),
            ])
        ]),
        const SizedBox(height: 25),

        // ROW 1: KODE & KATEGORI
        Row(children: [
          Expanded(flex: 3, child: _buildTextField("Kode Barang (Auto)", _kodeController, true, isMandatory: true)),
          const SizedBox(width: 20),
          Expanded(flex: 2, child: _buildDropdown("Kategori", _dropdowns['categories'] ?? [], _selectedKategoriId, (val) => setState(() => _selectedKategoriId = val), isReadOnly, isMandatory: true)),
        ]),
        const SizedBox(height: 20),

        // ROW 2: NAMA BARANG
        _buildTextField("Nama Barang", _namaBarangController, isReadOnly, isMandatory: true),
        const SizedBox(height: 20),

        // ROW 3: PEMILIK & JENIS ITEM (Trigger Kode)
        Row(children: [
          Expanded(child: _buildDropdown("Pemilik", _dropdowns['owners'] ?? [], _selectedPemilikId, (val) {
            setState(() { _selectedPemilikId = val; });
            _generateItemCode(); // Panggil fungsi async
          }, isReadOnly, isMandatory: true)),
          const SizedBox(width: 20),
          Expanded(child: _buildDropdown("Jenis Item", _dropdowns['types'] ?? [], _selectedJenisId, (val) {
            setState(() { _selectedJenisId = val; });
            _generateItemCode(); // Panggil fungsi async
          }, isReadOnly, isMandatory: true)),
        ]),
        const SizedBox(height: 20),

        // ROW 4: MANUFAKTUR & SUPPLIER (Trigger Kode)
        Row(children: [
          Expanded(child: _buildDropdown("Manufaktur", _dropdowns['manufacturers'] ?? [], _selectedManufactureId, (val) {
            setState(() { _selectedManufactureId = val; });
            _generateItemCode(); // Panggil fungsi async
          }, isReadOnly, isMandatory: true)),
          const SizedBox(width: 20),
          Expanded(child: _buildDropdown("Supplier", _dropdowns['suppliers'] ?? [], _selectedSupplierId, (val) {
            setState(() { _selectedSupplierId = val; });
            _generateItemCode(); // Panggil fungsi async
          }, isReadOnly, isMandatory: true)),
        ]),
        const SizedBox(height: 20),

        // ROW 5: KEMASAN & STOK MIN
        Row(children: [
          Expanded(child: _buildDropdown("Kemasan (Satuan)", _dropdowns['packagings'] ?? [], _selectedPackagingId, (val) => setState(() => _selectedPackagingId = val), isReadOnly, isMandatory: true)),
          const SizedBox(width: 20),
          Expanded(child: _buildTextField("Min Stock (Buffer Stok)", _minStockController, isReadOnly, isNumber: true, isMandatory: true)),
        ]),
        const SizedBox(height: 20),

        // ROW 6: KETERANGAN
        _buildTextField("Keterangan", _keteranganController, isReadOnly, maxLines: 3),

        const SizedBox(height: 30),
        if (_isEditing)
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton(onPressed: _selectedId == null ? _resetForm : () => setState(() => _isEditing = false), child: const Text("Batal")),
            const SizedBox(width: 10),
            ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: vosenDarkBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), onPressed: _saveData, child: const Text("Simpan Data"))
          ])
      ]),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, bool isReadOnly, {bool isNumber = false, int maxLines = 1, bool isMandatory = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      RichText(text: TextSpan(text: label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54), children: [if (isMandatory) const TextSpan(text: " *", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))])),
      const SizedBox(height: 8),
      TextField(controller: controller, readOnly: isReadOnly, keyboardType: isNumber ? TextInputType.number : TextInputType.text, maxLines: maxLines, decoration: InputDecoration(filled: true, fillColor: isReadOnly ? Colors.grey[100] : const Color(0xFFF7F8FA), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)))
    ]);
  }

  Widget _buildDropdown(String label, List<dynamic> items, String? value, Function(String?) onChanged, bool isReadOnly, {bool isMandatory = false}) {
    if (value != null && !items.any((e) => e['id'].toString() == value)) value = null;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      RichText(text: TextSpan(text: label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54), children: [if (isMandatory) const TextSpan(text: " *", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))])),
      const SizedBox(height: 8),
      Container(padding: const EdgeInsets.symmetric(horizontal: 15), decoration: BoxDecoration(color: isReadOnly ? Colors.grey[100] : const Color(0xFFF7F8FA), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
          child: DropdownButtonHideUnderline(child: DropdownButton<String>(
              value: value, isExpanded: true, hint: const Text("Pilih...", style: TextStyle(fontSize: 13, color: Colors.grey)),
              items: items.map<DropdownMenuItem<String>>((item) {
                String text = item['name'] ?? item['description'] ?? '-';
                return DropdownMenuItem<String>(value: item['id'].toString(), child: Text(text, style: const TextStyle(fontSize: 13)));
              }).toList(),
              onChanged: isReadOnly ? null : onChanged
          )))
    ]);
  }
}