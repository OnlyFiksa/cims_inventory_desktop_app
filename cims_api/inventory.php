<?php
include 'db_connect.php';
header('Content-Type: application/json');

$method = $_SERVER['REQUEST_METHOD'];

// =======================================================================
// 1. GET ALL INVENTORY
// =======================================================================
if ($method == 'GET') {
    $sql = "SELECT 
                i.id as inventory_id, 
                i.code as unique_code,
                i.name as item_name,
                i.min_stock,
                COALESCE(c.name, '-') as category_name,
                COALESCE(t.name, '-') as type_name,
                MAX(b.created_at) as date_in,
                MIN(b.expired_date) as expired_date,
                IFNULL(SUM(b.qty_current), 0) as qty_current
            FROM items i
            LEFT JOIN inventory_batches b ON i.id = b.item_id
            LEFT JOIN master_categories c ON i.category_id = c.id
            LEFT JOIN master_types t ON i.type_id = t.id
            WHERE i.status != 'Deleted' 
            GROUP BY i.id
            ORDER BY i.name ASC";

    try {
        $stmt = $conn->prepare($sql);
        $stmt->execute();
        $result = $stmt->fetchAll(PDO::FETCH_ASSOC);
        echo json_encode(["success" => true, "data" => $result]);
    } catch (PDOException $e) {
        echo json_encode(["success" => false, "message" => $e->getMessage()]);
    }
}

// =======================================================================
// 2. POST (STOCK ADJUSTMENT) - DENGAN EXTRA SMART ID PARSER
// =======================================================================
if ($method == 'POST') {
    
    // 1. Tangkap Input Mentah
    $rawId = $_POST['inventory_id'] ?? $_POST['item_id'] ?? $_POST['id'] ?? null;

    // 2. [AUTO-CORRECT SMART VERSION]
    $itemId = null;

    if (is_numeric($rawId)) {
        // Jika Angka, Aman.
        $itemId = $rawId;
    } else {
        // Jika Teks "Coca-Cola (PKR-003-0101-a)"
        
        // Tahap A: Cari Exact Match (Nama Persis atau Kode Persis)
        $stmtCheck = $conn->prepare("SELECT id FROM items WHERE name = ? OR code = ? LIMIT 1");
        $stmtCheck->execute([$rawId, $rawId]);
        $found = $stmtCheck->fetch(PDO::FETCH_ASSOC);
        
        if ($found) {
            $itemId = $found['id'];
        } else {
            // Tahap B: Bedah Teks! Ambil Kode di dalam Kurung ()
            if (preg_match('/\((.*?)\)/', $rawId, $match)) {
                $codeInBracket = $match[1]; // Dapat "PKR-003-0101-a"
                
                // Cari pakai Kode Bersih ini
                $stmtCheck2 = $conn->prepare("SELECT id FROM items WHERE code = ? LIMIT 1");
                $stmtCheck2->execute([$codeInBracket]);
                $found2 = $stmtCheck2->fetch(PDO::FETCH_ASSOC);
                
                if ($found2) {
                    $itemId = $found2['id'];
                }
            }
        }
    }

    // 3. Validasi Akhir: Kalau masih gak ketemu juga, baru error.
    if (empty($itemId)) {
        echo json_encode(["success" => false, "message" => "GAGAL: Barang tidak ditemukan di database (Cek Nama/Kode)."]);
        exit;
    }

    $qtySystem  = (int)$_POST['qty_system'];
    $qtyActual  = (int)$_POST['qty_actual'];
    $reason     = $_POST['reason'];
    $diff       = $qtyActual - $qtySystem;

    if ($diff == 0) {
        echo json_encode(["success" => true, "message" => "Stok sesuai, tidak ada perubahan."]);
        exit;
    }

    try {
        $conn->beginTransaction();

        // SKENARIO A: STOK LEBIH (+) -> INSERT BATCH BARU
        if ($diff > 0) {
            $batchNo = "ADJ-" . date("ymd") . "-" . rand(100, 999);
            
            $sqlIn = "INSERT INTO inventory_batches 
                      (batch_no, item_id, qty_initial, qty_current, expired_date, created_by, created_at) 
                      VALUES (?, ?, ?, ?, DATE_ADD(CURDATE(), INTERVAL 1 YEAR), 'System Adjustment', NOW())";
            
            $stmtIn = $conn->prepare($sqlIn);
            $stmtIn->execute([$batchNo, $itemId, $diff, $diff]);
        
        // SKENARIO B: STOK KURANG (-) -> UPDATE BATCH (FEFO)
        } else {
            $qtyToReduce = abs($diff);
            $batches = $conn->query("SELECT id, qty_current FROM inventory_batches 
                                     WHERE item_id = $itemId AND qty_current > 0 
                                     ORDER BY expired_date ASC")->fetchAll(PDO::FETCH_ASSOC);
            
            foreach ($batches as $batch) {
                if ($qtyToReduce <= 0) break;
                $reduce = min($qtyToReduce, $batch['qty_current']);
                $conn->query("UPDATE inventory_batches SET qty_current = qty_current - $reduce WHERE id = " . $batch['id']);
                $qtyToReduce -= $reduce;
            }
        }

        // LOG TRANSAKSI
        $transNo = "ADJ-" . date("YmdHis");
        $sqlLog = "INSERT INTO trx_adjustments 
                   (trans_no, trans_date, inventory_id, qty_system, qty_actual, qty_diff, reason, created_at) 
                   VALUES (?, CURDATE(), ?, ?, ?, ?, ?, NOW())";
        
        $stmtLog = $conn->prepare($sqlLog);
        $stmtLog->execute([$transNo, $itemId, $qtySystem, $qtyActual, $diff, $reason]);

        $conn->commit();
        echo json_encode(["success" => true, "message" => "Adjustment berhasil disimpan"]);

    } catch (Exception $e) {
        $conn->rollBack();
        echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
    }
}
?>