-- ==========================================================
-- AAA Migration 0004 : สิทธิ์เข้าออกเป็นของบ้าน (ไม่ใช่ของลูกบ้านรายคน)
--   บ้าน 98/0 มี รถ / RFID / PIN / QR กี่รายการก็ได้ คนในบ้านจัดการกันเอง
--   tb_user = รายชื่อผู้ติดต่อของบ้าน (เจ้าบ้าน / ผู้อยู่อาศัย / ผู้เช่า) + บัญชี LINE
-- ข้อมูลเดิม: ย้ายรถ / credential ของลูกบ้านไปอยู่ใต้บ้านของคนนั้น
--   ลูกบ้านที่ปิดใช้งานอยู่ -> รายการของเขาย้ายไปแบบปิดใช้งาน (ไม่เปิดสิทธิ์คืนโดยไม่ตั้งใจ)
--   ลูกบ้านที่ไม่มีบ้าน -> รายการของเขาถูกทิ้ง (ไม่มีบ้านให้ผูก)
-- ==========================================================

PRAGMA defer_foreign_keys = true;

/* 1. tb_house: สถานะการอยู่อาศัย OCCUPIED / VACANT (ไม่มีผู้อยู่อาศัย = ทุกช่องทางของบ้านใช้ไม่ได้) */

ALTER TABLE tb_house ADD COLUMN occupancy_status TEXT DEFAULT 'OCCUPIED';

/* 2. tb_user.role: OWNER (เจ้าบ้าน) / RESIDENT (ผู้อยู่อาศัย) / TENANT (ผู้เช่า)
   ลูกบ้านคนแรกของแต่ละบ้านเป็นเจ้าบ้าน */

UPDATE tb_user SET role = 'OWNER'
WHERE autoID IN (SELECT MIN(autoID) FROM tb_user WHERE house_id IS NOT NULL GROUP BY house_id);

/* 3. tb_vehicle: user_id -> house_id (SQLite แก้ NOT NULL / FK ไม่ได้ ต้องสร้างตารางใหม่) */

CREATE TABLE tb_vehicle_new (
    autoID INTEGER PRIMARY KEY AUTOINCREMENT,
    vehicle_id TEXT UNIQUE NOT NULL,
    project_id TEXT NOT NULL,
    house_id TEXT NOT NULL,
    license_plate TEXT NOT NULL,
    province TEXT,
    brand TEXT,
    color TEXT,
    is_active INTEGER DEFAULT 1,
    id_status TEXT DEFAULT 'ACTIVE',
    create_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    update_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (project_id) REFERENCES tb_project(project_id),
    FOREIGN KEY (house_id) REFERENCES tb_house(house_id)
);

INSERT INTO tb_vehicle_new (autoID, vehicle_id, project_id, house_id, license_plate, province, brand, color,
    is_active, id_status, create_date, update_date)
SELECT v.autoID, v.vehicle_id, v.project_id, u.house_id, v.license_plate, v.province, v.brand, v.color,
    CASE WHEN u.is_active = 1 THEN v.is_active ELSE 0 END, v.id_status, v.create_date, v.update_date
FROM tb_vehicle v JOIN tb_user u ON u.user_id = v.user_id
WHERE u.house_id IS NOT NULL;

DROP TABLE tb_vehicle;
ALTER TABLE tb_vehicle_new RENAME TO tb_vehicle;

CREATE INDEX IX_tb_vehicle_project_id ON tb_vehicle(project_id);
CREATE INDEX IX_tb_vehicle_house_id ON tb_vehicle(house_id);
CREATE INDEX IX_tb_vehicle_project_license ON tb_vehicle(project_id, license_plate);

CREATE TRIGGER TRIG_AUTO_UPDATE_DATE_tb_vehicle AFTER UPDATE ON tb_vehicle
FOR EACH ROW BEGIN UPDATE tb_vehicle SET update_date = CURRENT_TIMESTAMP WHERE autoID = OLD.autoID; END;

/* 4. tb_credential: เจ้าของเป็น house_id (ลูกบ้าน) หรือ visitor_id (ผู้เยี่ยมชม) อย่างใดอย่างหนึ่ง */

CREATE TABLE tb_credential_new (
    autoID INTEGER PRIMARY KEY AUTOINCREMENT,
    credential_id TEXT UNIQUE NOT NULL,
    project_id TEXT NOT NULL,
    house_id TEXT,
    visitor_id TEXT,
    cred_type TEXT NOT NULL,
    cred_hash TEXT NOT NULL,
    valid_from DATETIME,
    valid_until DATETIME,
    max_uses INTEGER,
    use_count INTEGER DEFAULT 0,
    is_active INTEGER DEFAULT 1,
    id_status TEXT DEFAULT 'ACTIVE',
    create_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    update_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (project_id, cred_type, cred_hash),
    CHECK ((house_id IS NULL) <> (visitor_id IS NULL)),
    FOREIGN KEY (project_id) REFERENCES tb_project(project_id),
    FOREIGN KEY (house_id) REFERENCES tb_house(house_id),
    FOREIGN KEY (visitor_id) REFERENCES tb_visitor(visitor_id)
);

INSERT INTO tb_credential_new (autoID, credential_id, project_id, house_id, visitor_id, cred_type, cred_hash,
    valid_from, valid_until, max_uses, use_count, is_active, id_status, create_date, update_date)
SELECT c.autoID, c.credential_id, c.project_id, u.house_id, c.visitor_id, c.cred_type, c.cred_hash,
    c.valid_from, c.valid_until, c.max_uses, c.use_count,
    CASE WHEN c.user_id IS NULL OR u.is_active = 1 THEN c.is_active ELSE 0 END,
    c.id_status, c.create_date, c.update_date
FROM tb_credential c LEFT JOIN tb_user u ON u.user_id = c.user_id
WHERE c.visitor_id IS NOT NULL OR u.house_id IS NOT NULL;

DROP TABLE tb_credential;
ALTER TABLE tb_credential_new RENAME TO tb_credential;

CREATE INDEX IX_tb_credential_house_id ON tb_credential(house_id);
CREATE INDEX IX_tb_credential_visitor_id ON tb_credential(visitor_id);

CREATE TRIGGER TRIG_AUTO_UPDATE_DATE_tb_credential AFTER UPDATE ON tb_credential
FOR EACH ROW BEGIN UPDATE tb_credential SET update_date = CURRENT_TIMESTAMP WHERE autoID = OLD.autoID; END;

PRAGMA defer_foreign_keys = false;
