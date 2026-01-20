import 'package:flutter/material.dart';
import 'package:cims_app/widgets/custom_sidebar.dart';
import 'package:cims_app/services/users/user_service.dart';
import 'package:cims_app/services/auth_service.dart';

class UserManagementView extends StatefulWidget {
  const UserManagementView({super.key});

  @override
  State<UserManagementView> createState() => _UserManagementViewState();
}

class _UserManagementViewState extends State<UserManagementView> {
  // --- COLORS ---
  final Color vosenDarkBlue = const Color(0xFF0A2A4D);
  final Color vosenRed = const Color(0xFFD32F2F);
  final Color bgGrey = const Color(0xFFF5F7FA);
  final Color readOnlyColor = const Color(0xFFE0E0E0);
  final Color colorEditable = Colors.white;

  // --- STATE ---
  String _currentRole = "staff"; // Role yang sedang login
  String _currentUserId = "";    // ID user yang sedang login (untuk proteksi hapus diri sendiri)

  bool _isFormVisible = false;
  bool _isEditing = false;
  String? _selectedId;
  bool _isLoadingRole = true;

  // --- CONTROLLERS ---
  final _nikCtrl = TextEditingController();
  final _namaCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  // --- DROPDOWN ---
  String? _selectedJabatan;
  String? _selectedStatus;

  final List<String> listJabatan = ["Supervisor", "Staff", "Manager"];
  // Pastikan tidak ada status "Deleted" disini agar tidak dipilih manual
  final List<String> listStatus = ["Active", "Non-Active"];

  List<dynamic> _userList = [];
  final UserService _service = UserService();

  @override
  void initState() {
    super.initState();
    _checkRole(); // 1. Cek identitas pelogin
    _fetchData();
  }

  // 1. LOGIC CEK IDENTITAS (ROLE & ID)
  void _checkRole() async {
    final auth = AuthService();
    final data = await auth.getUserSession();
    if (mounted) {
      setState(() {
        _currentRole = (data['role'] ?? "staff").toString().toLowerCase();
        _currentUserId = (data['id'] ?? "").toString(); // Penting untuk proteksi delete
        _isLoadingRole = false;
      });
    }
  }

  void _fetchData() async {
    final data = await _service.getUsers();
    if (mounted) setState(() => _userList = data);
  }

