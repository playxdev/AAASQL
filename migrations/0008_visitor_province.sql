-- ==========================================================
-- AAA Migration 0008 : รถของผู้มาติดต่อ (จังหวัด / ยี่ห้อ / สี) + รหัสพื้นที่ส่วนกลางของโครงการ
--   ฟอร์มผู้มาติดต่อกรอกรถแบบเดียวกับรถของบ้าน (หมวด + เลข + จังหวัด + ยี่ห้อ + สี)
--   ใช้แสดงผล; ANPR ของผู้มาติดต่อยังเทียบด้วยทะเบียนอย่างเดียว
-- ==========================================================

ALTER TABLE tb_visitor ADD COLUMN province TEXT;
ALTER TABLE tb_visitor ADD COLUMN brand TEXT;
ALTER TABLE tb_visitor ADD COLUMN color TEXT;

-- รหัสนำหน้า Guest Code ของงานส่วนกลาง (ไม่มีบ้าน) ตั้งได้ต่อโครงการ ค่าเริ่มต้น 0000 เช่น 0000+1234
-- ต้องขึ้นต้นด้วย 0 จึงไม่ชนกับ house_code (ห้ามขึ้นต้นด้วย 0)
ALTER TABLE tb_project ADD COLUMN common_area_code TEXT DEFAULT '0000';
