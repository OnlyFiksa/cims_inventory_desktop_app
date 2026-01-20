import 'package:flutter/material.dart';
import 'package:cims_app/services/master/appcode_service.dart';

class VolumePerKemasanView extends StatefulWidget {
  const VolumePerKemasanView({super.key});

  @override
  State<VolumePerKemasanView> createState() => _VolumePerKemasanViewState();
}

class _VolumePerKemasanViewState extends State<VolumePerKemasanView> {
  final Color vosenDarkBlue = const Color(0xFF0A2A4D);
  final Color vosenRed = const Color(0xFFD32F2F);
  final Color bgGrey = const Color(0xFFF5F7FA);

  bool _isFormVisible = false;
  bool _isEditing = false;
  String? _selectedId;
  Map<String, dynamic>? _selectedItem;

  // Controller
  final _kodeController = TextEditingController(); // Visual Saja (VPK-xxx)
  final _namaKemasanController = TextEditingController(); // "Botol Kaca"
  final _valueController = TextEditingController(); // "1"

  // Dropdown Satuan
  String? _selectedUnitId;
  List<dynamic> _unitsList = [];

  List<dynamic> _dataList = [];
  final AppCodeService _service = AppCodeService();

  @override
  void initState() {
    super.initState();
    _fetchData();
    _fetchUnits();
  }

  void _fetchData() async {
    final data = await _service.getPackagings();
    if (mounted) {
      setState(() {
        _dataList = data;
        _selectedId = null;
        _selectedItem = null;
      });
    }
  }

  void _fetchUnits() async {
    final units = await _service.getUnits();
    if (mounted) setState(() => _unitsList = units);
  }

  String _formatKode(String id) {
    if (id.isEmpty || id == "null") return "VPK-000";
    return "VPK-${id.padLeft(3, '0')}";
  }

  void _saveData() async {
    // Validasi Wajib Isi
    if (_namaKemasanController.text.isEmpty || _valueController.text.isEmpty || _selectedUnitId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nama, Value, dan Satuan wajib diisi!"), backgroundColor: Colors.red));
      return;
    }

    Map<String, String> data = {
      "name": _namaKemasanController.text,
      "value": _valueController.text,
      "unit_id": _selectedUnitId!,
    };

    bool success;
    if (_isEditing && _selectedId != null) {
      data['id'] = _selectedId!;
      success = await _service.updatePackaging(data);
    } else {
      success = await _service.addPackaging(data);
    }

    if (success) { _fetchData(); _resetForm(); }
  }

