-- =========================================================================
-- POLYTECHNIC UNIVERSITY OF THE PHILIPPINES - PARANAQUE CAMPUS
-- RESOURCE RESERVATION SYSTEM DATABASE SCHEMA (MySQL)
-- First-time setup script
-- =========================================================================

CREATE DATABASE IF NOT EXISTS `pup_reservation` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `pup_reservation`;

-- =========================================================================
-- 1. ADMINISTRATOR TABLE
-- =========================================================================
CREATE TABLE IF NOT EXISTS `admin` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `username` VARCHAR(50) NOT NULL UNIQUE,
    `password_hash` VARCHAR(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================
-- 2. AUTHORIZED USERS TABLE
-- =========================================================================
CREATE TABLE IF NOT EXISTS `authorized_users` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `student_number` VARCHAR(50) NOT NULL UNIQUE,
    `last_name` VARCHAR(100) NOT NULL,
    `first_name` VARCHAR(100) NOT NULL,
    `middle_name` VARCHAR(100) DEFAULT '',
    `pup_email` VARCHAR(255) NOT NULL UNIQUE,
    `password_hash` VARCHAR(255) NOT NULL,
    `email_verified` BOOLEAN DEFAULT FALSE,
    `password_changed` BOOLEAN DEFAULT FALSE,
    `account_status` VARCHAR(20) DEFAULT 'ACTIVE',
    `role` VARCHAR(20) DEFAULT 'STUDENT',
    `contact_number` VARCHAR(20) DEFAULT '',
    `program` VARCHAR(20) DEFAULT 'BSIT',
    `year_section` VARCHAR(20) DEFAULT '1-1',
    `failed_otp_attempts` INT DEFAULT 0,
    `lockout_until` VARCHAR(50) DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================
-- 3. OTP VERIFICATIONS TABLE
-- =========================================================================
CREATE TABLE IF NOT EXISTS `otp_verifications` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT NOT NULL,
    `otp_code` VARCHAR(255) NOT NULL,
    `expires_at` VARCHAR(50) NOT NULL,
    `is_used` BOOLEAN DEFAULT FALSE,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_otp_user`
        FOREIGN KEY (`user_id`) REFERENCES `authorized_users` (`id`)
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================
-- 4. FACILITIES TABLE
-- =========================================================================
CREATE TABLE IF NOT EXISTS `facilities` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `code` VARCHAR(50) NOT NULL UNIQUE,
    `type` VARCHAR(100) NOT NULL,
    `status` VARCHAR(50) DEFAULT 'Available',
    INDEX `idx_facility_type` (`type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================
-- 5. PROJECTORS TABLE
-- =========================================================================
CREATE TABLE IF NOT EXISTS `projectors` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `code` VARCHAR(50) NOT NULL UNIQUE,
    `model` VARCHAR(100) NOT NULL,
    `status` VARCHAR(50) DEFAULT 'Available'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================
-- 6. RESERVATION REQUESTS TABLE
-- =========================================================================
CREATE TABLE IF NOT EXISTS `reservation_requests` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `student_id` INT NOT NULL,
    `facility_type` VARCHAR(100) NOT NULL,
    `facility_id` INT DEFAULT NULL,
    `projector_id` INT DEFAULT NULL,
    `schedule_date` VARCHAR(20) NOT NULL,
    `start_time` VARCHAR(20) NOT NULL,
    `end_time` VARCHAR(20) NOT NULL,
    `course_code` VARCHAR(50) NOT NULL,
    `course_name` VARCHAR(255) NOT NULL,
    `professor` VARCHAR(255) NOT NULL,
    `status` VARCHAR(50) DEFAULT 'PENDING APPROVAL',
    `remarks` TEXT DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `checkout_time` VARCHAR(50) DEFAULT NULL,
    `return_time` VARCHAR(50) DEFAULT NULL,
    `released_by` VARCHAR(100) DEFAULT NULL,
    `received_by` VARCHAR(255) DEFAULT NULL,
    `returned_to` VARCHAR(100) DEFAULT NULL,
    `equipment_condition` TEXT DEFAULT NULL,
    CONSTRAINT `fk_reservation_student`
        FOREIGN KEY (`student_id`) REFERENCES `authorized_users` (`id`)
        ON DELETE CASCADE,
    CONSTRAINT `fk_reservation_facility`
        FOREIGN KEY (`facility_id`) REFERENCES `facilities` (`id`)
        ON DELETE SET NULL,
    CONSTRAINT `fk_reservation_projector`
        FOREIGN KEY (`projector_id`) REFERENCES `projectors` (`id`)
        ON DELETE SET NULL,
    INDEX `idx_res_schedule` (`schedule_date`, `start_time`, `end_time`),
    INDEX `idx_res_facility` (`facility_id`),
    INDEX `idx_res_projector` (`projector_id`),
    INDEX `idx_res_student` (`student_id`),
    INDEX `idx_res_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================
-- 7. SYSTEM LOGS TABLE
-- =========================================================================
CREATE TABLE IF NOT EXISTS `system_logs` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `admin_username` VARCHAR(50) DEFAULT NULL,
    `student_id` INT DEFAULT NULL,
    `action` VARCHAR(255) NOT NULL,
    `details` TEXT NOT NULL,
    `ip_address` VARCHAR(45) NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_log_student`
        FOREIGN KEY (`student_id`) REFERENCES `authorized_users` (`id`)
        ON DELETE SET NULL,
    INDEX `idx_log_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================
-- 8. AI SETTINGS TABLE
-- =========================================================================
CREATE TABLE IF NOT EXISTS `ai_settings` (
    `setting_key` VARCHAR(100) PRIMARY KEY,
    `setting_value` VARCHAR(255) NOT NULL,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================
-- SEED INITIAL DATA
-- =========================================================================

-- 1. Seed Default Administrator Account (Username: admin, Password: RSadmin@1904)
INSERT IGNORE INTO `admin` (`username`, `password_hash`)
VALUES (
    'admin',
    'scrypt:32768:8:1$HxsMUbqfjC7SiWQI$b7eb9643f71fa96df98cd3804cd492a6a351ac5d3a6e61dbf94724793f042144608153c8c0a9df8234eae642a938fd73e9cdc144fbfb535c924f1b2d38d0fb2c'
);

-- 2. Seed Campus Facilities
INSERT IGNORE INTO `facilities` (`id`, `code`, `type`, `status`) VALUES
(1, 'AVR-01', 'Audio-Visual Room (AVR)', 'Available'),
(2, 'COMP-LAB-01', 'Computer Laboratory', 'Available'),
(3, 'HM-LAB-01', 'Hospitality Management Laboratory', 'Available');

-- 3. Seed Campus Projectors
INSERT IGNORE INTO `projectors` (`id`, `code`, `model`, `status`) VALUES
(1, 'PJ-001', 'Epson EB-982W', 'Available'),
(2, 'PJ-002', 'Epson EB-982W', 'Available'),
(3, 'PJ-003', 'Epson EB-982W', 'Available'),
(4, 'PJ-004', 'Epson EB-982W', 'Available'),
(5, 'PJ-005', 'Epson EB-982W', 'Available'),
(6, 'PJ-006', 'Epson EB-982W', 'Available'),
(7, 'PJ-007', 'Epson EB-982W', 'Available'),
(8, 'PJ-008', 'Epson EB-982W', 'Available'),
(9, 'PJ-009', 'Epson EB-982W', 'Available'),
(10, 'PJ-010', 'Epson EB-982W', 'Available');

-- 4. Seed AI Settings
INSERT IGNORE INTO `ai_settings` (`setting_key`, `setting_value`) VALUES
('buffer_minutes', '15'),
('auto_suggest', '1'),
('peak_warning', '1'),
('email_alerts', '1');

-- 5. Seed Authorized Users
INSERT IGNORE INTO `authorized_users` (`student_number`, `last_name`, `first_name`, `middle_name`, `pup_email`, `password_hash`, `email_verified`, `password_changed`, `account_status`, `role`, `program`, `year_section`) VALUES
('2024-00538-PQ-1', 'Aguilon', 'Kate Heart', '', 'kateheartvaguilon@iskolarngbayan.pup.edu.ph', 'scrypt:32768:8:1$54i85G9PGdcJc0eR$87ed761f37625ef46c32de9843a1dfb5928b0fae5563f1e022bf4bbd8a5505e224d7133adea50b1bdba2d2b38ff6d0d14905f07755e411a090a3d280a356f8a2', FALSE, FALSE, 'ACTIVE', 'STUDENT', 'BSIT', '3-1'),
('2023-00201-PQ-0', 'Alim', 'Farhana', 'Sumandal', 'farhanasalim@iskolarngbayan.pup.edu.ph', 'scrypt:32768:8:1$KzWEiq4SgSD2Q14W$fe9c353a57b363126d7059ba68843d3c0b65b315b28e86ede287f54f077a0b11ec1c12a8d0751ed438a7774a5fe9b9260ad18d3decbe76f11f0a5c259df7087f', FALSE, FALSE, 'ACTIVE', 'STUDENT', 'BSIT', '3-1'),
('2023-00220-PQ-0', 'Atok', 'Marion Olivier', 'Cobo', 'marionoliviercatok@iskolarngbayan.pup.edu.ph', 'scrypt:32768:8:1$dlHYmSToTF1o7K47$be25290dea821355ed47fa24a102ae87b452719ad7322b0ef763c078f0a43d471fe58f08d4942ac4e5ecd2f809fcdc62e33f5ae2918530cbaa3a51d32725db32', FALSE, FALSE, 'ACTIVE', 'STUDENT', 'BSIT', '3-1'),
('2023-00087-PQ-0', 'Baaco', 'Kimvherly', '', 'kimvherlyhbaaco@iskolarngbayan.pup.edu.ph', 'scrypt:32768:8:1$i836Du2YRwxtABRw$f3e53f991670f572b3ccf66d99ddd34a16bf1463fce2daa3b04f2d5f92197fe55bcdfe76d1ea863f559489af8982a30af4c9df8da618b756207d10b67593092c', FALSE, FALSE, 'ACTIVE', 'STUDENT', 'BSIT', '3-1'),
('2023-00304-PQ-0', 'Bagsic', 'Jessy Ross', 'Lim', 'jessyrosslbagsic@iskolarngbayan.pup.edu.ph', 'scrypt:32768:8:1$81k3M3wrNQWteiTD$1833ae5863d7a16aaab855405cf8bd08a525764f3882fcad6ae8695a8cc9aa1489c7ed2c4cec0c071f560f5dc1c82d021fe3702dd2a173412c77ea6b332a0a34', FALSE, FALSE, 'ACTIVE', 'STUDENT', 'BSIT', '3-1'),
('2023-00144-PQ-0', 'Baladjay', 'Jestine Nicole', 'Bellales', 'jestinenicolebbaladjay@iskolarngbayan.pup.edu.ph', 'scrypt:32768:8:1$WZDiqb3KkrgqieQN$bc0b60e318bbbb5463d3d6d0ef08cb14f25aa00ccd462ed247b8418aefaca952f07c0dc92e4794e26daf49b599d9ac6ab15288bbf5f8ca82c406d56533ff8505', FALSE, FALSE, 'ACTIVE', 'STUDENT', 'BSIT', '3-1'),
('2024-00540-PQ-1', 'Bandojo', 'Arianne Gracielle', 'Intila', 'ariannegracielleibandojo@iskolarngbayan.pup.edu.ph', 'scrypt:32768:8:1$SxAMcAdVJjq7lrrb$548f1001b620b8420babc1a1b946ed1ca86eeb800099f25b93ca97c7361edd2f966f33b792ff03e844b489a085f9aaded8049b7d5de1f7022f6d25c7b0f8b313', FALSE, FALSE, 'ACTIVE', 'STUDENT', 'BSIT', '3-1'),
('2023-00098-PQ-0', 'Bartolay', 'Asshley Shane', 'Ancheta', 'asshleyshaneabartolay@iskolarngbayan.pup.edu.ph', 'scrypt:32768:8:1$LubIESyCblze8UR2$094148c79d2d31ecadcaa66e3abb3c1e81d74a7e46a6b59292eedf55b67f5cabe007756cbbd03725fd721366ae2b9b7b44858c55145828e4810e343017cdfd71', FALSE, FALSE, 'ACTIVE', 'STUDENT', 'BSIT', '3-1'),
('2023-00047-PQ-0', 'Bo', 'Alexsa', 'Salvacion', 'alexsasbo@iskolarngbayan.pup.edu.ph', 'scrypt:32768:8:1$VfOr85et5Ji6ttCs$ffc58e80474c54e97d3f9aeb12254b380292a43050803da079914a3225ef11103f86224e1a7604405df58ff020d6721dbc7c3e19e1697ed48848ad1295278b24', FALSE, FALSE, 'ACTIVE', 'STUDENT', 'BSIT', '3-1'),
('2023-00162-PQ-0', 'Buenaflor', 'Jericka', 'Sta. Ana', 'jerickasbuenaflor@iskolarngbayan.pup.edu.ph', 'scrypt:32768:8:1$k8XR374AdbAy2vhs$9517ed6d45e9bc2813fd2b8b4456b88c42514ba39c57cdce50dd5bc6b978597a1b30a287268c443ae3f459daca7d130693a17d6cf9f35e013de474fc0d38b497', FALSE, FALSE, 'ACTIVE', 'STUDENT', 'BSIT', '3-1'),
('2023-00212-PQ-0', 'Casas', 'Ma. Jillian', 'Langrio', 'majillianlcasas@iskolarngbayan.pup.edu.ph', 'scrypt:32768:8:1$DQl6YulHAyi3mreB$c589ae26be8f8e5cfca4e7246b87a87df745c6335ecc41b6d2148e66dbece998a2ef4280f860fb4cc91f744ee8e9405587c22d4b4d5cf565f88b84b1a0ef2f23', FALSE, FALSE, 'ACTIVE', 'STUDENT', 'BSIT', '3-1'),
('2023-00312-PQ-0', 'Cordis', 'Ricca Jane', 'Delloro', 'riccajanedcordis@iskolarngbayan.pup.edu.ph', 'scrypt:32768:8:1$I0ee62CdBES4xnS1$2866a8c53e78f0c96d4b585791faf1ad6ece0e974eb905e2a53864b73e985d1523056d3b657518b99c47afcfbc76b2d824d95f470d3b8def13e2da31fd02b729', FALSE, FALSE, 'ACTIVE', 'STUDENT', 'BSIT', '3-1'),
('2023-00153-PQ-0', 'Dela Torre', 'Jane Cristal', 'Candido', 'janecristalcdelatorre@iskolarngbayan.pup.edu.ph', 'scrypt:32768:8:1$O2mJXpqh6vGZdYRH$8df881df7a7382007e9dc66c1ae8e2ac7edd86c2685c3bbe2b4d6723d489159770c5136a04bda71f94de932805c1530d52f2dad0148089df3db4a7474fde1380', FALSE, FALSE, 'ACTIVE', 'STUDENT', 'BSIT', '3-1'),
('2024-00525-PQ-1', 'Delovino', 'Jed Allen', 'Grageda', 'jedallengdelovino@iskolarngbayan.pup.edu.ph', 'scrypt:32768:8:1$botG3pVu6rV8lXam$34c28121cadcf0c4c5e1419c85c955484318a0a26f058f10428cee9b20e3eb8aef6e4e58b70a2b5fb765b420d199b36a828b1a8ec95586aceefca6db80ed1417', FALSE, FALSE, 'ACTIVE', 'STUDENT', 'BSIT', '3-1'),
('2023-00294-PQ-0', 'Dera', 'Khristian Paul', 'Quebec', 'khristianpaulqdera@iskolarngbayan.pup.edu.ph', 'scrypt:32768:8:1$20mzEDegJtGMbGk9$27cd4b9c720d3bcfcc92656d5c87c9c6492d28dedf3cdd7080ba37c7a9aad7eddf576b1661ed55d1c1a2c02f5d109ea79860c2973f974115367190673bc97f13', FALSE, FALSE, 'ACTIVE', 'STUDENT', 'BSIT', '3-1'),
('2023-00262-PQ-0', 'Dometita', 'Jose Alfonso', 'Tiongco', 'josealfonsotdometita@iskolarngbayan.pup.edu.ph', 'scrypt:32768:8:1$UsDNMNHtwb85zjuh$41aee670aa5036d94b93564c0e39793f646191ca41cd8e7ef5ab65178dc8ab11b9b1379621a4b9498844e0237fd9642779c190b0e97d982ebe229244163ec378', FALSE, FALSE, 'ACTIVE', 'STUDENT', 'BSIT', '3-1'),
('2023-00081-PQ-0', 'Erlano', 'Carl Joshua', 'Legaspi', 'carljoshualerlano@iskolarngbayan.pup.edu.ph', 'scrypt:32768:8:1$TDsKBVYocbR4OYt1$4d331b95227ad3a8b7cc16c480c43fef738f4ce95f756f3b1e2a65604dc9687c42660f8931d873ede44773ed452442e0997b4616f171e92a18b28fd9d73c3e3a', FALSE, FALSE, 'ACTIVE', 'STUDENT', 'BSIT', '3-1'),
('2023-00186-PQ-0', 'Fenis', 'Shehanna', 'Alvior', 'shehannaafenis@iskolarngbayan.pup.edu.ph', 'scrypt:32768:8:1$vvfAQxigVyBA01sL$38d44d5ea0459ea87921087a2d16de2fe489d49292e1de6b6c64f20bcf688fbdda9835406d58ddf22785ebf559185c5515766b87833b4a341e01c1474505f9e2', FALSE, FALSE, 'ACTIVE', 'STUDENT', 'BSIT', '3-1'),
('2024-00565-PQ-1', 'Fernando', 'Pauleen Joy', 'Angeles', 'pauleenjoyafernando@iskolarngbayan.pup.edu.ph', 'scrypt:32768:8:1$0QbyYruJUgqu7q2E$0e160c4cd550ce863e8145ac550431945262c55f41f0c24c1eb13e5c62d984ebf887671ac52858bf8648d61cc4ec077d133c00b3881ecfff3b574ffdf0766e54', FALSE, FALSE, 'ACTIVE', 'STUDENT', 'BSIT', '3-1'),
('2023-00249-PQ-0', 'Galano', 'John Raexter', 'Tero', 'johnraextertgalano@iskolarngbayan.pup.edu.ph', 'scrypt:32768:8:1$mvNNZkakkQZPSww9$0fe72550b7fc50b1bf43d82040c336fabcacd6d49bc024acf67d5cc32d75dca05c9beebce3efad9520396c323ef6723cb7901e4762e5febf8b360a7ae12ca5d1', FALSE, FALSE, 'ACTIVE', 'STUDENT', 'BSIT', '3-1'),
('2023-00244-PQ-0', 'Galvadores', 'Mark Lorence', 'Jabal', 'marklorencejgalvadores@iskolarngbayan.pup.edu.ph', 'scrypt:32768:8:1$u2HQHfq2JThShrdc$89f297facbf0742dbd6383ea23504cdb7f2379172a0a051f1bfd32c840028f36114afd8a5a3414aca74aa342598a8ec11b3d20422db6958f1731f61fff7503f9', FALSE, FALSE, 'ACTIVE', 'STUDENT', 'BSIT', '3-1'),
('2023-00062-PQ-0', 'Garcia', 'Jhian', '', 'jhiankgarcia@iskolarngbayan.pup.edu.ph', 'scrypt:32768:8:1$Srvy7KaCt6OrzpZM$38079d6f9f14d27c98b3da44045c01ac38316604c51ebebf6c9ef61d7fa6c2add040a21e5cb6c9680de24545e97490034862af36b987fc6aaa0a2ccad171e65a', FALSE, FALSE, 'ACTIVE', 'STUDENT', 'BSIT', '3-1'),
('2024-00546-PQ-1', 'Golbe', 'Amira', '', 'amiraogolbe@iskolarngbayan.pup.edu.ph', 'scrypt:32768:8:1$1ew8Aq83ONDWB0Wb$110f3336baf9c347881c88746f34dba1ef0124c47f975c0237436092ca9d55df9df054b80ae7ef629d528b8270493e8da10d47edd1fabdb51e98e75517d82a06', FALSE, FALSE, 'ACTIVE', 'STUDENT', 'BSIT', '3-1'),
('2023-00075-PQ-0', 'Gonzaga', 'Jah Jah', 'Bajar', 'jahjahbgonzaga@iskolarngbayan.pup.edu.ph', 'scrypt:32768:8:1$zrv43J9uNi7c0gXV$33a3a998adfd4936ca31c9026e02f012de7072cef466688984c1671116fdac8071a03c7da35ddb2582c3a020750ec46738ea8425d2a14d5624ab16a0d042d882', FALSE, FALSE, 'ACTIVE', 'STUDENT', 'BSIT', '3-1'),
('2023-00119-PQ-0', 'Gonzales', 'Ag', 'Burlaza', 'agbugonzales@iskolarngbayan.pup.edu.ph', 'scrypt:32768:8:1$sV5KH5TjVsOu1tCa$27faac4a1a32b658a378e1e6b2d3a4543652be5dfe487606db0706e803b18dba2644a0dedb6f0f591b4f46449a2dd01fcd7be12c75216a54a56d8dbb78d377ab', FALSE, FALSE, 'ACTIVE', 'STUDENT', 'BSIT', '3-1'),
('2023-00006-PQ-0', 'Gualberto', 'Erika Wendy', 'De Guzman', 'erikawendydgualberto@iskolarngbayan.pup.edu.ph', 'scrypt:32768:8:1$aycg5lfOkMbsQ2xU$55a0b3ff3c039688cf23764ecc8de5cfb69c289bf4718c5ec958a524d46c75e3431f20aef4b677dc9b4f79d56a6f4ddd6aa1e46249a3bb3ed660fb1f7770a7b5', FALSE, FALSE, 'ACTIVE', 'STUDENT', 'BSIT', '3-1'),
('2023-00226-PQ-0', 'Imperial', 'Jonerick James', 'Vargas', 'jonerickjamesvimperial@iskolarngbayan.pup.edu.ph', 'scrypt:32768:8:1$1z0SKKrooxbTp7vy$cbac91296e80dc29d00bce39f3405d7c1a80c4ac538a4ba29ced35aa33d878a7e27c988c524babf4b57b9ee1d97f90535be430c783c354405111d4d1be987da0', FALSE, FALSE, 'ACTIVE', 'STUDENT', 'BSIT', '3-1'),
('2024-00547-PQ-1', 'Lagon', 'Cherie Mae', '', 'cheriemaerlagon@iskolarngbayan.pup.edu.ph', 'scrypt:32768:8:1$ar1hwJJ4eTMzruoi$8083550b38142bda661fdfa1a2eab0f912ff35fe0b41ae58f2be4e992691a66c3038ddd2ba64581eba2f073520c5b50c6ce32858316d36ce585bfccdcf184591', FALSE, FALSE, 'ACTIVE', 'STUDENT', 'BSIT', '3-1'),
('2023-00296-PQ-0', 'Loyola', 'Joshua', 'Dapat', 'joshuadloyola@iskolarngbayan.pup.edu.ph', 'scrypt:32768:8:1$XRhnyDr0bbn2ovOQ$2daf55bc41bccbf9eaf832536c34868e71b976d96d893c1c439eb6b37ce1b8c81fe4193bba5912fa2209dd1e7c51844d8ac1790c1ae9e0ee26b1bee71b01bf27', FALSE, FALSE, 'ACTIVE', 'STUDENT', 'BSIT', '3-1'),
('2023-00325-PQ-0', 'Mallari', 'Sharie Mhae', 'Sayas', 'shariemhaesmallari@iskolarngbayan.pup.edu.ph', 'scrypt:32768:8:1$v9umDPAw8VWEdHIr$06bb07455e7716ab10328f4371286965f644854e01fa306ba7f77a2e8dd85f3142ad911f74cbd6854bc6328957bb5e6bf8adeabe16a2fbeba2bab5ca65f3e5ad', FALSE, FALSE, 'ACTIVE', 'STUDENT', 'BSIT', '3-1'),
('2023-00150-PQ-0', 'Malupa', 'John Charles', 'Alferez', 'johncharlesamalupa@iskolarngbayan.pup.edu.ph', 'scrypt:32768:8:1$xqYnavSPqcJ4zx3O$f5ce997511b2bc4544a7a312e6d37e610e3648a6524903bcff9f537a6dec3313806885fe14a34067c17e15cb9440643f95b58d4a4a0489ed0a37cdb961fcc7fd', FALSE, FALSE, 'ACTIVE', 'STUDENT', 'BSIT', '3-1'),
('2023-00003-PQ-0', 'Maningo', 'Stephanie Vianne', 'Mayordomo', 'stephanieviannemmaningo@iskolarngbayan.pup.edu.ph', 'scrypt:32768:8:1$qwHIvKIfGyvS5vpD$db24795ccbb2a1794f2f2c187cbbfbe1a33fc76a246d23daf76973eb4033339088225a825918bb4b38b226c77b705e3b1084e29b2db697ecfb51d3f1f7efb817', FALSE, FALSE, 'ACTIVE', 'STUDENT', 'BSIT', '3-1'),
('2023-00007-PQ-0', 'Masarate', 'Jaira', 'Rapanut', 'jairarmasarate@iskolarngbayan.pup.edu.ph', 'scrypt:32768:8:1$uBIsd1Ky2S0tu2WT$48f7c6e600ec516e682539f952ecae2dbd824b024504cc12efe55999f4831d27152f0623fb5e460bb5b38ec8712ebc110018f807dde92e942851b5d6c237ebd2', FALSE, FALSE, 'ACTIVE', 'STUDENT', 'BSIT', '3-1'),
('2023-00182-PQ-0', 'Melgar', 'Valerine', 'Sebuyo', 'valerinesmelgar@iskolarngbayan.pup.edu.ph', 'scrypt:32768:8:1$JpVONBr7cyQhUnh0$553cdaeac5bb005a8dfd26ee31f2202d1191595d3d90bc01146c226841bc4e2319f59da888a8bfdc95f50c9283c427b870f084759cd0c2e240affd75f84a5ae1', FALSE, FALSE, 'ACTIVE', 'STUDENT', 'BSIT', '3-1'),
('2023-00005-PQ-0', 'Mendoza', 'Akira Marie', 'Peregrino', 'akiramariepmendoza@iskolarngbayan.pup.edu.ph', 'scrypt:32768:8:1$IocezNs1cRmfdsfl$dc4d98ae59cda35bf7947f0f81164091a8704c1b8fa1c63b4ae51c3fa591feee5069bc2120386bde2f614693630e4c090f26faeb19d034475106cdb124da3610', FALSE, FALSE, 'ACTIVE', 'STUDENT', 'BSIT', '3-1'),
('2023-00114-PQ-0', 'Miranda', 'Duz Criztian', 'Ramos', 'duzcriztianrmiranda@iskolarngbayan.pup.edu.ph', 'scrypt:32768:8:1$Ar6AJQV6dCpz8zk3$7f0f88e9d06607cee07cdce5a627d33801374e46f7839edba85d521ca6dd096cc8175b7feee84510160f3ccc0b6c107d3ef399ea8f2a908e5445a546442d899b', FALSE, FALSE, 'ACTIVE', 'STUDENT', 'BSIT', '3-1'),
('2023-00288-PQ-0', 'Morillo', 'John Aaron', 'Galatiera', 'johnaarongmorillo@iskolarngbayan.pup.edu.ph', 'scrypt:32768:8:1$VeFVYXY7wIsKLZq8$727e5cba04915471ed01107a3014278ef146ab3bf92e5558ff9fcee0cd0315486997baa111c12bb1af9b5921ee6da5a7f653c2fa99fe003152b3ab739fa45747', FALSE, FALSE, 'ACTIVE', 'STUDENT', 'BSIT', '3-1'),
('2023-00324-PQ-0', 'Nazarrea', 'Danilene', 'Bencito', 'danilenebnazarrea@iskolarngbayan.pup.edu.ph', 'scrypt:32768:8:1$78aPFHfyeRbBTTWY$8e66ce21244b40f9751fc432e6404862c1044db545ca234de57e9f0f68115cb082cce9b95581eb4ff15c5b2bde5161862ac5a315a9b38c6a96d022367ac60913', FALSE, FALSE, 'ACTIVE', 'STUDENT', 'BSIT', '3-1'),
('2023-00012-PQ-0', 'Neri', 'Mark Joven', 'Demolar', 'markjovendneri@iskolarngbayan.pup.edu.ph', 'scrypt:32768:8:1$iXgtr4jM4gW7tSLs$1d2ff0fd825d9e4a9ebce5d75d09598710d07baf3755826cc575f2dceb54cd8c60e5324d3aa5201b7edf61f9acaacc25d7efdd0b5affc48fc45b0d1e267854b3', FALSE, FALSE, 'ACTIVE', 'STUDENT', 'BSIT', '3-1'),
('2024-00537-PQ-1', 'Nocidal', 'Judel', 'Bas', 'judelbnocidal@iskolarngbayan.pup.edu.ph', 'scrypt:32768:8:1$WVtirHtMyDPPfGUv$57d04ca02340328af3fa9ef601af35e2289cc6702a3b68e4cb43b615d18cd5f17516f1e54f48a17f07f4df686ba61bf685b6378ba0efcc1abe66d662559627c7', FALSE, FALSE, 'ACTIVE', 'STUDENT', 'BSIT', '3-1'),
('2023-00091-PQ-0', 'Obra', 'James Matthew', 'Laudiza', 'jamesmatthewlobra@iskolarngbayan.pup.edu.ph', 'scrypt:32768:8:1$JTIZDtCtsqfNiz3m$92d1183b063b0caca548da2020788b35fe503352f16b137e84e4388ea7dd32db78749b3032d632f3ef848bddcab0779a838de72b422ac40e7e91827914967ec7', FALSE, FALSE, 'ACTIVE', 'STUDENT', 'BSIT', '3-1'),
('2023-00008-PQ-0', 'Pacis', 'Faith', 'Rosales', 'faithrpacis@iskolarngbayan.pup.edu.ph', 'scrypt:32768:8:1$xkCdWm2sQ8P4IRW8$f4c31a314c7d2209ee5d3c92882952149567c4f75dc0c2be7a8bdd05d5d37284a778d8c283cf06bf398556537038e159b6c96e3c951d05358584c992e587e9a1', FALSE, FALSE, 'ACTIVE', 'STUDENT', 'BSIT', '3-1'),
('2023-00276-PQ-0', 'Penserga', 'Aljhon', 'Cantonjos', 'aljhoncpenserga@iskolarngbayan.pup.edu.ph', 'scrypt:32768:8:1$q1ejQazhZEenkUmg$8f6cdcbb8bb252860c768366ab559be1e05f93634730dda47178b675b6724d7f93aff9d27e267554f25a21155bbda6ea296caa5e49531be944ac36e267e834b0', FALSE, FALSE, 'ACTIVE', 'STUDENT', 'BSIT', '3-1'),
('2024-00549-PQ-1', 'Putis', 'Nicko Jhon', 'Tayum', 'nickojhontputis@iskolarngbayan.pup.edu.ph', 'scrypt:32768:8:1$fsvJ5zf4nG1WK19J$dbc4151826008f2dbaca44dd506f4dfea4d8427ea391e87b65c77c7729240f211920dc053ef492b1a00a4d475c09e8452a386c46a1d48c0914a2833b9047c3c7', FALSE, FALSE, 'ACTIVE', 'STUDENT', 'BSIT', '3-1'),
('2023-00247-PQ-0', 'Rarugal', 'Norielle', 'Bunggay', 'noriellebrarugal@iskolarngbayan.pup.edu.ph', 'scrypt:32768:8:1$eEyVWDmfkWMucLm3$9bccb8683719051ac4d4d7d239480fe8b688185b17f3f561f3ca5c4140304f80b22b9fda26abae3045b98574e9cf9fd161150d414532abf660ce25bc6522ac0c', FALSE, FALSE, 'ACTIVE', 'STUDENT', 'BSIT', '3-1'),
('2024-00550-PQ-1', 'Relagio', 'Danica', '', 'danicarrelagio@iskolarngbayan.pup.edu.ph', 'scrypt:32768:8:1$vw28swb3hZYRbXFv$a5f250438ca98c05b4959b40d1e6d23204fb600d495b2ba656fd80e38766f53b0c163e42ee0dec5bac35df914accee978e5b1f27f2c39ef28c78bb9050efeb85', FALSE, FALSE, 'ACTIVE', 'STUDENT', 'BSIT', '3-1'),
('2023-00056-PQ-0', 'Rodil', 'Lester John', 'Marquez', 'lesterjohnmrodil@iskolarngbayan.pup.edu.ph', 'scrypt:32768:8:1$JNRjKVay32YlpDqE$92aae7d195295129f0544264e2759cbf0781966e0294a81ff4b3c018a506d0f404519a5d342acb54b6f4092f36e1e1f0bdd90b880f1b096566ec2ad60ff8f6c5', FALSE, FALSE, 'ACTIVE', 'STUDENT', 'BSIT', '3-1'),
('2023-00001-PQ-0', 'Ronquillo', 'Rommel', 'Romuga', 'rommelrronquillo@iskolarngbayan.pup.edu.ph', 'scrypt:32768:8:1$3GaIx1awEBZnNnqW$a782b93706a592959648aae8b62c834de2fd38e8d9c630904683990b6d2b9212784d36730dc5d2217a8d193b5b37fdebae771e4f707281eec47690854b867441', FALSE, FALSE, 'ACTIVE', 'STUDENT', 'BSIT', '3-1'),
('2023-00070-PQ-0', 'Salazar', 'Ivan', 'Villanueva', 'ivanvsalazar@iskolarngbayan.pup.edu.ph', 'scrypt:32768:8:1$sueYcwWvn6QCml6C$eeb1f6e6e88a1bfc23e14c8ac85423f52063aef666ce3898aed3915e9e6c3ad3cb60c8e2bdc6dece0d6f20e1d8a61a2d335f7698220467ed63b99d7cbf975565', FALSE, FALSE, 'ACTIVE', 'STUDENT', 'BSIT', '3-1'),
('2023-00133-PQ-0', 'Sardon', 'Gillian Allan', 'Sibua', 'gillianallanssardon@iskolarngbayan.pup.edu.ph', 'scrypt:32768:8:1$ph3v94FcTp5FyBD7$cf5d37cb044e8ee412f63d979da8d55e981111c64d3a98c710e2f054ddae5b532652ce89512310b6dbcf1db79904311f6ac5e7972f2cda202424db68a0e15af0', FALSE, FALSE, 'ACTIVE', 'STUDENT', 'BSIT', '3-1'),
('2023-00127-PQ-0', 'Siervo', 'Dyril Justin', 'Amonelo', 'dyriljustinasiervo@iskolarngbayan.pup.edu.ph', 'scrypt:32768:8:1$hzE0Z0jyCrIHqyqw$70ff2be76c9ffdac8768f4b3a956db1425df754b8288398a5dcab7380977d2096f11e070f666b60cf53d57db779a3e200f9e5aed06e8dd340b24bd6dd62a61f1', FALSE, FALSE, 'ACTIVE', 'STUDENT', 'BSIT', '3-1'),
('2023-00136-PQ-0', 'Soriano', 'Trina Mae', 'Alquero', 'trinamaeasoriano@iskolarngbayan.pup.edu.ph', 'scrypt:32768:8:1$QNexAeq3ChNXmNI5$a2caea1bad6777e4e4d3f409a65311ecb47bd352cc0692b78512c5ab5cc2ec566776457816e111b271136abd4c2fa083c9fa609775e38e66a23c054542a14eec', FALSE, FALSE, 'ACTIVE', 'STUDENT', 'BSIT', '3-1'),
('2024-00564-PQ-1', 'Talampas', 'Kyla Tricia', 'Carrillo', 'kylatriciactalampas@iskolarngbayan.pup.edu.ph', 'scrypt:32768:8:1$8rQC6XksY5RyyJ2h$26e5b3184342dd25784017c37634434161635350a122d5ab336adcb89addb0dbedc03efbbcf6a9da1f2e5974bc8a938623990bc79625364658a1add7108fafa5', FALSE, FALSE, 'ACTIVE', 'STUDENT', 'BSIT', '3-1'),
('2023-00004-PQ-0', 'Tamayo', 'Ellise James', 'Bulaong', 'ellisejamesbtamayo@iskolarngbayan.pup.edu.ph', 'scrypt:32768:8:1$czvlzOkFCULIKVbR$c88d43154d3739da783635471442644aea8f7001bc47a7484b42059bad1ced0a5afb36033ba005f4ee0dcc805f59b7e877b74bc011d20e0347ff738e6ffb45a1', FALSE, FALSE, 'ACTIVE', 'STUDENT', 'BSIT', '3-1'),
('2023-00170-PQ-0', 'Taruc', 'Yukalhey', 'Ramos', 'yukalheyrtaruc@iskolarngbayan.pup.edu.ph', 'scrypt:32768:8:1$4IrYKohLZspgEoGn$72104c78ad6e1acbd3fd2b0a5291f025ce55605dcd98fd433326f76d3f2deaeeaa0e2640a6cbdfe687f5ff9fd185848ab18a6722edbaea2c3b9dd9f80f0bedd1', FALSE, FALSE, 'ACTIVE', 'STUDENT', 'BSIT', '3-1'),
('2023-00173-PQ-0', 'Tobias', 'Erick Christian', '', 'erickchristiantobias@iskolarngbayan.pup.edu.ph', 'scrypt:32768:8:1$Xpi7clY8QIgKcDUF$eba31e370eae1c6558d22042ee4b23411db573a326b5fd7a754238fd26e03a3d648af1010bdf659666366b533a386c786f6d736aabb55bd3376836848c91eb73', FALSE, FALSE, 'ACTIVE', 'STUDENT', 'BSIT', '3-1'),
('2023-00109-PQ-0', 'Tuaya', 'Erikka Maey', 'Palomar', 'erikkamaeyptuaya@iskolarngbayan.pup.edu.ph', 'scrypt:32768:8:1$4Kq6m8S8ySxHphWH$6bc8c724c431f49ac198df130d3c2a3d8a7d7be918a2c0a420a2c77bc45f702f80a53eec8a45e9168b1792ee8372d869e91dbcde9add7ddb9686d288d8daf250', FALSE, FALSE, 'ACTIVE', 'STUDENT', 'BSIT', '3-1'),
('2024-00552-PQ-1', 'Valdez', 'Arg', '', 'argbvaldez@iskolarngbayan.pup.edu.ph', 'scrypt:32768:8:1$mOLrWM3PwGXSunq0$777cef5394d9b68514713f77078fc561041faa7fd14ff5c5b6bda3588cc306cc5e7b39c6f2a1568780cd97763fadf79a5714008e853038c21b72b3d7f29702a8', FALSE, FALSE, 'ACTIVE', 'STUDENT', 'BSIT', '3-1'),
('2023-00142-PQ-0', 'Valiente', 'Mary Diane', '', 'marydianevaliente@iskolarngbayan.pup.edu.ph', 'scrypt:32768:8:1$IOtjqiDsgYxBNXto$256df4e66db04502222a19bce938df22df5832055a060f069ee285b38b2446cd5e7f3497eeae1b06098c2741c13f8e5f10447e4a913439acdf04b85af0a0ca18', FALSE, FALSE, 'ACTIVE', 'STUDENT', 'BSIT', '3-1'),
('2023-00298-PQ-0', 'Villarosa', 'Sebastian', 'Guevarra', 'sebastiangvillarosa@iskolarngbayan.pup.edu.ph', 'scrypt:32768:8:1$qGFvH07hkswGmnPV$8a562f3580e832f0c7bcc11ee364c6f4e72667a1c2ee0ac4be53ee63e86be667ce167d53fb33ea07201f62eff2a55c07218d7d855a199b3f626387d4b1d0928b', FALSE, FALSE, 'ACTIVE', 'STUDENT', 'BSIT', '3-1');
