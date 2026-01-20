<?php
include 'db_connect.php';
header('Content-Type: application/json');

try {
    // 1. STATS: CARD ATAS
    // FIX: Hanya hitung item yang TIDAK Deleted
    $qTotal = $conn->query("SELECT COUNT(*) as total FROM items WHERE status != 'Deleted'");
    $totalItems = $qTotal->fetch(PDO::FETCH_ASSOC)['total'];

    // Hitung Low Stock & Out Stock (Hanya untuk item Active)
    $sqlStock = "SELECT i.id, i.min_stock, IFNULL(SUM(b.qty_current), 0) as total_stock 
                 FROM items i 
                 LEFT JOIN inventory_batches b ON i.id = b.item_id 
                 WHERE i.status != 'Deleted' -- FIX DISINI
                 GROUP BY i.id";
    $stocks = $conn->query($sqlStock)->fetchAll(PDO::FETCH_ASSOC);

    $lowStock = 0;
    $outOfStock = 0;
    
    foreach ($stocks as $s) {
        if ($s['total_stock'] == 0) $outOfStock++;
        elseif ($s['total_stock'] < $s['min_stock']) $lowStock++;
    }

    // Expired Count (Hanya batch yang qty > 0 dan item induknya belum dihapus)
    $sqlExp = "SELECT COUNT(*) as total 
               FROM inventory_batches b
               JOIN items i ON b.item_id = i.id
               WHERE b.expired_date < CURDATE() 
               AND b.qty_current > 0
               AND i.status != 'Deleted'"; // FIX DISINI
    $qExp = $conn->query($sqlExp);
    $expiredCount = $qExp->fetch(PDO::FETCH_ASSOC)['total'];

    // 2. DATA TABEL (Overview Stok Terkini)
    // FIX: Tambahkan WHERE i.status != 'Deleted'
    $sqlList = "SELECT 
                    i.id as item_id,
                    i.name as item_name,
                    i.min_stock,
                    COALESCE(c.name, '-') as category_name,
                    MAX(b.created_at) as date_in, 
                    MIN(b.expired_date) as expired_date, 
                    IFNULL(SUM(b.qty_current), 0) as qty_current 
                FROM items i
                LEFT JOIN inventory_batches b ON i.id = b.item_id
                LEFT JOIN master_categories c ON i.category_id = c.id
                WHERE i.status != 'Deleted' -- FIX DISINI (PENTING)
                GROUP BY i.id
                ORDER BY i.name ASC";

    $stmtList = $conn->query($sqlList);
    $listData = $stmtList->fetchAll(PDO::FETCH_ASSOC);

    $formattedList = [];
    foreach ($listData as $row) {
        $status = "Active";
        $today = date('Y-m-d');
        $totalStock = (int)$row['qty_current'];
        
        if ($totalStock == 0) {
            $status = "Out of Stock";
        } elseif ($row['expired_date'] != null && $row['expired_date'] < $today) {
            $status = "Expired";
        } elseif ($totalStock < $row['min_stock']) {
            $status = "Low Stock";
        }

        $formattedList[] = [
            "name" => $row['item_name'],
            "cat"  => $row['category_name'],
            "in"   => $row['date_in'] ? date('d/m/Y', strtotime($row['date_in'])) : "-",
            "exp"  => $row['expired_date'] ? date('d/m/Y', strtotime($row['expired_date'])) : "-",
            "qty_current" => $totalStock,
            "status" => $status
        ];
    }

    // 3. GET CATEGORIES
    $catQuery = $conn->query("SELECT name FROM master_categories ORDER BY name ASC");
    $categories = $catQuery->fetchAll(PDO::FETCH_COLUMN);

    echo json_encode([
        "success" => true,
        "stats" => [
            "total_items" => $totalItems,
            "low_stock" => $lowStock,
            "expired" => $expiredCount,
            "out_of_stock" => $outOfStock
        ],
        "list" => $formattedList,
        "categories" => $categories
    ]);

} catch (Exception $e) {
    echo json_encode(["success" => false, "message" => $e->getMessage()]);
}
?>