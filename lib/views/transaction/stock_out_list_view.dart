import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart'; // Wajib untuk InputFormatter
import 'package:cims_app/services/transaction/transaksi_service.dart';

class StockOutListView extends StatefulWidget {
  const StockOutListView({super.key});

  @override
  State<StockOutListView> createState() => _StockOutListViewState();
}

class _StockOutListViewState extends State<StockOutListView> {
  // --- COLORS ---
  final Color vosenDarkBlue = const Color(0xFF0A2A4D);
  final Color vosenRed = const Color(0xFFD32F2F);
  final Color bgGrey = const Color(0xFFF5F7FA);
  final Color colorReadOnly = const Color(0xFFE0E0E0);
  final Color colorEditable = Colors.white;

  // --- STATE ---
  bool _isFormVisible = false;
  bool _isEditing = false;

  // --- CONTROLLERS ---
  final _noTransCtrl = TextEditingController();
  final _tanggalCtrl = TextEditingController();
  final _dibuatOlehCtrl = TextEditingController();
  final _deskripsiCtrl = TextEditingController();

  final _namaBarangCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _satuanCtrl = TextEditingController();
  final _hargaSatuanCtrl = TextEditingController();
  final _totalHargaCtrl = TextEditingController();
  final _inUseExpDateCtrl = TextEditingController();
  final _noQCCtrl = TextEditingController();

  // --- DROPDOWN VALUES ---
  String? _valPemilikId;
  String? _valItemId;
  String? _valUnitId;

  // --- DATA ---
  List<dynamic> _trxList = [];
  Map<String, List<dynamic>> _dropdowns = {};

  final TransaksiService _service = TransaksiService();

  @override
  void initState() {
    super.initState();
    _fetchData();
    _fetchDropdowns();
  }

  void _fetchData() async {
    final data = await _service.getStockOut();
    if (mounted) setState(() => _trxList = data);
  }

  void _fetchDropdowns() async {
    final data = await _service.getStockOutDropdowns();
    if (mounted) setState(() => _dropdowns = data);
  }

  // ===========================================================================
  // LOGIC SIMPAN DATA
  // ===========================================================================
  void _saveData() async {
    // 1. Validasi Kolom Wajib
    if (_tanggalCtrl.text.isEmpty || _valPemilikId == null || _valItemId == null ||
        _qtyCtrl.text.isEmpty || _valUnitId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Harap isi semua kolom bertanda (*)"), backgroundColor: Colors.red));
      return;
    }

    // 2. Validasi Angka Nol / Negatif
    double qtyCheck = double.tryParse(_qtyCtrl.text) ?? 0;
    if (qtyCheck <= 0) {
      _showErrorDialog("Jumlah barang harus lebih dari 0!");
      return;
    }

    try {
      // Format Tanggal ke DB (YYYY-MM-DD)
      String dateDb = DateFormat('yyyy-MM-dd').format(DateFormat('dd/MM/yyyy').parse(_tanggalCtrl.text));
      String inUseDb = "";
      if (_inUseExpDateCtrl.text.isNotEmpty) {
        inUseDb = DateFormat('yyyy-MM-dd').format(DateFormat('dd/MM/yyyy').parse(_inUseExpDateCtrl.text));
      }

      // Bersihkan Format Harga
      String cleanPrice = _hargaSatuanCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '');
      String cleanTotal = _totalHargaCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '');

      Map<String, String> data = {
        "trans_date": dateDb,
        "owner_id": _valPemilikId!,
        "created_by": _dibuatOlehCtrl.text,
        "description": _deskripsiCtrl.text,
        "item_id": _valItemId!,
        "qty_out": _qtyCtrl.text,
        "unit_id": _valUnitId!,
        "in_use_exp_date": inUseDb,
        "qc_number": _noQCCtrl.text,
        "price": cleanPrice,
        "total_price": cleanTotal,
      };

      // 3. Panggil Service
      var result = await _service.addStockOut(data);

