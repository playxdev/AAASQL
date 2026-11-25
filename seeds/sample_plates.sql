-- ==========================================================
-- AAA Sample Plates (test village PRJ-000 only)
-- ป้ายทะเบียนตัวอย่างครบทุกรูปแบบของไทย สำหรับทดสอบ ANPR (รันซ้ำได้ แถวที่มีอยู่แล้วไม่ถูกแก้)
--   รย.1-3 แบบเก่า     : กข 1234   (2 ตัวอักษร + 4 ตัวเลข)
--   รย.1-3 ปัจจุบัน     : 1กข 1234  (1 ตัวเลข + 2 ตัวอักษร + 4 ตัวเลข)
--   ป้ายพิเศษ          : รวย 9999  (3 ตัวอักษร + 4 ตัวเลข)
--   จักรยานยนต์ (3 บรรทัด): 1กข / จังหวัด / 1234 -> เก็บ 1กข1234, จังหวัดอยู่คอลัมน์ province
--   รถบรรทุก / รถโดยสาร : 70-1234, 80-1234 (เลข 2 หลัก + ขีด + เลข 4 หลัก)
-- license_plate เก็บแบบ normalizePlate() ของ AAAAPI: ตัดช่องว่างและขีดออก; province เป็นชื่อเต็ม (normalizeProvince)
-- รัน (จาก repo AAAAPI): npx wrangler d1 execute aaa-d1 --remote --file=../AAASQL/seeds/sample_plates.sql
-- ==========================================================

INSERT OR IGNORE INTO tb_house (house_id, project_id, house_number, zone_or_soi)
VALUES ('SAMPLE-HOUSE', 'PRJ-000', '0/0', 'ป้ายตัวอย่าง');

-- ผู้ติดต่อหลักของบ้าน (สิทธิ์เข้าออกเป็นของบ้าน ไม่ใช่ของคน)
INSERT OR IGNORE INTO tb_user (user_id, project_id, house_id, full_name, role)
VALUES ('SAMPLE-USER', 'PRJ-000', 'SAMPLE-HOUSE', 'ป้ายทะเบียนตัวอย่าง', 'OWNER');

INSERT OR IGNORE INTO tb_vehicle (vehicle_id, project_id, house_id, license_plate, province, brand, color)
VALUES
    ('SAMPLE-V-OLD',     'PRJ-000', 'SAMPLE-HOUSE', 'กข1234',  'กรุงเทพมหานคร', 'TOYOTA', 'WHITE'),
    ('SAMPLE-V-CURRENT', 'PRJ-000', 'SAMPLE-HOUSE', '1กข1234', 'กรุงเทพมหานคร', 'HONDA',  'BLACK'),
    -- ป้ายเดียวกันต่างจังหวัด = คนละคัน: ANPR ต้องได้จังหวัดจากกล้องถึงจะแยกได้ (ไม่งั้น PLATE_AMBIGUOUS)
    ('SAMPLE-V-CURRENT-CM', 'PRJ-000', 'SAMPLE-HOUSE', '1กข1234', 'เชียงใหม่', 'MAZDA', 'GRAY'),
    ('SAMPLE-V-SPECIAL', 'PRJ-000', 'SAMPLE-HOUSE', 'รวย9999', 'ชลบุรี',         'BENZ',   'SILVER'),
    ('SAMPLE-V-MOTO',    'PRJ-000', 'SAMPLE-HOUSE', '2กค5678', 'เชียงใหม่',      'YAMAHA', 'RED'),
    ('SAMPLE-V-TRUCK',   'PRJ-000', 'SAMPLE-HOUSE', '701234',  'ระยอง',         'ISUZU',  'BLUE'),
    ('SAMPLE-V-BUS',     'PRJ-000', 'SAMPLE-HOUSE', '801234',  'นครราชสีมา',    'HINO',   'YELLOW');
