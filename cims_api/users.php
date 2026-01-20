<?php
include 'db_connect.php';
header('Content-Type: application/json');

$method = $_SERVER['REQUEST_METHOD'];

// 1. GET ALL USERS (YANG TIDAK DIHAPUS)
if ($method == 'GET') {
    // PERUBAHAN UTAMA DISINI: Tambahkan WHERE status != 'Deleted'
    // Agar user yang sudah dihapus tidak terambil oleh Flutter
    $stmt = $conn->query("SELECT * FROM users WHERE status != 'Deleted' ORDER BY name ASC");
    echo json_encode(["success" => true, "data" => $stmt->fetchAll(PDO::FETCH_ASSOC)]);
}

// 2. POST (ADD USER)
if ($method == 'POST' && !isset($_GET['action'])) {
    $nik = $_POST['nik'];
    $name = $_POST['name'];
    $email = $_POST['email'];
    $pass = $_POST['password'];
    $role = strtolower($_POST['role']); 
    $status = $_POST['status'];

    // Cek NIK Duplikat
    $check = $conn->prepare("SELECT id FROM users WHERE nik = ? AND status != 'Deleted'");
    $check->execute([$nik]);
    if ($check->rowCount() > 0) {
        echo json_encode(["success" => false, "message" => "NIK sudah terdaftar!"]);
        exit();
    }

    try {
        $stmt = $conn->prepare("INSERT INTO users (nik, name, email, password, role, status) VALUES (?, ?, ?, ?, ?, ?)");
        $stmt->execute([$nik, $name, $email, $pass, $role, $status]);   
        echo json_encode(["success" => true, "message" => "User berhasil ditambahkan"]);
    } catch (PDOException $e) {
        echo json_encode(["success" => false, "message" => $e->getMessage()]);
    }
}

// 3. UPDATE & DELETE
if ($method == 'POST' && isset($_GET['action'])) {
    
    // UPDATE USER
    if ($_GET['action'] == 'update') {
        $id = $_POST['id'];
        $name = $_POST['name'];
        $email = $_POST['email'];
        $pass = $_POST['password'];
        $role = strtolower($_POST['role']);
        $status = $_POST['status'];

        try {
            $stmt = $conn->prepare("UPDATE users SET name=?, email=?, password=?, role=?, status=? WHERE id=?");
            $stmt->execute([$name, $email, $pass, $role, $status, $id]);
            echo json_encode(["success" => true, "message" => "Data user diperbarui"]);
        } catch (PDOException $e) {
            echo json_encode(["success" => false, "message" => $e->getMessage()]);
        }
    }

    // DELETE USER (SOFT DELETE LOGIC)
    // Ini disesuaikan juga, barangkali bapak pakai endpoint ini suatu saat nanti
    if ($_GET['action'] == 'delete') {
        $id = $_POST['id'];
        try {
            // JANGAN DIHAPUS PERMANEN, CUKUP UBAH STATUS JADI 'Deleted'
            $stmt = $conn->prepare("UPDATE users SET status = 'Deleted' WHERE id=?");
            $stmt->execute([$id]);
            
            echo json_encode(["success" => true, "message" => "User berhasil dihapus."]);
        } catch (PDOException $e) {
            echo json_encode(["success" => false, "message" => $e->getMessage()]);
        }
    }
}
?>