      if (result['success'] == true) {
        // SUKSES
        _fetchData();
        _showSuccessDialog("Stok keluar berhasil disimpan.\nStok barang telah dikurangi.");
        setState(() => _isFormVisible = false);
      } else {
        // GAGAL DARI BACKEND (Misal: Stok Tidak Cukup)
        // Tampilkan Pesan Spesifik dari PHP di Popup Tengah
        _showErrorDialog(result['message'] ?? "Terjadi kesalahan pada sistem.");
      }
    } catch (e) {
      _showErrorDialog("Format data salah: $e");
    }
  }

  // ===========================================================================
  // UI BUILDER
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    return _isFormVisible ? _buildFormSection() : _buildListSection();
  }

  // --- LIST VIEW ---
  Widget _buildListSection() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      padding: const EdgeInsets.all(25),
      child: Column(children: [
        Row(children: [
          Text("Daftar Stok Keluar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: vosenDarkBlue)),
          const Spacer(),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: vosenDarkBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
            onPressed: () { _resetForm(); setState(() { _isFormVisible = true; _isEditing = true; }); },
            icon: const Icon(Icons.remove_circle_outline, size: 18), label: const Text("Input Keluar"),
          )
        ]),
        const SizedBox(height: 20),
        Container(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15), decoration: BoxDecoration(color: bgGrey, borderRadius: BorderRadius.circular(8)), child: const Row(children: [
          Expanded(flex: 2, child: Text("NO. TRANS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          Expanded(flex: 2, child: Text("TANGGAL", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          Expanded(flex: 3, child: Text("NAMA BARANG", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          Expanded(flex: 1, child: Text("QTY", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          Expanded(flex: 2, child: Text("TOTAL HARGA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        ])),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _trxList.length, itemBuilder: (context, index) {
          final item = _trxList[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 5), padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
            child: Row(children: [
              Expanded(flex: 2, child: Text(item['trans_no'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
              Expanded(flex: 2, child: Text(item['trans_date'] ?? '-', style: const TextStyle(fontSize: 13))),
              Expanded(flex: 3, child: Text(item['item_name'] ?? '-', style: const TextStyle(fontSize: 13))),
              Expanded(flex: 1, child: Text("${item['qty_out'] ?? '0'} ${item['unit_name'] ?? ''}", style: const TextStyle(fontSize: 13))),
              Expanded(flex: 2, child: Text("Rp ${NumberFormat('#,###').format(double.tryParse(item['total_price'].toString()) ?? 0)}", style: TextStyle(color: vosenDarkBlue, fontWeight: FontWeight.bold, fontSize: 13))),
            ]),
          );
        },
        )
      ]),
    );
  }

  // --- FORM INPUT ---
  Widget _buildFormSection() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(children: [
        Row(children: [
          IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _isFormVisible = false)),
          const SizedBox(width: 10),
          Text(_isEditing ? "Input Stok Keluar" : "Detail Stok Keluar", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: vosenDarkBlue)),
        ]),
        const Divider(height: 30),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(children: [
            _buildInput("No. Transaksi", _noTransCtrl, isReadOnly: true, color: colorReadOnly),
            _buildInput("Tanggal", _tanggalCtrl, isDate: true, isMandatory: true),
            _buildDropdown("Pemilik", _dropdowns['owners'] ?? [], _valPemilikId, (val) => setState(() => _valPemilikId = val), isMandatory: true),
            _buildInput("Dibuat Oleh", _dibuatOlehCtrl),
            _buildInput("Keperluan / Deskripsi", _deskripsiCtrl, maxLines: 3),
          ])),
          const SizedBox(width: 30),
          Expanded(child: Column(children: [
            _buildDropdown("Kode Barang", _dropdowns['items'] ?? [], _valItemId, (val) {
              setState(() {
                _valItemId = val;
                // Auto Fill Nama & Satuan
                var item = (_dropdowns['items'] as List).firstWhere((e) => e['id'].toString() == val, orElse: () => null);
                if (item != null) {
                  _namaBarangCtrl.text = item['name'] ?? '-';
                  _satuanCtrl.text = item['unit_name'] ?? '-';
                  _valUnitId = item['unit_id']?.toString();
                }
              });
            }, isMandatory: true, displayCode: true),

            _buildInput("Nama Barang", _namaBarangCtrl, isReadOnly: true, color: colorReadOnly),

            Row(children: [
              // Kolom Qty dengan Logic Hitung Total
              Expanded(child: _buildInput("Qty Keluar", _qtyCtrl, isMandatory: true, isNumber: true, onChanged: (_) => _calculateTotal())),
              const SizedBox(width: 15),
              Expanded(child: _buildInput("Satuan", _satuanCtrl, isReadOnly: true, color: colorReadOnly)),
            ]),

            _buildInput("In-Use Exp. Date", _inUseExpDateCtrl, isDate: true),
            _buildInput("No. QC (Opsional)", _noQCCtrl),

            Row(children: [
              Expanded(child: _buildInput("Harga Satuan", _hargaSatuanCtrl, isNumber: true, onChanged: (_) => _calculateTotal())),
              const SizedBox(width: 15),
              Expanded(child: _buildInput("Total Harga", _totalHargaCtrl, isReadOnly: true, color: colorReadOnly)),
            ]),
          ])),
        ]),
        const SizedBox(height: 30),
        Align(alignment: Alignment.centerRight, child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: vosenDarkBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)), onPressed: _saveData, icon: const Icon(Icons.save), label: const Text("Simpan")))
      ]),
    );
  }

  // ===========================================================================
  // WIDGET HELPERS
  // ===========================================================================

  Widget _buildLabel(String label, bool isMandatory) {
    return RichText(text: TextSpan(text: label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54), children: [if (isMandatory) TextSpan(text: " *", style: TextStyle(color: vosenRed, fontWeight: FontWeight.bold))]));
  }

  // Helper Input dengan Proteksi Angka
  Widget _buildInput(String label, TextEditingController controller, {bool isReadOnly = false, Color? color, int maxLines = 1, bool isDate = false, bool isMandatory = false, bool isNumber = false, Function(String)? onChanged}) {
    Color backColor = color ?? (isReadOnly ? colorReadOnly : colorEditable);
    return Padding(padding: const EdgeInsets.only(bottom: 15), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildLabel(label, isMandatory), const SizedBox(height: 8),
      TextField(
          controller: controller,
          readOnly: isDate ? true : isReadOnly,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,

          // PROTEKSI INPUT: Hanya Angka, Tolak Minus & Titik
          inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : null,

          maxLines: maxLines,
          onChanged: onChanged,
          onTap: isDate ? () => _selectDate(context, controller) : null,
          decoration: InputDecoration(filled: true, fillColor: backColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)), contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15), suffixIcon: isDate ? const Icon(Icons.calendar_today, size: 18) : null)
      )
    ]));
  }

  Widget _buildDropdown(String label, List<dynamic> items, String? value, Function(String?) onChanged, {bool isMandatory = false, bool displayCode = false}) {
    if (value != null && !items.any((e) => e['id'].toString() == value)) value = null;
    return Padding(padding: const EdgeInsets.only(bottom: 15), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildLabel(label, isMandatory), const SizedBox(height: 8),
      Container(padding: const EdgeInsets.symmetric(horizontal: 15), decoration: BoxDecoration(color: colorEditable, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)), child: DropdownButtonHideUnderline(child: DropdownButton<String>(
          value: value, isExpanded: true, hint: const Text("Pilih...", style: TextStyle(fontSize: 13, color: Colors.grey)),
          items: items.map<DropdownMenuItem<String>>((item) {
            String text = displayCode ? (item['code'] ?? '-') : (item['name'] ?? item['description'] ?? '-');
            return DropdownMenuItem<String>(value: item['id'].toString(), child: Text(text, style: const TextStyle(fontSize: 13)));
          }).toList(),
          onChanged: onChanged
      )))
    ]));
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2101));
    if (picked != null) setState(() => controller.text = DateFormat('dd/MM/yyyy').format(picked));
  }

  void _calculateTotal() {
    if (_qtyCtrl.text.isNotEmpty && _hargaSatuanCtrl.text.isNotEmpty) {
      try {
        double qty = double.parse(_qtyCtrl.text);
        double harga = double.parse(_hargaSatuanCtrl.text);
        _totalHargaCtrl.text = "Rp ${(qty * harga).toStringAsFixed(0)}";
      } catch (e) { _totalHargaCtrl.text = "0"; }
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(context: context, builder: (c) => AlertDialog(content: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.check_circle, color: Colors.green, size: 80), const SizedBox(height: 20), const Text("Berhasil!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), const SizedBox(height: 10), Text(message), const SizedBox(height: 20), ElevatedButton(onPressed: () => Navigator.pop(c), child: const Text("Tutup"))])));
  }

  // --- POPUP ERROR KHUSUS ---
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text("Gagal Simpan", style: TextStyle(color: Colors.red)),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 16)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    _noTransCtrl.clear(); _tanggalCtrl.clear(); _dibuatOlehCtrl.clear(); _deskripsiCtrl.clear();
    _namaBarangCtrl.clear(); _qtyCtrl.clear(); _satuanCtrl.clear(); _hargaSatuanCtrl.clear(); _totalHargaCtrl.clear(); _inUseExpDateCtrl.clear(); _noQCCtrl.clear();
    _valPemilikId = null; _valItemId = null; _valUnitId = null;
  }
}