<?php
include 'db_connect.php';
header('Content-Type: application/json');

$method = $_SERVER['REQUEST_METHOD'];

// 1. VERIFIKASI STOK MASUK
if ($method == 'POST') {
    $trxId = $_POST['trx_id'];
    
    // Ambil Data Transaksi
    $stmt = $conn->prepare("SELECT * FROM trx_in WHERE id = ?");
    $stmt->execute([$trxId]);
    $trx = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$trx) {
        echo json_encode(["success" => false, "message" => "Transaksi tidak ditemukan"]);
        exit();
    }

    if ($trx['status'] == 'verified') {
        echo json_encode(["success" => false, "message" => "Transaksi sudah diverifikasi sebelumnya"]);
        exit();
    }

    try {
        $conn->beginTransaction();

        // A. Generate Kode Unik Per Botol
        // Format: [KodeBarang]-[Batch]-a, b, c...
        // Kita butuh Kode Barang dari tabel items
        $stmtItem = $conn->prepare("SELECT code FROM items WHERE id = ?");
        $stmtItem->execute([$trx['item_id']]);
        $itemCode = $stmtItem->fetchColumn();

        // Cek sudah ada berapa batch sebelumnya untuk item ini (Logic Huruf a, b, c)
        // Sesuai manual: Huruf a adalah default master. Huruf b, c muncul di transaksi.
        // Kita hitung jumlah inventory_batches untuk item ini.
        $stmtCount = $conn->prepare("SELECT COUNT(*) FROM inventory_batches WHERE item_id = ?");
        $stmtCount->execute([$trx['item_id']]);
        $count = $stmtCount->fetchColumn();
        
        // Konversi angka ke huruf (0=a, 1=b, 2=c...)
        $suffix = chr(97 + $count); // 97 adalah ASCII 'a'

        $uniqueCode = $itemCode . "-" . $suffix;

        // B. Masukkan ke Inventory Batches (Stok Aktif)
        $sqlInv = "INSERT INTO inventory_batches 
                   (item_id, unique_code, supplier_batch, expired_date, qty_current, trx_in_id) 
                   VALUES (?, ?, ?, ?, ?, ?)";
        $stmtInv = $conn->prepare($sqlInv);
        $stmtInv->execute([
            $trx['item_id'], 
            $uniqueCode, 
            $trx['supplier_batch'], 
            $trx['expired_date'], 
            $trx['qty_in'], 
            $trx['id']
        ]);

        // C. Update Status trx_in jadi 'verified'
        $stmtUpd = $conn->prepare("UPDATE trx_in SET status = 'verified' WHERE id = ?");
        $stmtUpd->execute([$trxId]);

        $conn->commit();
        echo json_encode(["success" => true, "message" => "Stok berhasil diverifikasi & masuk gudang"]);

    } catch (Exception $e) {
        $conn->rollBack();
        echo json_encode(["success" => false, "message" => "Gagal Verifikasi: " . $e->getMessage()]);
    }
}
?>