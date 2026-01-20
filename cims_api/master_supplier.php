<?php
include 'db_connect.php';

$method = $_SERVER['REQUEST_METHOD'];

// 1. GET
if ($method == 'GET') {
    $stmt = $conn->prepare("SELECT * FROM master_suppliers ORDER BY id DESC");
    $stmt->execute();
    $result = $stmt->fetchAll(PDO::FETCH_ASSOC);
    echo json_encode(["success" => true, "data" => $result]);
}

// 2. POST (ADD)
if ($method == 'POST' && !isset($_GET['action'])) {
    $name = $_POST['name'];
    $address = $_POST['address'] ?? '';
    $phone = $_POST['phone'] ?? '';
    $website = $_POST['website'] ?? '';
    $desc = $_POST['description'] ?? '';

    try {
        $stmt = $conn->prepare("INSERT INTO master_suppliers (name, address, phone, website, description) VALUES (?, ?, ?, ?, ?)");
        $stmt->execute([$name, $address, $phone, $website, $desc]);
        echo json_encode(["success" => true, "message" => "Data berhasil disimpan"]);
    } catch (PDOException $e) {
        echo json_encode(["success" => false, "message" => "Gagal: " . $e->getMessage()]);
    }
}

// 3. UPDATE & DELETE
if ($method == 'POST' && isset($_GET['action'])) {
    
    // UPDATE
    if ($_GET['action'] == 'update') {
        $id = $_POST['id'];
        $name = $_POST['name'];
        $address = $_POST['address'];
        $phone = $_POST['phone'];
        $website = $_POST['website'];
        $desc = $_POST['description'];

        $stmt = $conn->prepare("UPDATE master_suppliers SET name=?, address=?, phone=?, website=?, description=? WHERE id=?");
        if ($stmt->execute([$name, $address, $phone, $website, $desc, $id])) {
            echo json_encode(["success" => true, "message" => "Data berhasil diupdate"]);
        } else {
            echo json_encode(["success" => false, "message" => "Gagal update"]);
        }
    }

    // DELETE
    if ($_GET['action'] == 'delete') {
        $id = $_POST['id'];
        $stmt = $conn->prepare("DELETE FROM master_suppliers WHERE id=?");
        if ($stmt->execute([$id])) {
            echo json_encode(["success" => true, "message" => "Data berhasil dihapus"]);
        } else {
            echo json_encode(["success" => false, "message" => "Gagal hapus"]);
        }
    }
}
?>