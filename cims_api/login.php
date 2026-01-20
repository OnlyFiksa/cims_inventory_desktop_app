<?php
include 'db_connect.php';

$method = $_SERVER['REQUEST_METHOD'];

if ($method == 'POST') {
    // Terima NIK & Password
    $nik = $_POST['nik'];
    $password = $_POST['password'];

    try {
        $stmt = $conn->prepare("SELECT * FROM users WHERE nik = ?");
        $stmt->execute([$nik]);
        $user = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($user) {
            // --- KEMBALI KE LOGIKA SEDERHANA ---
            // Cek apakah password input SAMA PERSIS dengan database
            if ($password == $user['password']) { 
                
                // Tetap pertahankan Cek Status (Fitur bagus)
                if ($user['status'] != 'Active') {
                    echo json_encode(["success" => false, "message" => "Akun Non-Aktif."]);
                    exit();
                }

                echo json_encode([
                    "success" => true,
                    "message" => "Login Berhasil",
                    "user" => [
                        "id" => $user['id'],
                        "name" => $user['name'],
                        "role" => $user['role'],
                        "nik" => $user['nik']
                    ]
                ]);
            } else {
                echo json_encode(["success" => false, "message" => "Password salah!"]);
            }
        } else {
            echo json_encode(["success" => false, "message" => "NIK tidak terdaftar!"]);
        }
    } catch (Exception $e) {
        echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
    }
}
?>