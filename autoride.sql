-- ========================================================
-- AUTORIDE DATABASE OPTIMIZATION SCRIPT
-- Data Architect Solution
-- ========================================================

DROP DATABASE IF EXISTS autoride_db;
CREATE DATABASE autoride_db;
USE autoride_db;

-- 1. BẢNG DỮ LIỆU XE
CREATE TABLE Cars (
    car_id INT AUTO_INCREMENT PRIMARY KEY,
    model_name VARCHAR(100) NOT NULL,
    license_plate VARCHAR(20) UNIQUE NOT NULL
);

-- 2. BẢNG HỢP ĐỒNG THUÊ XE (ĐÃ TỐI ƯU HÓA)
CREATE TABLE Rentals (
    rental_id INT AUTO_INCREMENT PRIMARY KEY,
    car_id INT NOT NULL,
    customer_name VARCHAR(100) NOT NULL,
    rent_date DATETIME NOT NULL,
    return_date DATETIME DEFAULT NULL,
    
    -- Khóa chặt trạng thái vòng đời hợp đồng bằng ENUM
    status ENUM('BOOKED', 'ACTIVE', 'COMPLETED', 'CANCELLED') DEFAULT 'BOOKED',
    
    -- Các trường quản lý tài chính dùng DECIMAL để tránh sai số
    security_deposit DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    late_fee DECIMAL(12, 2) DEFAULT 0.00,
    damage_fee DECIMAL(12, 2) DEFAULT 0.00,
    
    FOREIGN KEY (car_id) REFERENCES Cars(car_id) ON DELETE RESTRICT
);

-- 3. BẢNG BIÊN BẢN KIỂM TRA XE (INSPECTIONS)
CREATE TABLE Inspections (
    inspection_id INT AUTO_INCREMENT PRIMARY KEY,
    rental_id INT NOT NULL,
    inspection_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    damage_description TEXT,
    inspector_name VARCHAR(100) NOT NULL,
    FOREIGN KEY (rental_id) REFERENCES Rentals(rental_id) ON DELETE RESTRICT
);

-- ========================================================
-- KỊCH BẢN THỰC THI NGHIỆP VỤ (DML)
-- ========================================================

-- Bước 1: Thêm dữ liệu xe mẫu
INSERT INTO Cars (model_name, license_plate) 
VALUES ('Toyota Camry', '30A-123.45');

-- Bước 2: Khách hàng "Nguyen Van A" đặt xe và đóng cọc 10.000.000 VNĐ
INSERT INTO Rentals (car_id, customer_name, rent_date, status, security_deposit)
VALUES (1, 'Nguyen Van A', '2026-10-01 08:00:00', 'BOOKED', 10000000.00);

-- Bước 3: Khách nhận xe -> Trạng thái chuyển sang ACTIVE
UPDATE Rentals 
SET status = 'ACTIVE' 
WHERE rental_id = 1;

-- Bước 4: Khách trả xe -> Nhân viên kiểm tra phát hiện vỡ đèn pha trái
INSERT INTO Inspections (rental_id, inspection_date, damage_description, inspector_name)
VALUES (1, '2026-10-05 17:00:00', 'Vỡ đèn pha trái do va quẹt', 'Kỹ thuật viên Tran Van B');

-- Bước 5: Cập nhật thông tin trả xe, ghi nhận chi phí phạt và hoàn tất hợp đồng
UPDATE Rentals 
SET return_date = '2026-10-05 17:00:00',
    status = 'COMPLETED',
    late_fee = 0.00,
    damage_fee = 2000000.00
WHERE rental_id = 1;

-- ========================================================
-- TRUY VẤN TÍNH TOÁN TIỀN HOÀN TRẢ CHO KHÁCH (REFUND)
-- ========================================================

SELECT 
    r.rental_id,
    r.customer_name,
    c.model_name,
    c.license_plate,
    r.security_deposit,
    r.late_fee,
    r.damage_fee,
    i.damage_description,
    -- Tiền hoàn lại = Tiền cọc - Phí trễ - Phí hư hỏng
    (r.security_deposit - r.late_fee - r.damage_fee) AS refund_amount,
    r.status
FROM Rentals r
JOIN Cars c ON r.car_id = c.car_id
LEFT JOIN Inspections i ON r.rental_id = i.rental_id
WHERE r.rental_id = 1;