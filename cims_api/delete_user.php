<?php
include 'db_connect.php';
header('Content-Type: application/json');

// ID user yang mau dihapus
$target_id = $_POST['id'] ?? null;
// ID user yang sedang login (Supervisor)
$admin_id = $_POST['admin_id'] ?? null;

if (!$target_id || !$admin_id) {
    echo json_encode(["success" => false, "message" => "Parameter ID tidak lengkap"]);
    exit;
}

// 1. CEK: JANGAN BIARKAN MENGHAPUS DIRI SENDIRI
if ($target_id == $admin_id) {
    echo json_encode(["success" => false, "message" => "Anda tidak bisa menghapus akun Anda sendiri!"]);
    exit;
}

try {
    // 2. LOGIC BARU: LANGSUNG HAPUS (SOFT DELETE)
    // Tidak peduli status awalnya Active atau Non-Active, langsung 'Deleted'.
    // Ini menjawab request Bapak yang kedua.
    
    $sql = "UPDATE users SET status = 'Deleted' WHERE id = ?";
    $stmt = $conn->prepare($sql);
    $stmt->execute([$target_id]);

    echo json_encode([
        "success" => true, 
        "message" => "User berhasil dihapus."
    ]);

} catch (Exception $e) {
    echo json_encode(["success" => false, "message" => "Database Error: " . $e->getMessage()]);
}
?>