<?php
include 'db_connect.php';

$method = $_SERVER['REQUEST_METHOD'];

// 1. GET (AMBIL DATA)
if ($method == 'GET') {
    $stmt = $conn->prepare("SELECT * FROM master_pemilik ORDER BY id DESC");
    $stmt->execute();
    $result = $stmt->fetchAll(PDO::FETCH_ASSOC);
    echo json_encode(["success" => true, "data" => $result]);
}

// 2. POST (TAMBAH DATA BARU)
if ($method == 'POST' && !isset($_GET['action'])) {
    $code = $_POST['code'];
    $name = $_POST['name'];
    $address = $_POST['address'] ?? '';
    $phone = $_POST['phone'] ?? '';
    $desc = $_POST['description'] ?? '';

    // Cek Duplikat Kode di Server Side (Opsional, karena di UI sudah dicek)
    $check = $conn->prepare("SELECT id FROM master_pemilik WHERE code = ?");
    $check->execute([$code]);
    if ($check->rowCount() > 0) {
        echo json_encode(["success" => false, "message" => "Kode sudah ada!"]);
        exit();
    }

    try {
        $stmt = $conn->prepare("INSERT INTO master_pemilik (code, name, address, phone, description) VALUES (?, ?, ?, ?, ?)");
        $stmt->execute([$code, $name, $address, $phone, $desc]);
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
        $code = $_POST['code'];
        $name = $_POST['name'];
        $address = $_POST['address'] ?? '';
        $phone = $_POST['phone'] ?? '';
        $desc = $_POST['description'] ?? '';

        $stmt = $conn->prepare("UPDATE master_pemilik SET code=?, name=?, address=?, phone=?, description=? WHERE id=?");
        if ($stmt->execute([$code, $name, $address, $phone, $desc, $id])) {
            echo json_encode(["success" => true, "message" => "Data berhasil diupdate"]);
        } else {
            echo json_encode(["success" => false, "message" => "Gagal update"]);
        }
    }

    // DELETE
    if ($_GET['action'] == 'delete') {
        $id = $_POST['id'];
        
        // Cek apakah data dipakai di tabel lain? (Opsional logic constraint)
        // ...

        $stmt = $conn->prepare("DELETE FROM master_pemilik WHERE id=?");
        if ($stmt->execute([$id])) {
            echo json_encode(["success" => true, "message" => "Data berhasil dihapus"]);
        } else {
            echo json_encode(["success" => false, "message" => "Gagal hapus"]);
        }
    }
}
?>