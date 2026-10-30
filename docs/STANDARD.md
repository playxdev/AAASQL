# 📘 AAA Database Standard Specification

**Project:** Axis Auto Access (AAA)
**Version:** 2.1.0
**Engine:** Cloudflare D1 (SQLite)
**Effective Date:** 2026-10-30

---

## 1. 🏁 Core Philosophy

1. **Multi-Tenant Ready:** ทุกตารางที่เกี่ยวกับโครงการต้องมี `project_id` และทุก query ของ API ต้องกรองด้วย `project_id` ที่มาจาก token
2. **Standardized Identity:** `autoID INTEGER PRIMARY KEY AUTOINCREMENT` เป็น primary key เสมอ
3. **Consistency:** ทุกตารางหลักมี common fields ตามข้อ 3 เพื่อ audit trail
4. **Security First:** ห้ามเก็บรหัสผ่าน / PIN / RFID / QR / secret แบบ plaintext (ดูข้อ 5.1)
5. **Migrations Only:** แก้ schema ผ่านไฟล์ใน `migrations/` เท่านั้น ห้ามแก้ไฟล์ที่ apply ขึ้น remote แล้ว

---

## 2. 🔠 Naming Conventions

| Object Type | Naming Pattern | Example |
| :--- | :--- | :--- |
| **Table** | `tb_` + `snake_case` | `tb_project`, `tb_user`, `tb_access_log` |
| **Primary Key** | `autoID` | `autoID INTEGER PRIMARY KEY AUTOINCREMENT` |
| **Business ID** | `[table_name]_id` | `project_id`, `user_id` (UUID หรือรหัสที่ admin กำหนด) |
| **Admin Table Fields** | `admin_` + `field_name` | `admin_id`, `admin_name`, `admin_password`, `admin_level` |
| **Foreign Key** | `[ref_table]_id` | `project_id`, `house_id` |
| **Index** | `IX_` / `UX_` (unique) + table + columns | `IX_tb_vehicle_project_license` |
| **Trigger** | `TRIG_AUTO_UPDATE_DATE_` + table | `TRIG_AUTO_UPDATE_DATE_tb_house` |

---

## 3. 🏗️ Common Fields (Main Table Standard)

| # | Column | Type | Default | Description |
|:- |:------ |:---- |:------- |:---------- |
| 1 | `autoID` | `INTEGER PRIMARY KEY AUTOINCREMENT` | — | Primary key |
| 2 | `[table_name]_id` | `TEXT UNIQUE NOT NULL` | — | Business identifier |
| 3 | `is_active` | `INTEGER` | `1` | Soft-delete flag (1 = active, 0 = ปิดใช้งาน) |
| 4 | `id_status` | `TEXT` | `'ACTIVE'` | Record status เช่น `ACTIVE`, `REVOKED` |
| 5 | `create_date` | `DATETIME` | `CURRENT_TIMESTAMP` | เวลาสร้าง (UTC) |
| 6 | `update_date` | `DATETIME` | `CURRENT_TIMESTAMP` | อัปเดตอัตโนมัติด้วย trigger (UTC) |

ตาราง log (`tb_access_log`, `tb_audit_log`) เป็น append-only ไม่มี `update_date` และไม่มี trigger

---

## 4. 💾 Data Type Standards

- **Status / Flags:** `INTEGER` (0 / 1)
- **Text / ID / Description:** `TEXT`
- **Timestamp:** `DATETIME` เก็บเป็น UTC รูปแบบ `YYYY-MM-DD HH:MM:SS` (เหมือน `CURRENT_TIMESTAMP`)
- **Money / Price:** เก็บเป็น `INTEGER` หน่วยสตางค์ (SQLite ไม่มี DECIMAL)
- **ทะเบียนรถ:** ตัดช่องว่างและ `-` ก่อนเก็บ (เช่น `กก9999`)
- **ภาพ / ไฟล์:** เก็บใน R2 เท่านั้น ใน D1 เก็บแค่ key (เช่น `tb_access_log.image_url` = `<project_id>/<YYYY-MM-DD>/<event_id>.jpg`)

---

## 5. 🔒 Safety & Constraints

### 5.1 Secret Storage

| ข้อมูล | วิธีเก็บ |
|---|---|
| รหัสผ่าน Admin | PBKDF2-SHA256 100,000 รอบ: `pbkdf2_sha256$<iterations>$<salt hex>$<hash hex>` |
| RFID / QR / PIN / Guest Code | HMAC-SHA256(`CRED_PEPPER`, `project_id:cred_type:value`) |
| Device secret | SHA-256 hex |
| รหัสผูก LINE | SHA-256 hex, ใช้ครั้งเดียว, หมดอายุ 24 ชม. |

- Admin คนแรกสร้างด้วย SQL + `scripts/hash-password.mjs` (repo AAAAPI)
- ห้ามบันทึกค่าลับลง `tb_access_log` / `tb_audit_log`

### 5.2 Indexing Standard

- **Unique:** ทุก Business ID (`*_id`), `admin_name`, `(project_id, house_code)`, `(project_id, cred_type, cred_hash)`, `line_user_id`
- **Composite:** field ที่ค้นบ่อย เช่น `(project_id, license_plate)`, `(project_id, timestamp)`
- **Foreign Key:** ทุก FK column มี index

### 5.3 Auto Update Trigger

```sql
CREATE TRIGGER TRIG_AUTO_UPDATE_DATE_{table} AFTER UPDATE ON {table}
FOR EACH ROW BEGIN UPDATE {table} SET update_date = CURRENT_TIMESTAMP WHERE autoID = OLD.autoID; END;
```

ผลข้างเคียง: `meta.changes` ของ D1 นับแถวที่ trigger แก้ด้วย โค้ดจึงต้องเช็ค `changes > 0` ไม่ใช่ `=== 1`

---

## 📝 Change Log

### v2.1.0 (2026-10-30)

- เพิ่มมาตรฐานการเก็บภาพ / ไฟล์: R2 เท่านั้น D1 เก็บแค่ key (ข้อ 4)

### v2.0.0 (2026-10-30)

- ย้ายจาก Microsoft SQL Server ไป Cloudflare D1 (SQLite)
- รหัสผ่าน Admin เปลี่ยนจาก bcrypt เป็น PBKDF2-SHA256 (WebCrypto บน Workers)
- เพิ่มมาตรฐานการเก็บ credential / secret (ข้อ 5.1)
- ตัด `prefix`, `is_delete`, `update_by` ออกจาก common fields; เพิ่ม `create_date`
- Admin จัดการผ่าน Admin API ได้แล้ว (ยกเว้นสร้าง admin คนแรก)

### v1.1.0 (2026-06-28) — MS SQL Server (เลิกใช้)

### v1.0.0 (2026-06-26) — MS SQL Server (เลิกใช้)
