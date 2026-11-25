-- ==========================================================
-- AAA Migration 0006 : Root / Admin / คนในบ้าน, รหัสอ้างอิง, ชื่อสั้นของรายการ
--   tb_admin.admin_level: ROOT (PlayDevX, ทุกโครงการ) / ADMIN (ประจำโครงการ)
--   tb_user.role: OWNER (เจ้าบ้าน, 1 คนต่อบ้าน) / FAMILY (ลูกบ้าน) / RESIDENT (ผู้พักอาศัย) / TENANT (ผู้เช่า)
--   ref = รหัสอ้างอิงที่คนอ่านได้ ห้ามซ้ำทั้งระบบ (ID ภายในยังเป็น UUID เหมือนเดิม)
--     คนในบ้าน: <project_code>-<house_code>-NN เช่น PROJ-0001-9806-01
--     ผู้ดูแล:   <project_code>-ANN / -RNN   เช่น PROJ-0001-A01, PLAY-0013-R01
--   label = ชื่อสั้นของรถ / บัตร / PIN / QR เช่น "บัตรแม่", "pin ส่งของ"
--   tb_credential.issued_by_type / issued_by_id = ใครสร้าง (ADMIN / OWNER = คนในบ้าน) ใช้กำหนดสิทธิ์ลบ
-- ==========================================================

/* 1. เจ้าบ้าน 1 คนต่อบ้าน: เจ้าบ้านที่เกิน (ถ้ามี) ลดเป็นผู้พักอาศัย แล้วกันซ้ำด้วย partial unique index */

UPDATE tb_user SET role = 'RESIDENT'
WHERE role = 'OWNER' AND autoID NOT IN (
    SELECT MIN(autoID) FROM tb_user WHERE role = 'OWNER' AND is_active = 1 AND house_id IS NOT NULL GROUP BY house_id
);
CREATE UNIQUE INDEX UX_tb_user_house_owner ON tb_user(house_id) WHERE role = 'OWNER' AND is_active = 1;

/* 2. รหัสอ้างอิง (ref) */

ALTER TABLE tb_user ADD COLUMN ref TEXT;
ALTER TABLE tb_admin ADD COLUMN ref TEXT;

WITH r AS (
    SELECT u.user_id,
           p.project_code || '-' || COALESCE(h.house_code, 'H' || h.autoID) || '-' ||
           printf('%02d', ROW_NUMBER() OVER (PARTITION BY u.house_id ORDER BY CASE u.role WHEN 'OWNER' THEN 0 ELSE 1 END, u.autoID)) AS ref
    FROM tb_user u
    JOIN tb_house h ON h.house_id = u.house_id
    JOIN tb_project p ON p.project_id = u.project_id
    WHERE p.project_code IS NOT NULL
)
UPDATE tb_user SET ref = (SELECT r.ref FROM r WHERE r.user_id = tb_user.user_id);

WITH r AS (
    SELECT a.admin_id,
           p.project_code || '-' || CASE a.admin_level WHEN 'ROOT' THEN 'R' ELSE 'A' END ||
           printf('%02d', ROW_NUMBER() OVER (PARTITION BY a.project_id, a.admin_level = 'ROOT' ORDER BY a.autoID)) AS ref
    FROM tb_admin a JOIN tb_project p ON p.project_id = a.project_id
    WHERE p.project_code IS NOT NULL
)
UPDATE tb_admin SET ref = (SELECT r.ref FROM r WHERE r.admin_id = tb_admin.admin_id);

CREATE UNIQUE INDEX UX_tb_user_ref ON tb_user(ref);
CREATE UNIQUE INDEX UX_tb_admin_ref ON tb_admin(ref);

/* 3. ชื่อสั้น + ผู้สร้าง credential */

ALTER TABLE tb_vehicle ADD COLUMN label TEXT;
ALTER TABLE tb_credential ADD COLUMN label TEXT;
ALTER TABLE tb_credential ADD COLUMN issued_by_type TEXT;
ALTER TABLE tb_credential ADD COLUMN issued_by_id TEXT;
CREATE INDEX IX_tb_credential_house_type ON tb_credential(house_id, cred_type);

/* 4. โครงการของ PlayDevX (Root) — บัญชี root ใส่ด้วย SQL แยก (มีรหัสผ่าน) ดู AAAAPI README */

INSERT OR IGNORE INTO tb_project (project_id, project_name, project_code) VALUES ('PRJ-PLAY', 'PlayDevX', 'PLAY-0013');
