-- ==========================================================
-- AAA Migration 0005 : รหัสโครงการสำหรับ login Admin
--   รูปแบบ AAAA-AA11: ชื่อย่อโครงการ A–Z 4 ตัว + สาขา / ลำดับ A–Z 0–9 4 ตัว เช่น PROJ-0001
--   Admin login ด้วย project_code + admin_name + password
--   admin_name ห้ามซ้ำเฉพาะในโครงการเดียวกัน (เดิมห้ามซ้ำทั้งระบบ)
-- ==========================================================

PRAGMA defer_foreign_keys = true;

/* 1. tb_project.project_code (เก็บแบบตัวใหญ่ + ขีด เช่น PROJ-0001; project_id ภายในไม่เปลี่ยน) */

ALTER TABLE tb_project ADD COLUMN project_code TEXT;
UPDATE tb_project SET project_code = 'PROJ-0001' WHERE project_id = 'PRJ-000';
CREATE UNIQUE INDEX UX_tb_project_code ON tb_project(project_code);

/* 2. tb_admin: UNIQUE(admin_name) -> UNIQUE(project_id, admin_name) (SQLite ลบ UNIQUE ในตารางไม่ได้ ต้องสร้างใหม่) */

CREATE TABLE tb_admin_new (
    autoID INTEGER PRIMARY KEY AUTOINCREMENT,
    admin_id TEXT UNIQUE NOT NULL,
    project_id TEXT NOT NULL,
    admin_name TEXT NOT NULL,
    -- PBKDF2-SHA256: pbkdf2_sha256$<iterations>$<salt hex>$<hash hex> (สร้างด้วย scripts/hash-password.mjs)
    admin_password TEXT NOT NULL,
    admin_level TEXT DEFAULT 'ADMIN',
    is_active INTEGER DEFAULT 1,
    id_status TEXT DEFAULT 'ACTIVE',
    create_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    update_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (project_id, admin_name),
    FOREIGN KEY (project_id) REFERENCES tb_project(project_id)
);

INSERT INTO tb_admin_new (autoID, admin_id, project_id, admin_name, admin_password, admin_level,
    is_active, id_status, create_date, update_date)
SELECT autoID, admin_id, project_id, admin_name, admin_password, admin_level,
    is_active, id_status, create_date, update_date
FROM tb_admin;

DROP TABLE tb_admin;
ALTER TABLE tb_admin_new RENAME TO tb_admin;

CREATE INDEX IX_tb_admin_project_id ON tb_admin(project_id);

CREATE TRIGGER TRIG_AUTO_UPDATE_DATE_tb_admin AFTER UPDATE ON tb_admin
FOR EACH ROW BEGIN UPDATE tb_admin SET update_date = CURRENT_TIMESTAMP WHERE autoID = OLD.autoID; END;

PRAGMA defer_foreign_keys = false;
