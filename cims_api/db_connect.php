<?php
// Izinkan akses dari mana saja (CORS)
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: GET,POST,PUT,DELETE");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// Matikan error HTML
error_reporting(0);
ini_set('display_errors', 0);

$host = "localhost";
$user = "root";
$pass = "";
$db   = "cims_db";

try {
    $conn = new PDO("mysql:host=$host;dbname=$db", $user, $pass);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch(PDOException $e) {
    echo json_encode(["success" => false, "message" => "Koneksi Gagal: " . $e->getMessage()]);
    die();
}