<?php
include 'db_connect.php';
$method = $_SERVER['REQUEST_METHOD'];

if ($method == 'GET') {
    $stmt = $conn->prepare("SELECT * FROM master_units ORDER BY id ASC");
    $stmt->execute();
    echo json_encode(["success" => true, "data" => $stmt->fetchAll(PDO::FETCH_ASSOC)]);
}

if ($method == 'POST' && !isset($_GET['action'])) {
    $code = $_POST['code']; $name = $_POST['name'];
    try {
        $stmt = $conn->prepare("INSERT INTO master_units (code, name) VALUES (?, ?)");
        $stmt->execute([$code, $name]);
        echo json_encode(["success" => true, "message" => "Satuan berhasil disimpan"]);
    } catch (PDOException $e) { echo json_encode(["success" => false, "message" => $e->getMessage()]); }
}

if ($method == 'POST' && isset($_GET['action'])) {
    if ($_GET['action'] == 'update') {
        $stmt = $conn->prepare("UPDATE master_units SET code=?, name=? WHERE id=?");
        $stmt->execute([$_POST['code'], $_POST['name'], $_POST['id']]);
        echo json_encode(["success" => true, "message" => "Update berhasil"]);
    }
    if ($_GET['action'] == 'delete') {
        $stmt = $conn->prepare("DELETE FROM master_units WHERE id=?");
        $stmt->execute([$_POST['id']]);
        echo json_encode(["success" => true, "message" => "Hapus berhasil"]);
    }
}
?>