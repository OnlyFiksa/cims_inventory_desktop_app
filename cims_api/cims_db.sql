-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Jan 20, 2026 at 03:57 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.0.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `cims_db`
--

-- --------------------------------------------------------

--
-- Table structure for table `inventory_batches`
--

CREATE TABLE `inventory_batches` (
  `id` int(11) NOT NULL,
  `batch_no` varchar(50) DEFAULT NULL COMMENT 'Nomor Batch Internal / ADJ',
  `item_id` int(11) NOT NULL,
  `qty_initial` int(11) NOT NULL DEFAULT 0 COMMENT 'Jumlah Awal Masuk',
  `unique_code` varchar(50) NOT NULL,
  `supplier_batch` varchar(50) NOT NULL,
  `expired_date` date NOT NULL,
  `price` decimal(15,2) DEFAULT 0.00,
  `created_by` varchar(50) DEFAULT 'System',
  `qty_current` int(11) NOT NULL DEFAULT 0,
  `trx_in_id` int(11) NOT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `inventory_batches`
--

INSERT INTO `inventory_batches` (`id`, `batch_no`, `item_id`, `qty_initial`, `unique_code`, `supplier_batch`, `expired_date`, `price`, `created_by`, `qty_current`, `trx_in_id`, `is_active`, `created_at`) VALUES
(5, NULL, 3, 0, 'PKR-003-0101-a-a', '', '2026-01-18', 0.00, 'System', 10, 2, 1, '2026-01-18 05:41:00'),
(6, NULL, 5, 0, 'PKR-003-0101-a-a', '', '2026-01-21', 0.00, 'System', 0, 4, 1, '2026-01-18 14:43:03'),
(7, 'ADJ-260120-660', 5, 4, '', '', '2027-01-20', 0.00, 'System Adjustment', 1, 0, 1, '2026-01-20 01:17:13'),
(8, NULL, 5, 0, 'PKR-003-0101-a-c', '', '2026-01-19', 0.00, 'System', 0, 3, 1, '2026-01-20 01:17:54'),
(9, 'BATCH-260120025333', 5, 3, '', '', '2026-01-20', 0.00, 'Supervisor Input', 0, 0, 1, '2026-01-20 01:53:33');

-- --------------------------------------------------------

--
-- Table structure for table `items`
--

CREATE TABLE `items` (
  `id` int(11) NOT NULL,
  `code` varchar(50) NOT NULL,
  `name` varchar(255) NOT NULL,
  `category_id` int(11) DEFAULT NULL,
  `owner_id` int(11) DEFAULT NULL,
  `type_id` int(11) DEFAULT NULL,
  `manufacturer_id` int(11) DEFAULT NULL,
  `supplier_id` int(11) DEFAULT NULL,
  `packaging_id` int(11) DEFAULT NULL,
  `min_stock` int(11) DEFAULT 0,
  `description` text DEFAULT NULL,
  `status` varchar(20) NOT NULL DEFAULT 'Active',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `items`
--

INSERT INTO `items` (`id`, `code`, `name`, `category_id`, `owner_id`, `type_id`, `manufacturer_id`, `supplier_id`, `packaging_id`, `min_stock`, `description`, `status`, `created_at`, `updated_at`) VALUES
(3, 'PKR-003-0101-a', 'Coca-Cola', 1, 1, 1, 1, 1, 1, 2, '', 'Deleted', '2026-01-18 03:55:14', '2026-01-18 05:42:23'),
(4, 'PKR-002-0101-a', 'Fanta', 1, 1, 1, 1, 1, 1, 5, '', 'Deleted', '2026-01-18 05:42:51', '2026-01-18 14:14:10'),
(5, 'PKR-003-0101-a', 'Yupi', 1, 1, 1, 1, 1, 1, 3, '', 'Active', '2026-01-18 14:14:34', '2026-01-18 14:14:34');

-- --------------------------------------------------------

--
-- Table structure for table `master_categories`
--

CREATE TABLE `master_categories` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `description` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `master_categories`
--

INSERT INTO `master_categories` (`id`, `name`, `description`) VALUES
(1, 'Kimia', 'Bahan kimia umum'),
(2, 'Media', 'Media pertumbuhan bakteri'),
(3, 'Sintesis', '');

-- --------------------------------------------------------

--
-- Table structure for table `master_manufacturers`
--

CREATE TABLE `master_manufacturers` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `address` text DEFAULT NULL,
  `phone` varchar(50) DEFAULT NULL,
  `website` varchar(100) DEFAULT NULL,
  `description` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `master_manufacturers`
--

INSERT INTO `master_manufacturers` (`id`, `name`, `address`, `phone`, `website`, `description`) VALUES
(1, 'Merck', 'Germany', NULL, NULL, NULL),
(2, 'Sigma Aldrich', 'USA', '', '', '');

-- --------------------------------------------------------

--
-- Table structure for table `master_packagings`
--

CREATE TABLE `master_packagings` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `value` double NOT NULL,
  `unit_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `master_packagings`
--

INSERT INTO `master_packagings` (`id`, `name`, `value`, `unit_id`) VALUES
(1, 'Botol', 1, 2);

-- --------------------------------------------------------

--
-- Table structure for table `master_pemilik`
--

CREATE TABLE `master_pemilik` (
  `id` int(11) NOT NULL,
  `code` varchar(10) NOT NULL,
  `name` varchar(100) NOT NULL,
  `address` text DEFAULT NULL,
  `phone` varchar(50) DEFAULT NULL,
  `description` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `master_pemilik`
--

INSERT INTO `master_pemilik` (`id`, `code`, `name`, `address`, `phone`, `description`) VALUES
(1, 'PK', 'PT. Vosen Pratita Kemindo', 'Jl. Daan Mogot KM 12', '021-54321', 'Milik Perusahaan'),
(2, 'TT', 'Titipan Vendor', '-', '-', 'Konsinyasi'),
(3, 'DO', 'Pt. dodol', 'wsd', '0', '');

-- --------------------------------------------------------

--
-- Table structure for table `master_suppliers`
--

CREATE TABLE `master_suppliers` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `address` text DEFAULT NULL,
  `phone` varchar(50) DEFAULT NULL,
  `website` varchar(100) DEFAULT NULL,
  `description` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `master_suppliers`
--

INSERT INTO `master_suppliers` (`id`, `name`, `address`, `phone`, `website`, `description`) VALUES
(1, 'PT. Indofa', NULL, '021-5551234', NULL, NULL),
(2, 'PT. Global', NULL, '031-8889999', NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `master_types`
--

CREATE TABLE `master_types` (
  `id` int(11) NOT NULL,
  `code` varchar(10) NOT NULL,
  `name` varchar(100) NOT NULL,
  `description` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `master_types`
--

INSERT INTO `master_types` (`id`, `code`, `name`, `description`) VALUES
(1, 'R', 'Reagen', NULL),
(2, 'M', 'Media Mikrobiologi', NULL),
(4, 'S', 'Solfen', 'Ini untuk pelarut');

-- --------------------------------------------------------

--
-- Table structure for table `master_units`
--

CREATE TABLE `master_units` (
  `id` int(11) NOT NULL,
  `code` varchar(20) NOT NULL,
  `name` varchar(50) NOT NULL,
  `description` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `master_units`
--

INSERT INTO `master_units` (`id`, `code`, `name`, `description`) VALUES
(1, 'L', 'Liter', NULL),
(2, 'ML', 'Mililiter', NULL),
(3, 'KG', 'Kilogram', NULL),
(4, 'G', 'Gram', NULL),
(5, 'PCS', 'Pieces', NULL),
(6, 'Mg', 'Miligram', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `trx_adjustments`
--

CREATE TABLE `trx_adjustments` (
  `id` int(11) NOT NULL,
  `trans_no` varchar(50) NOT NULL,
  `trans_date` date NOT NULL,
  `inventory_id` int(11) NOT NULL,
  `qty_system` int(11) NOT NULL,
  `qty_actual` int(11) NOT NULL,
  `qty_diff` int(11) NOT NULL,
  `reason` text NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `trx_adjustments`
--

INSERT INTO `trx_adjustments` (`id`, `trans_no`, `trans_date`, `inventory_id`, `qty_system`, `qty_actual`, `qty_diff`, `reason`, `created_at`) VALUES
(1, 'ADJ-20260118060150', '2026-01-18', 3, 3, 1, -2, 'Tumpah', '2026-01-18 05:01:50'),
(2, 'ADJ-20260118060546', '2026-01-18', 0, 1, 5, 4, 'Apakek', '2026-01-18 05:05:46'),
(3, 'ADJ-20260118060557', '2026-01-18', 0, 1, 5, 4, 'apaaja', '2026-01-18 05:05:57'),
(4, 'ADJ-20260118063359', '2026-01-18', 0, 1, 5, 4, 'apaja', '2026-01-18 05:33:59'),
(5, 'ADJ-20260120021713', '2026-01-20', 5, 1, 5, 4, 'A', '2026-01-20 01:17:13'),
(6, 'ADJ-20260120021723', '2026-01-20', 5, 5, 2, -3, 'B', '2026-01-20 01:17:23'),
(7, 'ADJ-20260120021808', '2026-01-20', 5, 7, 6, -1, 'H', '2026-01-20 01:18:08');

-- --------------------------------------------------------

--
-- Table structure for table `trx_in`
--

CREATE TABLE `trx_in` (
  `id` int(11) NOT NULL,
  `trans_no` varchar(50) NOT NULL,
  `trans_date` date NOT NULL,
  `surat_jalan` varchar(100) DEFAULT NULL,
  `po_number` varchar(100) DEFAULT NULL,
  `owner_id` int(11) NOT NULL,
  `manufacturer_id` int(11) NOT NULL,
  `supplier_id` int(11) NOT NULL,
  `item_id` int(11) NOT NULL,
  `packaging_id` int(11) NOT NULL,
  `recipient` varchar(100) DEFAULT NULL,
  `qty_in` int(11) NOT NULL,
  `unit_id` int(11) NOT NULL,
  `price` double DEFAULT 0,
  `total_price` double DEFAULT 0,
  `supplier_batch` varchar(50) DEFAULT NULL,
  `expired_date` date NOT NULL,
  `notes` text DEFAULT NULL,
  `status` enum('pending','verified','rejected') NOT NULL DEFAULT 'pending',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `trx_in`
--

INSERT INTO `trx_in` (`id`, `trans_no`, `trans_date`, `surat_jalan`, `po_number`, `owner_id`, `manufacturer_id`, `supplier_id`, `item_id`, `packaging_id`, `recipient`, `qty_in`, `unit_id`, `price`, `total_price`, `supplier_batch`, `expired_date`, `notes`, `status`, `created_at`) VALUES
(3, 'IN-260118153245', '2026-01-18', '', '', 3, 2, 2, 5, 1, '', 5, 3, 0, 0, '', '2026-01-19', '', 'verified', '2026-01-18 14:32:45'),
(4, 'IN-260118154204', '2026-01-18', '', '', 1, 1, 2, 5, 1, '', 1, 4, 0, 0, '', '2026-01-21', '', 'verified', '2026-01-18 14:42:04'),
(7, 'IN-260120025333', '2026-01-20', '', '', 1, 2, 2, 5, 1, '', 3, 3, 0, 0, '', '2026-01-20', '', 'verified', '2026-01-20 01:53:33');

-- --------------------------------------------------------

--
-- Table structure for table `trx_out`
--

CREATE TABLE `trx_out` (
  `id` int(11) NOT NULL,
  `trans_no` varchar(50) NOT NULL,
  `trans_date` date NOT NULL,
  `owner_id` int(11) NOT NULL,
  `item_id` int(11) NOT NULL,
  `created_by` varchar(100) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `qty_out` int(11) NOT NULL,
  `unit_id` int(11) NOT NULL,
  `in_use_exp_date` date DEFAULT NULL,
  `qc_number` varchar(50) DEFAULT NULL,
  `price` double DEFAULT 0,
  `total_price` double DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `trx_out`
--

INSERT INTO `trx_out` (`id`, `trans_no`, `trans_date`, `owner_id`, `item_id`, `created_by`, `description`, `qty_out`, `unit_id`, `in_use_exp_date`, `qc_number`, `price`, `total_price`, `created_at`) VALUES
(1, 'OUT-2601-0001', '2026-01-20', 3, 5, '', '', 8, 2, NULL, '', 0, 0, '2026-01-20 01:56:33');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `nik` varchar(50) NOT NULL,
  `name` varchar(100) NOT NULL,
  `email` varchar(100) NOT NULL,
  `password` varchar(255) NOT NULL,
  `role` enum('supervisor','staff','manager') NOT NULL DEFAULT 'staff',
  `status` enum('Active','Non-Active','Deleted') NOT NULL DEFAULT 'Active',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `nik`, `name`, `email`, `password`, `role`, `status`, `created_at`) VALUES
(1, 'SP01', 'Budi Supervisor', 'spv@vosen.co.id', '123', 'supervisor', 'Deleted', '2026-01-15 05:05:37'),
(4, 'K1020', 'Taufik', 'taufik@gmail.com', '123', 'supervisor', 'Active', '2026-01-16 11:54:24'),
(5, 'K1122', 'Siti', 'siti@gmail.com', '123', 'staff', 'Deleted', '2026-01-16 12:07:55'),
(6, 'K123', 'Nisa', 'nisa@gmail.com', '123', 'staff', 'Active', '2026-01-18 03:56:32');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `inventory_batches`
--
ALTER TABLE `inventory_batches`
  ADD PRIMARY KEY (`id`),
  ADD KEY `item_id` (`item_id`),
  ADD KEY `trx_in_id` (`trx_in_id`);

--
-- Indexes for table `items`
--
ALTER TABLE `items`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `master_categories`
--
ALTER TABLE `master_categories`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `master_manufacturers`
--
ALTER TABLE `master_manufacturers`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `master_packagings`
--
ALTER TABLE `master_packagings`
  ADD PRIMARY KEY (`id`),
  ADD KEY `unit_id` (`unit_id`);

--
-- Indexes for table `master_pemilik`
--
ALTER TABLE `master_pemilik`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `master_suppliers`
--
ALTER TABLE `master_suppliers`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `master_types`
--
ALTER TABLE `master_types`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `master_units`
--
ALTER TABLE `master_units`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `trx_adjustments`
--
ALTER TABLE `trx_adjustments`
  ADD PRIMARY KEY (`id`),
  ADD KEY `inventory_id` (`inventory_id`);

--
-- Indexes for table `trx_in`
--
ALTER TABLE `trx_in`
  ADD PRIMARY KEY (`id`),
  ADD KEY `item_id` (`item_id`),
  ADD KEY `owner_id` (`owner_id`),
  ADD KEY `manufacturer_id` (`manufacturer_id`),
  ADD KEY `supplier_id` (`supplier_id`),
  ADD KEY `packaging_id` (`packaging_id`),
  ADD KEY `fk_trx_in_unit` (`unit_id`);

--
-- Indexes for table `trx_out`
--
ALTER TABLE `trx_out`
  ADD PRIMARY KEY (`id`),
  ADD KEY `item_id` (`item_id`),
  ADD KEY `owner_id` (`owner_id`),
  ADD KEY `unit_id` (`unit_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `nik` (`nik`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `inventory_batches`
--
ALTER TABLE `inventory_batches`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT for table `items`
--
ALTER TABLE `items`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `master_categories`
--
ALTER TABLE `master_categories`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `master_manufacturers`
--
ALTER TABLE `master_manufacturers`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `master_packagings`
--
ALTER TABLE `master_packagings`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `master_pemilik`
--
ALTER TABLE `master_pemilik`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `master_suppliers`
--
ALTER TABLE `master_suppliers`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `master_types`
--
ALTER TABLE `master_types`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `master_units`
--
ALTER TABLE `master_units`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `trx_adjustments`
--
ALTER TABLE `trx_adjustments`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `trx_in`
--
ALTER TABLE `trx_in`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `trx_out`
--
ALTER TABLE `trx_out`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `master_packagings`
--
ALTER TABLE `master_packagings`
  ADD CONSTRAINT `master_packagings_ibfk_1` FOREIGN KEY (`unit_id`) REFERENCES `master_units` (`id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
