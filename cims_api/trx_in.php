<?php
include 'db_connect.php';
header('Content-Type: application/json');
error_reporting(0); 

$method = $_SERVER['REQUEST_METHOD'];
$action = $_GET['action'] ?? '';

// --- FUNGSI BANTUAN ---
function convertDate($date) {
    if (empty($date)) return null;
    if (strpos($date, '/') !== false) {
        $parts = explode('/', $date);
        if (count($parts) == 3) {
            return $parts[2] . '-' . $parts[1] . '-' . $parts[0];
        }
    }
    return $date;
}

try {
    // 1. DROPDOWN
    if ($method == 'GET' && $action == 'dropdowns') {
        $items = $conn->query("SELECT id, code, name FROM items WHERE (status != 'Deleted' OR status IS NULL) ORDER BY name ASC")->fetchAll(PDO::FETCH_ASSOC);
        $owners = $conn->query("SELECT id, name FROM master_pemilik ORDER BY name ASC")->fetchAll(PDO::FETCH_ASSOC);
        $manufacturers = $conn->query("SELECT id, name FROM master_manufacturers ORDER BY name ASC")->fetchAll(PDO::FETCH_ASSOC);
        $suppliers = $conn->query("SELECT id, name FROM master_suppliers ORDER BY name ASC")->fetchAll(PDO::FETCH_ASSOC);
        $packagings = $conn->query("SELECT id, name, value FROM master_packagings ORDER BY name ASC")->fetchAll(PDO::FETCH_ASSOC);
        $units = $conn->query("SELECT id, name FROM master_units ORDER BY name ASC")->fetchAll(PDO::FETCH_ASSOC);

        echo json_encode([
            "success" => true,
            "data" => [
                "items" => $items, "owners" => $owners, "manufacturers" => $manufacturers,
                "suppliers" => $suppliers, "packagings" => $packagings, "units" => $units
            ]
        ]);
        exit;
    }

    // 2. GET LIST
    if ($method == 'GET') {
        $sql = "SELECT t.*, i.name as item_name, i.code as item_code, s.name as supplier_name, u.name as unit_name
                FROM trx_in t
                LEFT JOIN items i ON t.item_id = i.id
                LEFT JOIN master_suppliers s ON t.supplier_id = s.id
                LEFT JOIN master_units u ON t.unit_id = u.id
                ORDER BY t.created_at DESC";
        $stmt = $conn->prepare($sql);
        $stmt->execute();
        $result = $stmt->fetchAll(PDO::FETCH_ASSOC);
        echo json_encode(["success" => true, "data" => $result]);
        exit;
    }

    // 3. POST TRANSAKSI
    if ($method == 'POST') {
        
        $conn->beginTransaction(); 

        $itemId = $_POST['item_id'] ?? null;
        if (empty($itemId)) throw new Exception("Item ID tidak ditemukan");

        // --- LOGIKA PENENTUAN STATUS (FINAL FIX) ---
        // Prioritas 1: Ambil Status yang dikirim Flutter
        if (isset($_POST['status']) && !empty($_POST['status'])) {
            $status = $_POST['status'];
        } 
        // Prioritas 2: Cek User Role (Fallback)
        else {
            $userRole = $_POST['user_role'] ?? 'staff';
            $status = (strtolower($userRole) === 'supervisor') ? 'verified' : 'pending';
        }

        // Data Input
        $transDate = convertDate($_POST['trans_date'] ?? date("Y-m-d"));
        $expDate = convertDate($_POST['expired_date'] ?? null);
        $transNo = $_POST['trans_no'] ?? ("IN-" . date("ymdHis")); 
        $suratJalan = $_POST['surat_jalan'] ?? '';
        $poNumber   = $_POST['po_number'] ?? '';
        $ownerId    = $_POST['owner_id'] ?? null; 
        $manufId    = $_POST['manufacturer_id'] ?? null;
        $suppId     = $_POST['supplier_id'] ?? null;
        $recipient  = $_POST['recipient'] ?? '';
        $notes      = $_POST['notes'] ?? '';
        $packId     = $_POST['packaging_id'] ?? null;
        $unitId     = $_POST['unit_id'] ?? null;
        $batch      = $_POST['supplier_batch'] ?? '';
        $qtyIn      = floatval($_POST['qty_in'] ?? 0);
        $price      = floatval($_POST['price'] ?? 0);
        $total      = $qtyIn * $price;

        // INSERT TRX
        $sqlTrx = "INSERT INTO trx_in 
                (trans_no, trans_date, surat_jalan, po_number, owner_id, manufacturer_id, supplier_id, recipient, notes, 
                 item_id, packaging_id, qty_in, unit_id, expired_date, supplier_batch, price, total_price, status, created_at) 
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())";

        $stmt = $conn->prepare($sqlTrx);
        $stmt->execute([
            $transNo, $transDate, $suratJalan, $poNumber, $ownerId, $manufId, $suppId, $recipient, $notes,
            $itemId, $packId, $qtyIn, $unitId, $expDate, $batch, $price, $total, $status
        ]);
        
        // JIKA SUPERVISOR -> LANGSUNG NAMBAH STOK REAL
        if ($status === 'verified') {
            $finalExp = $expDate ?? date('Y-m-d', strtotime('+1 year'));
            $finalBatch = !empty($batch) ? $batch : ("BATCH-" . date("ymdHis"));

            $sqlBatch = "INSERT INTO inventory_batches 
                         (batch_no, item_id, qty_initial, qty_current, expired_date, price, created_by, created_at) 
                         VALUES (?, ?, ?, ?, ?, ?, 'Supervisor Input', NOW())";
            
            $stmtBatch = $conn->prepare($sqlBatch);
            $stmtBatch->execute([$finalBatch, $itemId, $qtyIn, $qtyIn, $finalExp, $price]);
        }

        $conn->commit(); 
        
        $msg = ($status === 'verified') ? "Stok Masuk Berhasil & Langsung Diverifikasi!" : "Data Tersimpan. Menunggu Verifikasi.";
        echo json_encode(["success" => true, "message" => $msg]);
        exit;
    }

} catch (Throwable $e) {
    if ($conn->inTransaction()) $conn->rollBack();
    http_response_code(200);
    echo json_encode(["success" => false, "message" => "Server Error: " . $e->getMessage()]);
}
?>