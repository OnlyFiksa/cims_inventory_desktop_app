<?php
include 'db_connect.php';

$method = $_SERVER['REQUEST_METHOD'];

// 1. GET (AMBIL DATA)
if ($method == 'GET') {
    $stmt = $conn->prepare("SELECT * FROM master_categories ORDER BY id ASC");
    $stmt->execute();
    $result = $stmt->fetchAll(PDO::FETCH_ASSOC);
    echo json_encode(["success" => true, "data" => $result]);
}

// 2. POST (TAMBAH DATA)
if ($method == 'POST' && !isset($_GET['action'])) {
    $name = $_POST['name'];
    $desc = $_POST['description'] ?? '';

    try {
        $stmt = $conn->prepare("INSERT INTO master_categories (name, description) VALUES (?, ?)");
        $stmt->execute([$name, $desc]);
        echo json_encode(["success" => true, "message" => "Kategori berhasil disimpan"]);
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
        $desc = $_POST['description'] ?? '';

        $stmt = $conn->prepare("UPDATE master_categories SET name=?, description=? WHERE id=?");
        if ($stmt->execute([$name, $desc, $id])) {
            echo json_encode(["success" => true, "message" => "Kategori berhasil diupdate"]);
        } else {
            echo json_encode(["success" => false, "message" => "Gagal update"]);
        }
    }

    // DELETE
    if ($_GET['action'] == 'delete') {
        $id = $_POST['id'];
        $stmt = $conn->prepare("DELETE FROM master_categories WHERE id=?");
        if ($stmt->execute([$id])) {
            echo json_encode(["success" => true, "message" => "Kategori berhasil dihapus"]);
        } else {
            echo json_encode(["success" => false, "message" => "Gagal hapus"]);
        }
    }
}
?>