  // 2. LOGIC CRUD
  void _saveData() async {
    if (_nikCtrl.text.isEmpty || _namaCtrl.text.isEmpty || _emailCtrl.text.isEmpty ||
        _passwordCtrl.text.isEmpty || _selectedJabatan == null || _selectedStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Harap isi semua kolom bertanda (*)"), backgroundColor: Colors.red));
      return;
    }

    Map<String, String> data = {
      "nik": _nikCtrl.text,
      "name": _namaCtrl.text,
      "email": _emailCtrl.text,
      "password": _passwordCtrl.text,
      "role": _selectedJabatan!.toLowerCase(),
      "status": _selectedStatus!
    };

    if (_isEditing && _selectedId != null) {
      data['id'] = _selectedId!;
      bool success = await _service.updateUser(data);
      if (success) {
        _fetchData();
        _showSuccessDialog("Data user berhasil diperbarui.");
        setState(() => _isFormVisible = false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal update user"), backgroundColor: Colors.red));
      }
    } else {
      var result = await _service.addUser(data);
      if (result['success'] == true) {
        _fetchData();
        _showSuccessDialog("User baru berhasil ditambahkan.");
        setState(() => _isFormVisible = false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? "Gagal menyimpan"), backgroundColor: Colors.red));
      }
    }
  }

  // 3. LOGIC HAPUS (DENGAN PROTEKSI ADMIN ID)
  void _deleteItem() async {
    if (_selectedId == null) return;

    // Panggil Service dengan 2 Parameter: ID Target & ID Admin
    var result = await _service.deleteUser(_selectedId!, _currentUserId);

    if (result['success'] == true) {
      _fetchData();
      _showSuccessDialog(result['message'] ?? "User berhasil dihapus.");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(result['message'] ?? "Gagal menghapus user"),
              backgroundColor: Colors.red
          )
      );
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  // ===========================================================================
  // UI BUILDER
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    if (_isLoadingRole) {
      return Scaffold(backgroundColor: bgGrey, body: Center(child: CircularProgressIndicator(color: vosenDarkBlue)));
    }

    return Scaffold(
      backgroundColor: bgGrey,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CustomSidebar(activeMenu: "User Management"),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderNav(),
                  const SizedBox(height: 30),
                  _isFormVisible ? _buildFormSection() : _buildListSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderNav() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("User Management", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: vosenDarkBlue)),
      const SizedBox(height: 5),
      Text("Login sebagai: ${_currentRole.toUpperCase()}", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
    ]);
  }

  // --- LIST VIEW SECTION ---
  Widget _buildListSection() {
    bool isSupervisor = _currentRole.contains('supervisor');

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      padding: const EdgeInsets.all(25),
      child: Column(
        children: [
          Row(
            children: [
              Text("Daftar Pengguna", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: vosenDarkBlue)),
              const Spacer(),

              // TOMBOL TAMBAH (HANYA SUPERVISOR)
              if (isSupervisor)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: vosenDarkBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                  onPressed: () {
                    _resetForm();
                    setState(() { _isFormVisible = true; _isEditing = true; _selectedId = null; });
                  },
                  icon: const Icon(Icons.person_add_alt, size: 18), label: const Text("Tambah User"),
                )
            ],
          ),
          const SizedBox(height: 20),
          Container(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15), decoration: BoxDecoration(color: bgGrey, borderRadius: BorderRadius.circular(8)), child: const Row(children: [
            Expanded(flex: 1, child: Text("NIK", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            Expanded(flex: 2, child: Text("NAMA LENGKAP", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            Expanded(flex: 2, child: Text("EMAIL", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            Expanded(flex: 1, child: Text("JABATAN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            Expanded(flex: 1, child: Text("STATUS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            SizedBox(width: 100, child: Center(child: Text("AKSI", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
          ])),
          const SizedBox(height: 10),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _userList.length,
            itemBuilder: (context, index) {
              final user = _userList[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 5), padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
                child: Row(children: [
                  Expanded(flex: 1, child: Text(user['nik'] ?? "-", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                  Expanded(flex: 2, child: Text(user['name'] ?? "-", style: const TextStyle(fontSize: 13))),
                  Expanded(flex: 2, child: Text(user['email'] ?? "-", style: const TextStyle(fontSize: 13))),
                  Expanded(flex: 1, child: Text(_capitalize(user['role'] ?? "-"), style: const TextStyle(fontSize: 13))),
                  Expanded(flex: 1, child: _buildStatusBadge(user['status'] ?? "-")),

                  // --- KOLOM AKSI ---
                  SizedBox(width: 100, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    // VIEW (Semua Role)
                    InkWell(onTap: () => _viewDetail(user), child: const Icon(Icons.visibility_outlined, color: Colors.blue, size: 20)),

                    // EDIT & DELETE (Hanya Supervisor)
                    if (isSupervisor) ...[
                      const SizedBox(width: 10),
                      InkWell(onTap: () => _confirmAction("Edit User", "Edit data pengguna ini?", () => _editDetail(user)), child: const Icon(Icons.edit_outlined, color: Colors.orange, size: 20)),

                      const SizedBox(width: 10),

                      // PROTEKSI: JANGAN TAMPILKAN TOMBOL HAPUS JIKA ITU DIRI SENDIRI
                      if (user['id'].toString() != _currentUserId)
                        InkWell(
                            onTap: () => _confirmAction("Hapus User", "Yakin hapus pengguna ini?\nData akan dihapus dari tampilan.", () => _deleteItem()),
                            child: Icon(Icons.delete_outline, color: vosenRed, size: 20)
                        )
                      else
                        const Icon(Icons.block, color: Colors.grey, size: 20) // Indikator tidak bisa hapus diri sendiri
                    ]
                  ])),
                ]),
              );
            },
          )
        ],
      ),
    );
  }

  // --- FORM SECTION ---
  Widget _buildFormSection() {
    String title = _isEditing ? (_selectedId == null ? "Tambah User Baru" : "Edit Data User") : "Detail User";
    bool isSupervisor = _currentRole.contains('supervisor');

    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _isFormVisible = false)),
          const SizedBox(width: 10),
          Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: vosenDarkBlue)),
        ]),
        const Divider(height: 30),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(children: [
            _buildInput("NIK (Nomor Induk Karyawan)", _nikCtrl, isReadOnly: _selectedId != null, isMandatory: true),
            _buildInput("Nama Lengkap", _namaCtrl, isReadOnly: !_isEditing, isMandatory: true),
            _buildInput("Email Perusahaan", _emailCtrl, isReadOnly: !_isEditing, isMandatory: true),
          ])),
          const SizedBox(width: 30),
          Expanded(child: Column(children: [
            _buildInput("Password", _passwordCtrl, isReadOnly: !_isEditing, isMandatory: true, isPassword: true),
            _buildDropdown("Jabatan / Role", listJabatan, _selectedJabatan, (val) => setState(() => _selectedJabatan = val), isMandatory: true, isEnabled: _isEditing),
            _buildDropdown("Status Akun", listStatus, _selectedStatus, (val) => setState(() => _selectedStatus = val), isMandatory: true, isEnabled: _isEditing),
          ])),
        ]),
        const SizedBox(height: 30),

        if (_isEditing && isSupervisor)
          Align(alignment: Alignment.centerRight, child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: vosenDarkBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)),
            onPressed: () => _confirmAction("Simpan Data", "Pastikan data user sudah benar?", _saveData),
            icon: const Icon(Icons.save), label: const Text("Simpan Data"),
          ))
      ]),
    );
  }

  // --- WIDGET HELPER ---
  Widget _buildLabel(String label, bool isMandatory) => RichText(text: TextSpan(text: label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54), children: [if (isMandatory) TextSpan(text: " *", style: TextStyle(color: vosenRed, fontWeight: FontWeight.bold))]));

  Widget _buildInput(String label, TextEditingController controller, {bool isReadOnly = false, bool isMandatory = false, bool isPassword = false}) {
    return Padding(padding: const EdgeInsets.only(bottom: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildLabel(label, isMandatory), const SizedBox(height: 8),
      TextField(controller: controller, readOnly: isReadOnly, obscureText: isPassword, decoration: InputDecoration(filled: true, fillColor: isReadOnly ? readOnlyColor : colorEditable, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)), contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15), suffixIcon: isPassword ? const Icon(Icons.lock_outline, size: 18) : null))
    ]));
  }

  Widget _buildDropdown(String label, List<String> items, String? value, Function(String?) onChanged, {bool isMandatory = false, bool isEnabled = true}) {
    return Padding(padding: const EdgeInsets.only(bottom: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildLabel(label, isMandatory), const SizedBox(height: 8),
      Container(padding: const EdgeInsets.symmetric(horizontal: 15), decoration: BoxDecoration(color: isEnabled ? colorEditable : readOnlyColor, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)), child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: value, isExpanded: true, hint: const Text("Pilih...", style: TextStyle(fontSize: 13, color: Colors.grey)), icon: const Icon(Icons.keyboard_arrow_down), items: items.map((String item) => DropdownMenuItem<String>(value: item, child: Text(item, style: const TextStyle(fontSize: 13)))).toList(), onChanged: isEnabled ? onChanged : null)))
    ]));
  }

  Widget _buildStatusBadge(String status) {
    Color bg = Colors.grey.shade200; Color text = Colors.grey.shade700;
    if (status == "Active") { bg = Colors.green.shade100; text = Colors.green.shade800; }
    else if (status == "Non-Active") { bg = Colors.red.shade100; text = Colors.red.shade800; }
    return Container(padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)), child: Text(status, textAlign: TextAlign.center, style: TextStyle(color: text, fontSize: 11, fontWeight: FontWeight.bold)));
  }

  void _viewDetail(Map<String, dynamic> user) {
    setState(() { _selectedId = user['id'].toString(); _isFormVisible = true; _isEditing = false; _fillForm(user); });
  }

  void _editDetail(Map<String, dynamic> user) {
    setState(() { _selectedId = user['id'].toString(); _isFormVisible = true; _isEditing = true; _fillForm(user); });
  }

  void _fillForm(Map<String, dynamic> user) {
    _nikCtrl.text = user['nik']; _namaCtrl.text = user['name']; _emailCtrl.text = user['email'];
    _passwordCtrl.text = user['password'];
    _selectedJabatan = _capitalize(user['role']);
    _selectedStatus = user['status'];
  }

  void _resetForm() {
    _nikCtrl.clear(); _namaCtrl.clear(); _emailCtrl.clear(); _passwordCtrl.clear();
    _selectedJabatan = null; _selectedStatus = null;
  }

  void _confirmAction(String title, String content, VoidCallback onConfirm) {
    showDialog(context: context, builder: (c) => AlertDialog(title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), content: Text(content), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("Batal")), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: vosenDarkBlue, foregroundColor: Colors.white), onPressed: () { Navigator.pop(c); onConfirm(); }, child: const Text("Ya, Lanjutkan"))]));
  }

  void _showSuccessDialog(String message) {
    showDialog(context: context, builder: (c) => AlertDialog(content: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.check_circle, color: Colors.green, size: 60), const SizedBox(height: 10), Text(message), const SizedBox(height: 20), ElevatedButton(onPressed: () => Navigator.pop(c), child: const Text("Tutup"))])));
  }
}