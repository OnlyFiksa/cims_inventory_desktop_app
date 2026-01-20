import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart'; // 1. WAJIB IMPORT INI (Untuk InputFormatter)
import 'package:cims_app/services/transaction/transaksi_service.dart';

class StockInListView extends StatefulWidget {
  final String userRole;
  const StockInListView({super.key, required this.userRole});

  @override
  State<StockInListView> createState() => _StockInListViewState();
}

class _StockInListViewState extends State<StockInListView> {
  // COLORS
  final Color vosenDarkBlue = const Color(0xFF0A2A4D);
  final Color vosenRed = const Color(0xFFD32F2F);
  final Color bgGrey = const Color(0xFFF5F7FA);
  final Color colorReadOnly = const Color(0xFFE0E0E0);
  final Color colorEditable = Colors.white;

  // STATE
  bool _isFormVisible = false;
  bool _isEditing = false;

  // CONTROLLERS
  final _noTransCtrl = TextEditingController();
  final _tanggalCtrl = TextEditingController();
  final _noSuratJalanCtrl = TextEditingController();
  final _noPOCtrl = TextEditingController();
  final _penerimaCtrl = TextEditingController();
  final _keteranganCtrl = TextEditingController();

  final _namaBarangCtrl = TextEditingController();
  final _expiredDateCtrl = TextEditingController();
  final _noBetsCtrl = TextEditingController();

  final _valueKemasanCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _hargaSatuanCtrl = TextEditingController();
  final _totalCtrl = TextEditingController();

  // DROPDOWN VALUES
  String? _valPemilikId;
  String? _valManufakturId;
  String? _valSupplierId;
  String? _valItemId;
  String? _valKemasanId;
  String? _valUnitId;

