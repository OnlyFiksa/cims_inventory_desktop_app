<?php
include 'db_connect.php';
header('Content-Type: application/json');

$method = $_SERVER['REQUEST_METHOD'];

// 1. GET REQUESTS
if ($method == 'GET') {

    // --- [BARU] ACTION: GET SEQUENCE NUMBER ---
    // Dipanggil saat generate kode otomatis
    if (isset($_GET['action']) && $_GET['action'] == 'get_sequence') {
        try {
            // Hitung TOTAL SEMUA ITEM (Termasuk yang Deleted)
            // Agar urutan terus maju (misal: 005, 006) walau ada yang dihapus
            $stmt = $conn->query("SELECT COUNT(*) as total FROM items");
            $result = $stmt->fetch(PDO::FETCH_ASSOC);
            
            // Urutan berikutnya = Total + 1
            $nextSequence = (int)$result['total'] + 1;
            
            echo json_encode(["success" => true, "sequence" => $nextSequence]);
            exit; // Stop script disini
        } catch (PDOException $e) {
            echo json_encode(["success" => false, "message" => $e->getMessage()]);
            exit;
        }
    }

    // --- ACTION: DROPDOWNS ---
    if (isset($_GET['action']) && $_GET['action'] == 'dropdowns') {
        $data = [];
        $data['categories'] = $conn->query("SELECT * FROM master_categories")->fetchAll(PDO::FETCH_ASSOC);
        $data['owners'] = $conn->query("SELECT * FROM master_pemilik")->fetchAll(PDO::FETCH_ASSOC);
        $data['types'] = $conn->query("SELECT * FROM master_types")->fetchAll(PDO::FETCH_ASSOC);
        $data['manufacturers'] = $conn->query("SELECT * FROM master_manufacturers")->fetchAll(PDO::FETCH_ASSOC);
        $data['suppliers'] = $conn->query("SELECT * FROM master_suppliers")->fetchAll(PDO::FETCH_ASSOC);
        $data['packagings'] = $conn->query("SELECT * FROM master_packagings")->fetchAll(PDO::FETCH_ASSOC);
        
        echo json_encode(["success" => true, "data" => $data]);
        exit;
    }

    // --- DEFAULT: GET ALL ITEMS (Hanya yang Active) ---
    // Tetap filter 'Deleted' agar list di aplikasi bersih
    $sql = "SELECT i.*, 
            COALESCE(c.name, '-') as category_name, 
            COALESCE(o.name, '-') as owner_name, 
            COALESCE(t.name, '-') as type_name, 
            COALESCE(m.name, '-') as manufacturer_name, 
            COALESCE(s.name, '-') as supplier_name,
            COALESCE(p.name, '-') as packaging_name 
            FROM items i
            LEFT JOIN master_categories c ON i.category_id = c.id
            LEFT JOIN master_pemilik o ON i.owner_id = o.id
            LEFT JOIN master_types t ON i.type_id = t.id
            LEFT JOIN master_manufacturers m ON i.manufacturer_id = m.id
            LEFT JOIN master_suppliers s ON i.supplier_id = s.id
            LEFT JOIN master_packagings p ON i.packaging_id = p.id
            WHERE i.status != 'Deleted' 
            ORDER BY i.id DESC";
    
    try {
        $stmt = $conn->prepare($sql);
        $stmt->execute();
        echo json_encode(["success" => true, "data" => $stmt->fetchAll(PDO::FETCH_ASSOC)]);
    } catch (PDOException $e) {
        echo json_encode(["success" => false, "message" => $e->getMessage()]);
    }
}

// 2. POST (ADD)
if ($method == 'POST' && !isset($_GET['action'])) {
    try {
        $stmt = $conn->prepare("INSERT INTO items (code, name, category_id, owner_id, type_id, manufacturer_id, supplier_id, packaging_id, min_stock, description, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'Active')");
        $stmt->execute([
            $_POST['code'], $_POST['name'], $_POST['category_id'], $_POST['owner_id'], 
            $_POST['type_id'], $_POST['manufacturer_id'], $_POST['supplier_id'], 
            $_POST['packaging_id'], $_POST['min_stock'], $_POST['description']
        ]);
        echo json_encode(["success" => true, "message" => "Item berhasil disimpan"]);
    } catch (PDOException $e) { echo json_encode(["success" => false, "message" => $e->getMessage()]); }
}

// 3. UPDATE & DELETE
if ($method == 'POST' && isset($_GET['action'])) {
    
    // UPDATE ITEM
    if ($_GET['action'] == 'update') {
        try {
            $stmt = $conn->prepare("UPDATE items SET code=?, name=?, category_id=?, owner_id=?, type_id=?, manufacturer_id=?, supplier_id=?, packaging_id=?, min_stock=?, description=? WHERE id=?");
            $stmt->execute([
                $_POST['code'], $_POST['name'], $_POST['category_id'], $_POST['owner_id'], 
                $_POST['type_id'], $_POST['manufacturer_id'], $_POST['supplier_id'], 
                $_POST['packaging_id'], $_POST['min_stock'], $_POST['description'], $_POST['id']
            ]);
            echo json_encode(["success" => true, "message" => "Update berhasil"]);
        } catch (PDOException $e) {
            echo json_encode(["success" => false, "message" => $e->getMessage()]);
        }
    }

    // DELETE ITEM (SOFT DELETE)
    if ($_GET['action'] == 'delete') {
        try {
            $stmt = $conn->prepare("UPDATE items SET status = 'Deleted' WHERE id=?");
            $stmt->execute([$_POST['id']]);
            echo json_encode(["success" => true, "message" => "Item berhasil dihapus (Soft Delete)"]);
        } catch (PDOException $e) {
            echo json_encode(["success" => false, "message" => $e->getMessage()]);
        }
    }
}
?>