import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cims_app/services/transaction/transaksi_service.dart';

class VerificationListView extends StatefulWidget {
  const VerificationListView({super.key});

  @override
  State<VerificationListView> createState() => _VerificationListViewState();
}

class _VerificationListViewState extends State<VerificationListView> {
  // COLORS
  final Color vosenDarkBlue = const Color(0xFF0A2A4D);
  final Color verifyGreen = const Color(0xFF2E7D32);
  final Color vosenRed = const Color(0xFFD32F2F);
  final Color bgGrey = const Color(0xFFF5F7FA);
  final Color colorReadOnly = const Color(0xFFE0E0E0);
  final Color colorEditable = Colors.white;

  // STATE
  bool _isFormVisible = false;
  String? _selectedId; // ID Transaksi Database
  Map<String, dynamic>? _selectedItem;

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
  final _satuanCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _hargaSatuanCtrl = TextEditingController();
  final _totalCtrl = TextEditingController();

  // DROPDOWN
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

    // Listener untuk Hitung Otomatis Total Harga
    _qtyCtrl.addListener(_calculateTotal);
    _hargaSatuanCtrl.addListener(_calculateTotal);
  }

  @override
  void dispose() {
    _qtyCtrl.removeListener(_calculateTotal);
    _hargaSatuanCtrl.removeListener(_calculateTotal);
    super.dispose();
  }

  void _calculateTotal() {
    if (_isFormVisible) {
      double qty = double.tryParse(_qtyCtrl.text) ?? 0;
      double price = double.tryParse(_hargaSatuanCtrl.text) ?? 0;
      double total = qty * price;
      if (_totalCtrl.text != total.toString()) {
        _totalCtrl.text = total.toStringAsFixed(0);
      }
    }
  }

  void _fetchData() async {
    final data = await _service.getStockIn();
    if (mounted) setState(() => _trxList = data);
  }

  void _fetchDropdowns() async {
    final data = await _service.getDropdowns();
    if (mounted) setState(() => _dropdowns = data);
  }

  // --- DATE PICKER LOGIC ---
  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    DateTime initial = DateTime.now();
    // Coba parsing tanggal lama jika ada isinya
    if (controller.text.isNotEmpty) {
      try { initial = DateFormat('dd/MM/yyyy').parse(controller.text); } catch (_) {}
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: vosenDarkBlue),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        controller.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  // --- LOGIC VERIFIKASI & SAVE ---
  void _verifyData() async {
    if (_selectedId == null) return;

    // 1. VALIDASI WAJIB DIISI
    if (_tanggalCtrl.text.isEmpty ||
        _valItemId == null ||
        _qtyCtrl.text.isEmpty ||
        _valUnitId == null ||
        _expiredDateCtrl.text.isEmpty ||
        _hargaSatuanCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Harap lengkapi semua kolom bertanda * (Wajib)!"), backgroundColor: Colors.red),
      );
      return;
    }

    // 2. Kumpulkan Data Revisi
    Map<String, String> data = {
      'trx_id': _selectedId!,
      'id': _selectedId!,
      'trans_date': _formatDateForDB(_tanggalCtrl.text),
      'surat_jalan': _noSuratJalanCtrl.text,
      'po_number': _noPOCtrl.text,
      'owner_id': _valPemilikId ?? '',
      'manufacturer_id': _valManufakturId ?? '',
      'supplier_id': _valSupplierId ?? '',
      'recipient': _penerimaCtrl.text,
      'notes': _keteranganCtrl.text,
      'item_id': _valItemId ?? '',
      'packaging_id': _valKemasanId ?? '',
      'qty_in': _qtyCtrl.text,
      'unit_id': _valUnitId ?? '',
      'expired_date': _formatDateForDB(_expiredDateCtrl.text),
      'supplier_batch': _noBetsCtrl.text,
      'price': _hargaSatuanCtrl.text,
    };

    bool success = await _service.verifyStockIn(data);

    if (success) {
      _fetchData();
      _showSuccessDialog("Data berhasil diverifikasi & masuk stok.");
      setState(() => _isFormVisible = false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal verifikasi"), backgroundColor: Colors.red));
    }
  }

  String _formatDateForDB(String uiDate) {
    try {
      return DateFormat('yyyy-MM-dd').format(DateFormat('dd/MM/yyyy').parse(uiDate));
    } catch (e) { return uiDate; }
  }

  void _openVerification(Map<String, dynamic> item) {
    setState(() {
      _selectedId = item['id'].toString();
      _selectedItem = item;
      _isFormVisible = true;

      _noTransCtrl.text = item['trans_no'] ?? '';

      if (item['trans_date'] != null) {
        try {
          _tanggalCtrl.text = DateFormat('dd/MM/yyyy').format(DateTime.parse(item['trans_date']));
        } catch(e) { _tanggalCtrl.text = ''; }
      } else { _tanggalCtrl.text = ''; }

      _noSuratJalanCtrl.text = item['surat_jalan'] ?? '';
      _noPOCtrl.text = item['po_number'] ?? '';
      _penerimaCtrl.text = item['recipient'] ?? '';
      _keteranganCtrl.text = item['notes'] ?? '';
      _namaBarangCtrl.text = item['item_name'] ?? '';
      _qtyCtrl.text = (item['qty_in'] ?? 0).toString();

      if (item['expired_date'] != null) {
        try {
          _expiredDateCtrl.text = DateFormat('dd/MM/yyyy').format(DateTime.parse(item['expired_date']));
        } catch(e) { _expiredDateCtrl.text = ''; }
      } else { _expiredDateCtrl.text = ''; }

      _noBetsCtrl.text = item['supplier_batch'] ?? '';
      _hargaSatuanCtrl.text = (item['price'] ?? 0).toString();
      _totalCtrl.text = (item['total_price'] ?? 0).toString();

      _valPemilikId = item['owner_id']?.toString();
      _valManufakturId = item['manufacturer_id']?.toString();
      _valSupplierId = item['supplier_id']?.toString();
      _valItemId = item['item_id']?.toString();
      _valKemasanId = item['packaging_id']?.toString();
      _valUnitId = item['unit_id']?.toString();

      _valueKemasanCtrl.text = item['packaging_value'] ?? '';
      _satuanCtrl.text = item['unit_name'] ?? '';
    });
  }

  // --- UI ---
  @override
  Widget build(BuildContext context) {
    return _isFormVisible ? _buildVerificationForm() : _buildListSection();
  }

  Widget _buildListSection() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      padding: const EdgeInsets.all(25),
      child: Column(
        children: [
          Row(children: [
            Text("Daftar Verifikasi Stok Masuk", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: vosenDarkBlue)),
            const Spacer(),
            Chip(label: Text("Total: ${_trxList.length}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), backgroundColor: vosenDarkBlue)
          ]),
          const SizedBox(height: 20),
          Container(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15), decoration: BoxDecoration(color: bgGrey, borderRadius: BorderRadius.circular(8)), child: const Row(children: [
            Expanded(flex: 2, child: Text("NO. TRANS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            Expanded(flex: 2, child: Text("TANGGAL", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            Expanded(flex: 3, child: Text("NAMA BARANG", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            Expanded(flex: 1, child: Text("QTY", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            Expanded(flex: 2, child: Text("STATUS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            SizedBox(width: 80, child: Text("AKSI", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          ])),
          const SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _trxList.length, itemBuilder: (context, index) {
            final item = _trxList[index];

            String noTrans = item['trans_no'] ?? '-';
            String tgl = item['trans_date'] ?? '-';
            String namaBarang = item['item_name'] ?? 'Item Terhapus / Tidak Ditemukan';
            String qty = (item['qty_in'] ?? 0).toString();
            String status = item['status'] ?? 'unknown';

            return Container(
              margin: const EdgeInsets.only(bottom: 5), padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
              child: Row(children: [
                Expanded(flex: 2, child: Text(noTrans, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                Expanded(flex: 2, child: Text(tgl, style: const TextStyle(fontSize: 13))),
                Expanded(flex: 3, child: Text(namaBarang, style: const TextStyle(fontSize: 13, color: Colors.black87))),
                Expanded(flex: 1, child: Text(qty, style: const TextStyle(fontSize: 13))),
                Expanded(flex: 2, child: _buildStatusBadge(status)),
                SizedBox(width: 80, child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: vosenDarkBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), minimumSize: const Size(0, 0)),
                    onPressed: () => _openVerification(item), child: const Text("Detail", style: TextStyle(fontSize: 11))
                )),
              ]),
            );
          },
          )
        ],
      ),
    );
  }

  Widget _buildVerificationForm() {
    // Cek apakah form terkunci (sudah verified)
    bool isAlreadyVerified = _selectedItem?['status'] == 'verified';
    bool isFormLocked = isAlreadyVerified;

    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(children: [
        Row(children: [
          IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _isFormVisible = false)),
          const SizedBox(width: 10),
          Text(isAlreadyVerified ? "Detail (Sudah Diverifikasi)" : "Verifikasi & Revisi Data", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: vosenDarkBlue)),
          const Spacer(),
          _buildStatusBadge(_selectedItem?['status'] ?? 'pending')
        ]),
        const Divider(height: 30),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(children: [
            _buildInput("No. Transaksi", _noTransCtrl, isReadOnly: true, color: colorReadOnly),

            // --- PERBAIKAN TANGGAL DISINI ---
            _buildInput("Tanggal", _tanggalCtrl,
                // Logic: Secara fungsi ReadOnly (biar keyboard ga muncul),
                // TAPI secara Visual warnanya PUTIH (colorEditable) kalau form belum dikunci.
                isReadOnly: true,
                color: isFormLocked ? colorReadOnly : colorEditable,
                isMandatory: true, isDate: true,
                onTap: isFormLocked ? null : () => _selectDate(context, _tanggalCtrl)),
            // --------------------------------

            _buildInput("No. Surat Jalan", _noSuratJalanCtrl, isReadOnly: isFormLocked),
            _buildInput("No. PO", _noPOCtrl, isReadOnly: isFormLocked),

            _buildDropdown("Pemilik", _dropdowns['owners'] ?? [], _valPemilikId, (val) => setState(() => _valPemilikId = val), isEnabled: !isFormLocked),
            _buildDropdown("Manufaktur", _dropdowns['manufacturers'] ?? [], _valManufakturId, (val) => setState(() => _valManufakturId = val), isEnabled: !isFormLocked),
            _buildDropdown("Supplier", _dropdowns['suppliers'] ?? [], _valSupplierId, (val) => setState(() => _valSupplierId = val), isEnabled: !isFormLocked),

            _buildInput("Penerima", _penerimaCtrl, isReadOnly: isFormLocked),
            _buildInput("Keterangan", _keteranganCtrl, maxLines: 3, isReadOnly: isFormLocked),
          ])),
          const SizedBox(width: 30),
          Expanded(child: Column(children: [
            _buildDropdown("Kode Barang", _dropdowns['items'] ?? [], _valItemId, (val) {
              setState(() {
                _valItemId = val;
                var item = _dropdowns['items']?.firstWhere((e) => e['id'].toString() == val, orElse: () => null);
                if (item != null) _namaBarangCtrl.text = item['name'] ?? '';
              });
            }, isEnabled: !isFormLocked, displayCode: true, isMandatory: true),

            _buildInput("Nama Barang", _namaBarangCtrl, isReadOnly: true, color: colorReadOnly),

            Row(children: [
              Expanded(child: _buildDropdown("Kemasan", _dropdowns['packagings'] ?? [], _valKemasanId, (val) {
                setState(() {
                  _valKemasanId = val;
                  var item = _dropdowns['packagings']?.firstWhere((e) => e['id'].toString() == val, orElse: () => null);
                  if (item != null) _valueKemasanCtrl.text = item['value'] ?? '';
                });
              }, isEnabled: !isFormLocked, isMandatory: true)),
              const SizedBox(width: 15),
              Expanded(child: _buildInput("Value", _valueKemasanCtrl, isReadOnly: true, color: colorReadOnly)),
            ]),

            Row(children: [
              Expanded(child: _buildInput("Qty", _qtyCtrl, isReadOnly: isFormLocked, isMandatory: true)),
              const SizedBox(width: 15),
              Expanded(child: _buildDropdown("Satuan", _dropdowns['units'] ?? [], _valUnitId, (val) {
                setState(() {
                  _valUnitId = val;
                  var item = _dropdowns['units']?.firstWhere((e) => e['id'].toString() == val, orElse: () => null);
                  if (item != null) _satuanCtrl.text = item['name'] ?? '';
                });
              }, isEnabled: !isFormLocked, isMandatory: true)),
            ]),

            // --- PERBAIKAN EXPIRED DATE DISINI ---
            _buildInput("Expired Date", _expiredDateCtrl,
                isReadOnly: true,
                color: isFormLocked ? colorReadOnly : colorEditable,
                isMandatory: true, isDate: true,
                onTap: isFormLocked ? null : () => _selectDate(context, _expiredDateCtrl)),
            // -------------------------------------

            _buildInput("No. Bets", _noBetsCtrl, isReadOnly: isFormLocked),

            Row(children: [
              Expanded(child: _buildInput("Harga Satuan", _hargaSatuanCtrl, isReadOnly: isFormLocked, isMandatory: true),),
              const SizedBox(width: 15),
              Expanded(child: _buildInput("Total Harga", _totalCtrl, isReadOnly: true, color: colorReadOnly)),
            ]),
          ])),
        ]),
        const SizedBox(height: 30),
        if (!isAlreadyVerified)
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: verifyGreen, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15)),
                onPressed: () => _confirmAction("Verifikasi Data", "Pastikan data sudah benar. Verifikasi sekarang?", _verifyData),
                icon: const Icon(Icons.check_circle_outline), label: const Text("SIMPAN & VERIFIKASI"))
          ])
      ]),
    );
  }

  // --- HELPERS (UI) ---
  Widget _buildLabel(String label, bool isMandatory) {
    return RichText(
      text: TextSpan(
          text: label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54),
          children: [
            if (isMandatory) const TextSpan(text: " *", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
          ]
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller, {
    bool isReadOnly = false,
    Color? color,
    int maxLines = 1,
    bool isDate = false,
    bool isMandatory = false,
    VoidCallback? onTap
  }) {
    Color backColor = color ?? (isReadOnly ? colorReadOnly : colorEditable);
    return Padding(padding: const EdgeInsets.only(bottom: 15), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildLabel(label, isMandatory),
      const SizedBox(height: 8),
      TextField(
          controller: controller,
          readOnly: isReadOnly,
          onTap: onTap, // Aksi saat diklik (untuk kalender)
          maxLines: maxLines,
          decoration: InputDecoration(
              filled: true,
              fillColor: backColor,
              suffixIcon: isDate ? const Icon(Icons.calendar_today, size: 18) : null, // Icon kalender
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15)
          )
      )
    ]));
  }

  Widget _buildDropdown(String label, List<dynamic> items, String? value, Function(String?) onChanged, {
    bool isEnabled = true,
    bool displayCode = false,
    bool isMandatory = false
  }) {
    if (value != null && !items.any((e) => e['id'].toString() == value)) value = null;
    Color backColor = isEnabled ? colorEditable : colorReadOnly;
    return Padding(padding: const EdgeInsets.only(bottom: 15), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildLabel(label, isMandatory),
      const SizedBox(height: 8),
      Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(color: backColor, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
          child: DropdownButtonHideUnderline(child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              hint: const Text("Pilih...", style: TextStyle(fontSize: 13, color: Colors.grey)),
              items: items.map<DropdownMenuItem<String>>((item) {
                String text = displayCode ? (item['code'] ?? '-') : (item['name'] ?? item['description'] ?? '-');
                return DropdownMenuItem<String>(value: item['id'].toString(), child: Text(text, style: const TextStyle(fontSize: 13)));
              }).toList(),
              onChanged: isEnabled ? onChanged : null
          )))
    ]));
  }

  Widget _buildStatusBadge(String status) {
    Color bg = Colors.grey.shade200; Color text = Colors.grey.shade700;
    if (status == "verified") { bg = Colors.green.shade100; text = Colors.green.shade800; }
    else if (status == "pending") { bg = Colors.orange.shade100; text = Colors.orange.shade800; }
    return Container(padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)), child: Text(status.toUpperCase(), textAlign: TextAlign.center, style: TextStyle(color: text, fontSize: 11, fontWeight: FontWeight.bold)));
  }

  void _confirmAction(String title, String content, VoidCallback onConfirm) {
    showDialog(context: context, builder: (c) => AlertDialog(title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), content: Text(content), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("Batal")), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: vosenDarkBlue, foregroundColor: Colors.white), onPressed: () { Navigator.pop(c); onConfirm(); }, child: const Text("Ya, Lanjutkan"))]));
  }

  void _showSuccessDialog(String message) {
    showDialog(context: context, builder: (c) => AlertDialog(content: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.check_circle, color: Colors.green, size: 60), const SizedBox(height: 10), Text(message), const SizedBox(height: 10), ElevatedButton(onPressed: () => Navigator.pop(c), child: const Text("Tutup"))])));
  }
}