  // DATA
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
    final data = await _service.getStockIn();
    if (mounted) setState(() => _trxList = data);
  }

  void _fetchDropdowns() async {
    final data = await _service.getDropdowns();
    if (mounted) setState(() => _dropdowns = data);
  }

  // ===========================================================================
  // LOGIC SIMPAN
  // ===========================================================================
  void _saveData() async {
    // 1. Validasi Kolom Wajib
    if (_tanggalCtrl.text.isEmpty || _valPemilikId == null || _valManufakturId == null ||
        _valSupplierId == null || _valItemId == null || _valKemasanId == null ||
        _valUnitId == null ||
        _qtyCtrl.text.isEmpty || _expiredDateCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Harap isi semua kolom bertanda (*)"), backgroundColor: Colors.red));
      return;
    }

    // 2. Validasi Angka Nol
    double qtyCheck = double.tryParse(_qtyCtrl.text) ?? 0;
    if (qtyCheck <= 0) {
      _showErrorDialog("Jumlah Qty harus lebih dari 0!");
      return;
    }

    try {
      // Format Tanggal
      String dateDb = DateFormat('yyyy-MM-dd').format(DateFormat('dd/MM/yyyy').parse(_tanggalCtrl.text));
      String expDb = DateFormat('yyyy-MM-dd').format(DateFormat('dd/MM/yyyy').parse(_expiredDateCtrl.text));

      // Bersihkan Format Uang (Rp dan Titik)
      String cleanPrice = _hargaSatuanCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '');
      String cleanTotal = _totalCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '');

      // Logic Status (Supervisor langsung Verified)
      String statusTrx = "pending";
      if (widget.userRole.toLowerCase() == 'supervisor') {
        statusTrx = "verified";
      }

      Map<String, String> data = {
        "trans_date": dateDb,
        "surat_jalan": _noSuratJalanCtrl.text,
        "po_number": _noPOCtrl.text,
        "recipient": _penerimaCtrl.text,
        "owner_id": _valPemilikId!,
        "manufacturer_id": _valManufakturId!,
        "supplier_id": _valSupplierId!,
        "item_id": _valItemId!,
        "packaging_id": _valKemasanId!,
        "qty_in": _qtyCtrl.text,
        "unit_id": _valUnitId!,
        "price": cleanPrice,
        "total_price": cleanTotal,
        "supplier_batch": _noBetsCtrl.text,
        "expired_date": expDb,
        "notes": _keteranganCtrl.text,
        "status": statusTrx
      };

      // 3. Panggil Service (Return Map)
      var result = await _service.addStockIn(data);

      if (result['success'] == true) {
        _fetchData();
        _showSuccessDialog("Stok masuk berhasil disimpan.");
        setState(() => _isFormVisible = false);
      } else {
        // Gagal dari Backend -> Tampilkan Popup Error
        _showErrorDialog(result['message'] ?? "Gagal menyimpan data.");
      }
    } catch (e) {
      _showErrorDialog("Error Format Data: $e");
    }
  }

  // ===========================================================================
  // UI BUILDER
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    return _isFormVisible ? _buildFormSection() : _buildListSection();
  }

  Widget _buildListSection() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      padding: const EdgeInsets.all(25),
      child: Column(children: [
        Row(children: [
          Text("Daftar Stok Masuk", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: vosenDarkBlue)),
          const Spacer(),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: vosenDarkBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
            onPressed: () { _resetForm(); setState(() { _isFormVisible = true; _isEditing = true; }); },
            icon: const Icon(Icons.add, size: 18), label: const Text("Input Stok"),
          )
        ]),
        const SizedBox(height: 20),
        Container(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15), decoration: BoxDecoration(color: bgGrey, borderRadius: BorderRadius.circular(8)), child: const Row(children: [
          Expanded(flex: 2, child: Text("NO. TRANS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          Expanded(flex: 2, child: Text("TANGGAL", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          Expanded(flex: 3, child: Text("NAMA BARANG", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          Expanded(flex: 1, child: Text("QTY", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          Expanded(flex: 2, child: Text("STATUS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
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
              Expanded(flex: 1, child: Text("${item['qty_in'] ?? '0'} ${item['unit_name'] ?? ''}", style: const TextStyle(fontSize: 13))),
              Expanded(flex: 2, child: _buildStatusBadge(item['status'] ?? 'pending')),
            ]),
          );
        },
        )
      ]),
    );
  }

  Widget _buildFormSection() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _isFormVisible = false)),
          const SizedBox(width: 10),
          Text(_isEditing ? "Input Stok Masuk" : "Detail Stok Masuk", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: vosenDarkBlue)),
        ]),
        const Divider(height: 30),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(children: [
            _buildInput("No. Transaksi", _noTransCtrl, isReadOnly: true),
            _buildInput("Tanggal", _tanggalCtrl, isDate: true, isMandatory: true),
            _buildInput("No. Surat Jalan", _noSuratJalanCtrl),
            _buildInput("No. PO", _noPOCtrl),
            _buildDropdown("Pemilik", _dropdowns['owners'] ?? [], _valPemilikId, (val) => setState(() => _valPemilikId = val), isMandatory: true),
            _buildDropdown("Manufaktur", _dropdowns['manufacturers'] ?? [], _valManufakturId, (val) => setState(() => _valManufakturId = val), isMandatory: true),
            _buildDropdown("Supplier", _dropdowns['suppliers'] ?? [], _valSupplierId, (val) => setState(() => _valSupplierId = val), isMandatory: true),
            _buildInput("Penerima", _penerimaCtrl),
            _buildInput("Keterangan", _keteranganCtrl, maxLines: 3),
          ])),
          const SizedBox(width: 30),
          Expanded(child: Column(children: [
            _buildDropdown("Kode Barang", _dropdowns['items'] ?? [], _valItemId, (val) {
              setState(() {
                _valItemId = val;
                var item = (_dropdowns['items'] as List).firstWhere((e) => e['id'].toString() == val, orElse: () => null);
                if (item != null) _namaBarangCtrl.text = item['name'];
              });
            }, isMandatory: true, displayCode: true),

            _buildInput("Nama Barang", _namaBarangCtrl, isReadOnly: true),

            Row(children: [
              Expanded(child: _buildDropdown("Kemasan", _dropdowns['packagings'] ?? [], _valKemasanId, (val) {
                setState(() {
                  _valKemasanId = val;
                  var pack = (_dropdowns['packagings'] as List).firstWhere((e) => e['id'].toString() == val, orElse: () => null);
                  if (pack != null) {
                    _valueKemasanCtrl.text = pack['value'].toString();
                  }
                });
              }, isMandatory: true)),
              const SizedBox(width: 15),
              Expanded(child: _buildInput("Value", _valueKemasanCtrl, isReadOnly: true)),
            ]),

            Row(children: [
              // Kolom Qty (Anti Minus)
              Expanded(child: _buildInput("Qty", _qtyCtrl, isMandatory: true, isNumber: true, onChanged: (_) => _calculateTotal())),
              const SizedBox(width: 15),
              Expanded(child: _buildDropdown("Satuan", _dropdowns['units'] ?? [], _valUnitId, (val) => setState(() => _valUnitId = val), isMandatory: true)),
            ]),

            _buildInput("Expired Date", _expiredDateCtrl, isDate: true, isMandatory: true),
            _buildInput("No. Bets", _noBetsCtrl),
            Row(children: [
              // Kolom Harga (Anti Minus)
              Expanded(child: _buildInput("Harga Satuan", _hargaSatuanCtrl, isNumber: true, onChanged: (_) => _calculateTotal())),
              const SizedBox(width: 15),
              Expanded(child: _buildInput("Total Harga", _totalCtrl, isReadOnly: true)),
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
  Widget _buildInput(String label, TextEditingController controller, {bool isReadOnly = false, int maxLines = 1, bool isDate = false, bool isMandatory = false, bool isNumber = false, Function(String)? onChanged}) {
    return Padding(padding: const EdgeInsets.only(bottom: 15), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildLabel(label, isMandatory), const SizedBox(height: 8),
      TextField(
          controller: controller,
          readOnly: isDate ? true : isReadOnly,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,

          // --- PROTEKSI INPUT ANGKA ---
          inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : null,

          maxLines: maxLines,
          onChanged: onChanged,
          onTap: isDate ? () => _selectDate(context, controller) : null,
          decoration: InputDecoration(filled: true, fillColor: (isReadOnly && !isDate) ? colorReadOnly : colorEditable, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)), contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15), suffixIcon: isDate ? const Icon(Icons.calendar_today, size: 18) : null)
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
        _totalCtrl.text = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(qty * harga);
      } catch (e) { _totalCtrl.text = "0"; }
    }
  }

  Widget _buildStatusBadge(String status) {
    Color bg = Colors.grey.shade200; Color text = Colors.grey.shade700;
    if (status == "verified") { bg = Colors.green.shade100; text = Colors.green.shade800; }
    else if (status == "pending") { bg = Colors.orange.shade100; text = Colors.orange.shade800; }
    return Container(padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)), child: Text(status.toUpperCase(), textAlign: TextAlign.center, style: TextStyle(color: text, fontSize: 11, fontWeight: FontWeight.bold)));
  }

  void _showSuccessDialog(String message) {
    showDialog(context: context, builder: (c) => AlertDialog(content: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.check_circle, color: Colors.green, size: 60), const SizedBox(height: 10), Text(message), const SizedBox(height: 10), ElevatedButton(onPressed: () => Navigator.pop(c), child: const Text("Tutup"))])));
  }

  // --- POPUP ERROR SPESIFIK ---
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
    _noTransCtrl.clear(); _tanggalCtrl.clear(); _noSuratJalanCtrl.clear(); _noPOCtrl.clear();
    _penerimaCtrl.clear(); _keteranganCtrl.clear(); _namaBarangCtrl.clear(); _expiredDateCtrl.clear();
    _noBetsCtrl.clear(); _valueKemasanCtrl.clear(); _qtyCtrl.clear(); _hargaSatuanCtrl.clear(); _totalCtrl.clear();
    _valPemilikId = null; _valManufakturId = null; _valSupplierId = null; _valItemId = null; _valKemasanId = null; _valUnitId = null;
  }
}