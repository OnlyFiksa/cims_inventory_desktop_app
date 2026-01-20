<?php
include 'db_connect.php';
header('Content-Type: application/json');

$method = $_SERVER['REQUEST_METHOD'];
$action = $_GET['action'] ?? '';

// =================================================================================
// 1. GET ALL STOCK OUT (Untuk Tampilan List di Flutter)
// =================================================================================
if ($method == 'GET' && empty($action)) {
    $sql = "SELECT t.*, 
            i.code as item_code, i.name as item_name,
            o.name as owner_name,
            u.name as unit_name
            FROM trx_out t
            LEFT JOIN items i ON t.item_id = i.id
            LEFT JOIN master_pemilik o ON t.owner_id = o.id
            LEFT JOIN master_units u ON t.unit_id = u.id
            ORDER BY t.created_at DESC";
    
    $stmt = $conn->prepare($sql);
    $stmt->execute();
    echo json_encode(["success" => true, "data" => $stmt->fetchAll(PDO::FETCH_ASSOC)]);
    exit;
}

// =================================================================================
// 2. GET DROPDOWN DATA (Untuk Form Input - SMART FILTER)
// =================================================================================
if ($method == 'GET' && $action == 'dropdowns') {
    $data = [];
    $data['owners'] = $conn->query("SELECT id, name FROM master_pemilik ORDER BY name ASC")->fetchAll(PDO::FETCH_ASSOC);
    
    // --- [PERBAIKAN DISINI] ---
    // Hanya ambil Item yang: 
    // 1. Statusnya TIDAK Deleted
    // 2. Punya stok > 0 di inventory_batches
    
    $sqlItem = "SELECT DISTINCT 
                    i.id, i.code, i.name, 
                    p.unit_id, u.name as unit_name, p.value as pack_value 
                FROM items i 
                -- Join ke tabel stok untuk cek ketersediaan
                JOIN inventory_batches b ON i.id = b.item_id
                -- Join info kemasan & satuan (agar Flutter tidak error)
                LEFT JOIN master_packagings p ON i.packaging_id = p.id
                LEFT JOIN master_units u ON p.unit_id = u.id
                -- Filter Kondisi
                WHERE i.status != 'Deleted' 
                  AND b.qty_current > 0
                ORDER BY i.name ASC";

    $data['items'] = $conn->query($sqlItem)->fetchAll(PDO::FETCH_ASSOC);
    
    echo json_encode(["success" => true, "data" => $data]);
    exit;
}

// =================================================================================
// 3. POST (SIMPAN TRANSAKSI & KURANGI STOK OTOMATIS)
// =================================================================================
if ($method == 'POST') {
    
    // Ambil Input
    $tgl        = $_POST['trans_date'];
    $owner      = $_POST['owner_id'];
    $creator    = $_POST['created_by'];
    $desc       = $_POST['description'];
    
    $item       = $_POST['item_id'];
    $qty        = (int)$_POST['qty_out']; // Pastikan Integer
    $unit       = $_POST['unit_id'];
    
    $inUseExp   = !empty($_POST['in_use_exp_date']) ? $_POST['in_use_exp_date'] : NULL;
    $qcNo       = $_POST['qc_number'];
    
    $price      = $_POST['price'] ?? 0;
    $totalPrice = $_POST['total_price'] ?? 0;

    // VALIDASI: Cek Qty Minus/Nol
    if ($qty <= 0) {
        echo json_encode(["success" => false, "message" => "Jumlah stok keluar tidak valid (Min 1)"]);
        exit;
    }

    try {
        // Mulai Transaksi Database (Biar kalau error, batal semua)
        $conn->beginTransaction();

        // A. CEK STOK TERSEDIA (Cukup gak?)
        $stmtCek = $conn->prepare("SELECT SUM(qty_current) as total FROM inventory_batches WHERE item_id = ? AND qty_current > 0");
        $stmtCek->execute([$item]);
        $resStock = $stmtCek->fetch(PDO::FETCH_ASSOC);
        $totalStock = $resStock ? $resStock['total'] : 0;

        if ($totalStock < $qty) {
            throw new Exception("Stok tidak cukup! Sisa stok di gudang: " . (int)$totalStock);
        }

        // B. Generate No Transaksi: OUT-YYMM-XXXX
        $ym = date("ym"); 
        $check = $conn->query("SELECT COUNT(*) as total FROM trx_out WHERE trans_no LIKE 'OUT-$ym-%'");
        $totalTrx = $check->fetch(PDO::FETCH_ASSOC)['total'] + 1;
        $no_trans = "OUT-$ym-" . str_pad($totalTrx, 4, '0', STR_PAD_LEFT);

        // C. Simpan ke Tabel Riwayat Keluar (trx_out)
        $sqlInsert = "INSERT INTO trx_out 
                (trans_no, trans_date, owner_id, created_by, description, 
                 item_id, qty_out, unit_id, in_use_exp_date, qc_number, price, total_price, created_at) 
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())";
        
        $stmtInsert = $conn->prepare($sqlInsert);
        $stmtInsert->execute([
            $no_trans, $tgl, $owner, $creator, $desc,
            $item, $qty, $unit, $inUseExp, $qcNo, $price, $totalPrice
        ]);

        // D. KURANGI STOK (ALGORITMA FEFO - First Expired First Out)
        // Ambil batch yang masih ada stok, urutkan dari yang mau BASI duluan
        $sqlBatch = "SELECT id, qty_current FROM inventory_batches 
                     WHERE item_id = ? AND qty_current > 0 
                     ORDER BY expired_date ASC, created_at ASC";
        $stmtBatch = $conn->prepare($sqlBatch);
        $stmtBatch->execute([$item]);
        $batches = $stmtBatch->fetchAll(PDO::FETCH_ASSOC);

        $sisa_yg_harus_keluar = $qty;

        foreach ($batches as $batch) {
            if ($sisa_yg_harus_keluar <= 0) break; // Sudah lunas, berhenti looping

            $qty_di_batch = (int)$batch['qty_current'];
            
            if ($qty_di_batch >= $sisa_yg_harus_keluar) {
                // Skenario 1: Stok di batch ini CUKUP
                // Kurangi batch ini sesuai kebutuhan, lalu selesai
                $conn->prepare("UPDATE inventory_batches SET qty_current = qty_current - ? WHERE id = ?")
                     ->execute([$sisa_yg_harus_keluar, $batch['id']]);
                
                $sisa_yg_harus_keluar = 0; 
            } else {
                // Skenario 2: Stok di batch ini KURANG (Habiskan batch ini, cari lagi di batch berikutnya)
                $conn->prepare("UPDATE inventory_batches SET qty_current = 0 WHERE id = ?")
                     ->execute([$batch['id']]);
                
                $sisa_yg_harus_keluar -= $qty_di_batch; // Masih ada sisa hutang stok
            }
        }

        // Kalau semua lancar, simpan permanen
        $conn->commit();
        echo json_encode(["success" => true, "message" => "Stok Keluar berhasil disimpan & Stok berkurang."]);

    } catch (Exception $e) {
        // Kalau ada error, batalkan semua perubahan
        if ($conn->inTransaction()) {
            $conn->rollBack();
        }
        echo json_encode(["success" => false, "message" => $e->getMessage()]);
    }
}
?>