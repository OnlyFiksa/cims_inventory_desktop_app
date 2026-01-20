<?php
include 'db_connect.php';
header('Content-Type: application/json');

// Matikan error reporting biar response bersih
error_reporting(0);

$type = $_GET['type'] ?? 'STOK_AKHIR';
$startDate = $_GET['start_date'] ?? '';
$endDate = $_GET['end_date'] ?? '';

try {

    // =======================================================================
    // 1. LAPORAN STOK AKHIR
    // =======================================================================
    if ($type == 'STOK_AKHIR') {
        
        $sql = "SELECT 
                    i.id as item_id,
                    
                    -- [FIX 1] Kembalikan nama alias jadi 'unique_code' agar terbaca Flutter
                    i.code as unique_code, 
                    i.code as item_code, 
                    
                    i.name as item_name,
                    c.name as category_name,
                    m.name as manufacturer_name,
                    s.name as supplier_name,
                    pk.name as packaging_name,
                    own.name as owner_name,
                    
                    -- [FIX 2] Kembalikan nama alias jadi 'qty_current' agar tidak NULL
                    COALESCE(SUM(b.qty_current), 0) as qty_current,
                    
                    MAX(b.created_at) as last_date_in,
                    MIN(b.expired_date) as expired_date -- Alias disamakan jadi expired_date

                FROM items i
                LEFT JOIN inventory_batches b ON i.id = b.item_id
                
                LEFT JOIN master_categories c ON i.category_id = c.id
                LEFT JOIN master_manufacturers m ON i.manufacturer_id = m.id
                LEFT JOIN master_suppliers s ON i.supplier_id = s.id
                LEFT JOIN master_packagings pk ON i.packaging_id = pk.id
                LEFT JOIN master_pemilik own ON i.owner_id = own.id

                WHERE i.status != 'Deleted'
                ";

        if (!empty($startDate) && !empty($endDate)) {
            $sql .= " AND DATE(b.created_at) BETWEEN '$startDate' AND '$endDate'";
        }

        $sql .= " GROUP BY i.id ORDER BY i.name ASC";

        $stmt = $conn->prepare($sql);
        $stmt->execute();
        $data = $stmt->fetchAll(PDO::FETCH_ASSOC);

        // Logic Status
        foreach ($data as &$row) {
            $exp = $row['expired_date'];
            $qty = (int)$row['qty_current'];
            $today = date('Y-m-d');

            if ($qty <= 0) { // Fix: Pakai <= 0 jaga-jaga ada minus
                $row['status'] = 'Out of Stock';
            } elseif ($exp != null && $exp < $today) {
                $row['status'] = 'Expired';
            } elseif ($qty < 5) { 
                $row['status'] = 'Low Stock';
            } else {
                $row['status'] = 'Active';
            }
        }

        echo json_encode(["success" => true, "data" => $data]);
    }

    // =======================================================================
    // 2. LAPORAN MUTASI
    // =======================================================================
    else if ($type == 'MUTASI') {
        
        $sqlUnion = "
            SELECT trans_no, trans_date, 'IN' as type, item_id, qty_in as qty, notes as ket, created_at 
            FROM trx_in
            WHERE 1=1 " . ((!empty($startDate) && !empty($endDate)) ? "AND trans_date BETWEEN '$startDate' AND '$endDate'" : "") . "

            UNION ALL

            SELECT trans_no, trans_date, 'OUT' as type, item_id, qty_out as qty, description as ket, created_at 
            FROM trx_out
            WHERE 1=1 " . ((!empty($startDate) && !empty($endDate)) ? "AND trans_date BETWEEN '$startDate' AND '$endDate'" : "") . "

            UNION ALL

            SELECT trans_no, trans_date, 'ADJUSTMENT' as type, inventory_id as item_id, qty_diff as qty, reason as ket, created_at 
            FROM trx_adjustments
            WHERE 1=1 " . ((!empty($startDate) && !empty($endDate)) ? "AND trans_date BETWEEN '$startDate' AND '$endDate'" : "") . "
        ";

        $finalSql = "SELECT t.*, i.name as item_name, i.code as unique_code 
                     FROM ($sqlUnion) t 
                     LEFT JOIN items i ON t.item_id = i.id 
                     ORDER BY t.trans_date DESC, t.created_at DESC";

        $stmt = $conn->prepare($finalSql);
        $stmt->execute();
        $data = $stmt->fetchAll(PDO::FETCH_ASSOC);

        echo json_encode(["success" => true, "data" => $data]);
    }

} catch (Exception $e) {
    echo json_encode(["success" => false, "message" => $e->getMessage()]);
}
?>