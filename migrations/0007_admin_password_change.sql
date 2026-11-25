-- ==========================================================
-- AAA Migration 0007 : บังคับเปลี่ยนรหัสผ่าน Admin
--   must_change_password = 1 หลัง Root สร้าง / รีเซ็ตรหัสผ่านให้ (รหัสที่ Root ส่งต่อมา)
--   login แล้วต้องตั้งรหัสใหม่ก่อน ถึงจะใช้ Admin API อื่นได้
-- ==========================================================

ALTER TABLE tb_admin ADD COLUMN must_change_password INTEGER DEFAULT 0;