  void _deleteItem() async {
    if (_selectedId == null) return;
    showDialog(context: context, builder: (c) => AlertDialog(title: const Text("Hapus?"), content: Text("Hapus '${_selectedItem?['name']}'?"), actions: [
      TextButton(onPressed: () => Navigator.pop(c), child: const Text("Batal")),
      ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: vosenRed, foregroundColor: Colors.white), onPressed: () async {
        Navigator.pop(c);
        if (await _service.deletePackaging(_selectedId!)) { _fetchData(); _resetForm(); }
      }, child: const Text("Hapus"))
    ]));
  }

  void _onRowTap(Map<String, dynamic> item) {
    setState(() { _selectedId = item['id'].toString(); _selectedItem = item; });
    if (_isFormVisible) _fillForm();
  }

  void _fillForm() {
    if (_selectedItem != null) {
      _kodeController.text = _formatKode((_selectedItem!['id'] ?? 0).toString());
      _namaKemasanController.text = _selectedItem!['name'] ?? '';
      _valueController.text = (_selectedItem!['value'] ?? 0).toString();
      _selectedUnitId = (_selectedItem!['unit_id'] ?? '').toString();
    }
  }

  void _onAddPressed() {
    _resetForm();
    setState(() {
      _isFormVisible = true;
      _kodeController.text = "AUTO";
    });
  }

  void _onEditPressed() {
    setState(() { _isFormVisible = true; _isEditing = true; _fillForm(); });
  }

  void _resetForm() {
    _kodeController.clear(); _namaKemasanController.clear(); _valueController.clear();
    setState(() { _isFormVisible = false; _isEditing = false; _selectedId = null; _selectedUnitId = null; });
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [if (_isFormVisible) ...[_buildFormCard(), const SizedBox(height: 30)], _buildTableCard()]);
  }

  Widget _buildTableCard() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: vosenDarkBlue.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 5))]),
      padding: const EdgeInsets.all(30),
      child: Column(children: [
        Row(children: [
          Expanded(child: Container(height: 45, padding: const EdgeInsets.symmetric(horizontal: 15), decoration: BoxDecoration(color: bgGrey, borderRadius: BorderRadius.circular(10)), child: const Row(children: [Icon(Icons.search, color: Colors.grey), SizedBox(width: 10), Expanded(child: TextField(decoration: InputDecoration(border: InputBorder.none, hintText: "Cari kemasan...", isCollapsed: true)))]))),
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
          Expanded(flex: 2, child: Text("NAMA KEMASAN", style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 1, child: Text("VALUE", style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 1, child: Text("SATUAN", style: TextStyle(fontWeight: FontWeight.bold))),
        ])),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _dataList.length, itemBuilder: (context, index) {
          final item = _dataList[index];
          final isSelected = _selectedId == (item['id'] ?? 0).toString();

          String id = (item['id'] ?? 0).toString();
          String name = item['name'] ?? '-';
          String val = (item['value'] ?? 0).toString();
          String unitName = item['unit_name'] ?? '-';
          String unitCode = item['unit_code'] ?? '';

          return InkWell(onTap: () => _onRowTap(item), borderRadius: BorderRadius.circular(10), child: Container(
            margin: const EdgeInsets.only(bottom: 5), padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
            decoration: BoxDecoration(color: isSelected ? Colors.blue.withOpacity(0.05) : Colors.white, border: isSelected ? Border.all(color: Colors.blue.withOpacity(0.3)) : Border(bottom: BorderSide(color: Colors.grey.shade100))),
            child: Row(children: [
              Expanded(flex: 1, child: Text(_formatKode(id), style: TextStyle(fontWeight: FontWeight.bold, color: vosenDarkBlue))),
              Expanded(flex: 2, child: Text(name)),
              Expanded(flex: 1, child: Text(val)),
              Expanded(flex: 1, child: Text("$unitName ($unitCode)")),
            ]),
          ));
        },
        )
      ]),
    );
  }

  Widget _buildFormCard() {
    return Container(width: double.infinity, padding: const EdgeInsets.all(30), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: vosenDarkBlue.withOpacity(0.1))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(_isEditing ? "Edit Kemasan" : "Tambah Kemasan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: vosenDarkBlue)),
      const SizedBox(height: 20),
      Row(children: [
        // Kode (Read Only)
        Expanded(flex: 1, child: _buildTextField("Kode (Otomatis)", _kodeController, readOnly: true)),
        const SizedBox(width: 20),
        // Nama Kemasan (WAJIB *)
        Expanded(flex: 3, child: _buildTextField("Nama Kemasan (ex: Botol Kaca)", _namaKemasanController, isMandatory: true)),
      ]),
      const SizedBox(height: 20),
      Row(children: [
        // Value (WAJIB *)
        Expanded(child: _buildTextField("Value (Angka)", _valueController, isMandatory: true)),
        const SizedBox(width: 20),
        // Dropdown Satuan (WAJIB *)
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Label Satuan dengan Bintang Merah
          RichText(
              text: const TextSpan(
                  text: "Satuan Dasar",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54),
                  children: [TextSpan(text: " *", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))]
              )
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(color: const Color(0xFFF7F8FA), borderRadius: BorderRadius.circular(10)),
            child: DropdownButtonHideUnderline(child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedUnitId,
              hint: const Text("Pilih Satuan"),
              items: _unitsList.map<DropdownMenuItem<String>>((item) {
                return DropdownMenuItem<String>(value: item['id'].toString(), child: Text("${item['code']} - ${item['name']}"));
              }).toList(),
              onChanged: (val) => setState(() => _selectedUnitId = val),
            )),
          )
        ]))
      ]),
      const SizedBox(height: 25),
      Row(mainAxisAlignment: MainAxisAlignment.end, children: [TextButton(onPressed: _resetForm, child: const Text("Batal")), const SizedBox(width: 10), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: vosenDarkBlue, foregroundColor: Colors.white), onPressed: _saveData, child: Text(_isEditing ? "Update" : "Simpan"))])
    ]));
  }

  // Helper Input Field dengan Bintang Merah
  Widget _buildTextField(String label, TextEditingController controller, {bool readOnly = false, bool isMandatory = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      RichText(
          text: TextSpan(
              text: label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54),
              children: [
                if (isMandatory)
                  const TextSpan(text: " *", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
              ]
          )
      ),
      const SizedBox(height: 8),
      TextField(controller: controller, readOnly: readOnly, decoration: InputDecoration(filled: true, fillColor: readOnly ? Colors.grey[100] : const Color(0xFFF7F8FA), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)))
    ]);
  }
}