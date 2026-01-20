import 'package:flutter/material.dart';
import 'package:cims_app/services/master/appcode_service.dart';

class VolumeKemasanView extends StatefulWidget {
  const VolumeKemasanView({super.key});

  @override
  State<VolumeKemasanView> createState() => _VolumeKemasanViewState();
}

class _VolumeKemasanViewState extends State<VolumeKemasanView> {
  final Color vosenDarkBlue = const Color(0xFF0A2A4D);
  final Color vosenRed = const Color(0xFFD32F2F);
  final Color bgGrey = const Color(0xFFF5F7FA);

  bool _isFormVisible = false;
  bool _isEditing = false;
  String? _selectedId;
  Map<String, dynamic>? _selectedItem;

  // Controller
  final _kodeController = TextEditingController(); // Manual (kg, L)
  final _namaController = TextEditingController(); // Nama (Kilogram, Liter)
  final _deskripsiController = TextEditingController(); // Deskripsi

  List<dynamic> _dataList = [];
  final AppCodeService _service = AppCodeService();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    final data = await _service.getUnits();
    setState(() { _dataList = data; _selectedId = null; _selectedItem = null; });
  }

  void _saveData() async {
    // Validasi Wajib Isi
    if (_namaController.text.trim().isEmpty || _kodeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kode & Nama Satuan wajib diisi!"), backgroundColor: Colors.red));
      return;
    }

    Map<String, String> data = {
      "code": _kodeController.text.trim(), // Simpan apa adanya (bisa huruf kecil/besar)
      "name": _namaController.text.trim(),
      "description": _deskripsiController.text.trim(), // Field baru
    };

    bool success;
    if (_isEditing) {
      data['id'] = _selectedId!;
      success = await _service.updateUnit(data);
    } else {
      success = await _service.addUnit(data);
    }

    if (success) { _fetchData(); _resetForm(); }
  }

  void _deleteItem() async {
    if (_selectedId == null) return;
    showDialog(context: context, builder: (c) => AlertDialog(title: const Text("Hapus?"), content: Text("Hapus satuan '${_selectedItem?['name']}'?"), actions: [
      TextButton(onPressed: () => Navigator.pop(c), child: const Text("Batal")),
      ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: vosenRed, foregroundColor: Colors.white), onPressed: () async {
        Navigator.pop(c);
        if (await _service.deleteUnit(_selectedId!)) { _fetchData(); _resetForm(); }
      }, child: const Text("Hapus"))
    ]));
  }

  void _onRowTap(Map<String, dynamic> item) {
    setState(() { _selectedId = item['id'].toString(); _selectedItem = item; });
    if (_isFormVisible) _fillForm();
  }

  void _fillForm() {
    if (_selectedItem != null) {
      _kodeController.text = _selectedItem!['code'];
      _namaController.text = _selectedItem!['name'];
      _deskripsiController.text = _selectedItem!['description'] ?? '';
    }
  }

  void _onAddPressed() {
    _resetForm();
    setState(() { _isFormVisible = true; });
  }

  void _onEditPressed() {
    setState(() { _isFormVisible = true; _isEditing = true; _fillForm(); });
  }

  void _resetForm() {
    _kodeController.clear(); _namaController.clear(); _deskripsiController.clear();
    setState(() { _isFormVisible = false; _isEditing = false; _selectedId = null; });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_isFormVisible) ...[_buildFormCard(), const SizedBox(height: 30)],
        _buildTableCard(),
      ],
    );
  }

  Widget _buildTableCard() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: vosenDarkBlue.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 5))]),
      padding: const EdgeInsets.all(30),
      child: Column(children: [
        Row(children: [
          Expanded(child: Container(height: 45, padding: const EdgeInsets.symmetric(horizontal: 15), decoration: BoxDecoration(color: bgGrey, borderRadius: BorderRadius.circular(10)), child: const Row(children: [Icon(Icons.search, color: Colors.grey), SizedBox(width: 10), Expanded(child: TextField(decoration: InputDecoration(border: InputBorder.none, hintText: "Cari satuan...", isCollapsed: true)))]))),
          const SizedBox(width: 20),
          if (_selectedId != null) ...[
            ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: vosenRed.withOpacity(0.1), foregroundColor: vosenRed, elevation: 0), onPressed: _deleteItem, icon: const Icon(Icons.delete_outline), label: const Text("Hapus")),
            const SizedBox(width: 10),
            ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.withOpacity(0.1), foregroundColor: Colors.orange[800], elevation: 0), onPressed: _onEditPressed, icon: const Icon(Icons.edit_outlined), label: const Text("Edit")),
            const SizedBox(width: 10),
          ],
          ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: vosenDarkBlue, foregroundColor: Colors.white, elevation: 0), onPressed: _onAddPressed, icon: const Icon(Icons.add), label: const Text("Tambah")),
        ]),
        const SizedBox(height: 25),
        Container(padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15), decoration: BoxDecoration(color: bgGrey, borderRadius: BorderRadius.circular(10)), child: const Row(children: [
          Expanded(flex: 1, child: Text("KODE", style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text("NAMA SATUAN", style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 3, child: Text("DESKRIPSI", style: TextStyle(fontWeight: FontWeight.bold))),
        ])),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _dataList.length, itemBuilder: (context, index) {
          final item = _dataList[index];
          final isSelected = _selectedId == item['id'].toString();
          return InkWell(onTap: () => _onRowTap(item), borderRadius: BorderRadius.circular(10), child: Container(
            margin: const EdgeInsets.only(bottom: 5), padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
            decoration: BoxDecoration(color: isSelected ? Colors.blue.withOpacity(0.05) : Colors.white, border: isSelected ? Border.all(color: Colors.blue.withOpacity(0.3)) : Border(bottom: BorderSide(color: Colors.grey.shade100))),
            child: Row(children: [
              Expanded(flex: 1, child: Text(item['code'], style: TextStyle(fontWeight: FontWeight.bold, color: vosenDarkBlue))),
              Expanded(flex: 2, child: Text(item['name'])),
              Expanded(flex: 3, child: Text(item['description'] ?? '-')),
            ]),
          ));
        },
        )
      ]),
    );
  }

  Widget _buildFormCard() {
    return Container(width: double.infinity, padding: const EdgeInsets.all(30), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: vosenDarkBlue.withOpacity(0.1))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(_isEditing ? "Edit Satuan" : "Tambah Satuan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: vosenDarkBlue)),
      const SizedBox(height: 20),
      Row(children: [
        // MANUAL INPUT
        Expanded(flex: 1, child: _buildTextField("Kode (ex: kg, L)", _kodeController, isMandatory: true)),
        const SizedBox(width: 20),
        Expanded(flex: 2, child: _buildTextField("Nama Satuan", _namaController, isMandatory: true)),
      ]),
      const SizedBox(height: 20),
      _buildTextField("Deskripsi", _deskripsiController),
      const SizedBox(height: 25),
      Row(mainAxisAlignment: MainAxisAlignment.end, children: [TextButton(onPressed: _resetForm, child: const Text("Batal")), const SizedBox(width: 10), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: vosenDarkBlue, foregroundColor: Colors.white), onPressed: _saveData, child: Text(_isEditing ? "Update" : "Simpan"))])
    ]));
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool readOnly = false, bool isMandatory = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      RichText(text: TextSpan(text: label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54), children: [if (isMandatory) const TextSpan(text: " *", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))])),
      const SizedBox(height: 8),
      TextField(controller: controller, readOnly: readOnly, decoration: InputDecoration(filled: true, fillColor: readOnly ? Colors.grey[100] : const Color(0xFFF7F8FA), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)))
    ]);
  }
}