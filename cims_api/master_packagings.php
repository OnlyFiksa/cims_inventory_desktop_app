<?php
include 'db_connect.php';
$method = $_SERVER['REQUEST_METHOD'];

// 1. GET (Join dengan Unit biar muncul nama satuannya, misal "Liter")
if ($method == 'GET') {
    $sql = "SELECT p.*, u.name as unit_name, u.code as unit_code 
            FROM master_packagings p 
            JOIN master_units u ON p.unit_id = u.id 
            ORDER BY p.id ASC";
    $stmt = $conn->prepare($sql);
    $stmt->execute();
    echo json_encode(["success" => true, "data" => $stmt->fetchAll(PDO::FETCH_ASSOC)]);
}

// 2. POST (ADD)
if ($method == 'POST' && !isset($_GET['action'])) {
    $name = $_POST['name'];
    $val  = $_POST['value'];
    $uid  = $_POST['unit_id'];

    try {
        $stmt = $conn->prepare("INSERT INTO master_packagings (name, value, unit_id) VALUES (?, ?, ?)");
        $stmt->execute([$name, $val, $uid]);
        echo json_encode(["success" => true, "message" => "Kemasan berhasil disimpan"]);
    } catch (PDOException $e) { echo json_encode(["success" => false, "message" => $e->getMessage()]); }
}

// 3. UPDATE & DELETE
if ($method == 'POST' && isset($_GET['action'])) {
    if ($_GET['action'] == 'update') {
        $stmt = $conn->prepare("UPDATE master_packagings SET name=?, value=?, unit_id=? WHERE id=?");
        $stmt->execute([$_POST['name'], $_POST['value'], $_POST['unit_id'], $_POST['id']]);
        echo json_encode(["success" => true, "message" => "Update berhasil"]);
    }
    if ($_GET['action'] == 'delete') {
        $stmt = $conn->prepare("DELETE FROM master_packagings WHERE id=?");
        $stmt->execute([$_POST['id']]);
        echo json_encode(["success" => true, "message" => "Hapus berhasil"]);
    }
}
?>