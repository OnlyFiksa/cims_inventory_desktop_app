<?php
include 'db_connect.php';

$method = $_SERVER['REQUEST_METHOD'];

// 1. GET (AMBIL DATA)
if ($method == 'GET') {
    $stmt = $conn->prepare("SELECT * FROM master_types ORDER BY id ASC");
    $stmt->execute();
    $result = $stmt->fetchAll(PDO::FETCH_ASSOC);
    echo json_encode(["success" => true, "data" => $result]);
}

// 2. POST (TAMBAH DATA)
if ($method == 'POST' && !isset($_GET['action'])) {
    $code = $_POST['code'];
    $name = $_POST['name'];
    $desc = $_POST['description'] ?? ''; // Tangkap Deskripsi

    try {
        // Insert Description juga
        $stmt = $conn->prepare("INSERT INTO master_types (code, name, description) VALUES (?, ?, ?)");
        $stmt->execute([$code, $name, $desc]);
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
        $desc = $_POST['description'] ?? '';

        // Update Description juga
        $stmt = $conn->prepare("UPDATE master_types SET code=?, name=?, description=? WHERE id=?");
        if ($stmt->execute([$code, $name, $desc, $id])) {
            echo json_encode(["success" => true, "message" => "Data berhasil diupdate"]);
        } else {
            echo json_encode(["success" => false, "message" => "Gagal update"]);
        }
    }

    // DELETE
    if ($_GET['action'] == 'delete') {
        $id = $_POST['id'];
        $stmt = $conn->prepare("DELETE FROM master_types WHERE id=?");
        if ($stmt->execute([$id])) {
            echo json_encode(["success" => true, "message" => "Data berhasil dihapus"]);
        } else {
            echo json_encode(["success" => false, "message" => "Gagal hapus"]);
        }
    }
}
?>