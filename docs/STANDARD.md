# 📘 AAA Database Standard Specification

**Project:** Axis Auto Access (AAA)  
**Version:** 1.2.0  
**Status:** Standard Compliant  
**Effective Date:** 2026-07-03

---

## 1. 🏁 Core Philosophy

1. **Multi-Tenant Ready:** Every table associated with a project must include a `project_id` field to support future expansion across multiple villages, residential communities, or buildings.
2. **Standardized Identity:** `autoID` (INT Identity) must always be used as the primary key.
3. **Consistency:** All tables must contain the 8 common fields to support a standardized Audit Trail system.
4. **Security First:** Passwords must never be stored in plain text. Always use `bcrypt` for password hashing.

---

## 2. 🔠 Naming Conventions

| Object Type | Naming Pattern | Example |
| :--- | :--- | :--- |
| **Table** | `tb_` + `snake_case` | `tb_project`, `tb_user`, `tb_access_log` |
| **Primary Key** | `autoID` | `autoID` (INT Identity 1,1) |
| **Business ID** | `[table_name]_id` | `project_id`, `user_id` |
| **Admin Table Fields** | `admin_` + `field_name` | `admin_id`, `admin_name`, `admin_password`, `admin_level` |
| **Foreign Key** | `[ref_table]_id` | `project_id`, `house_id` |

---

## 3. 🏗️ Common Fields (Main Table Standard)

All main tables (Master Data and Transaction tables) must contain the following standard columns:

| # | Column | Type | Default | Description |
|:- |:------ |:---- |:------- |:---------- |
| 1 | `autoID` | `INT IDENTITY(1,1)` | — | Primary key |
| 2 | `prefix` | `NVARCHAR(3)` | Table-specific | Business prefix (PRJ, HSE, USR, VEH, DEV, ACL, BLK, ADM) |
| 3 | `[table_name]_id` | `NVARCHAR(50)` | — | Unique business identifier |
| 4 | `is_active` | `BIT` | `1` | Soft-delete flag |
| 5 | `is_delete` | `BIT` | `0` | Reserved delete flag |
| 6 | `id_status` | `NVARCHAR(20)` | `'ACTIVE'` | Record status |
| 7 | `update_date` | `DATETIME` | `GETDATE()` | Auto-updated via trigger |
| 8 | `update_by` | `NVARCHAR(50)` | `'System'` | Last modifier |

### Admin Table Exception

The `tb_admin` table extends the standard with security-specific columns:

| Column | Type | Purpose |
|:------ |:---- |:------- |
| `admin_name` | `NVARCHAR(50) NOT NULL UNIQUE` | Login username |
| `admin_password` | `NVARCHAR(255) NOT NULL` | Bcrypt hashed password |

---

## 4. 💾 Data Type Standards

- **Money / Price:** `DECIMAL(18, 4)`
- **Status / Flags:** `BIT` (0 or 1)
- **Description / Remarks:** `NVARCHAR(MAX)`
- **Timestamp:** `DATETIME` (SQL Server standard)
- **Password:** `NVARCHAR(255)` (supports bcrypt hash length of 60 characters)
- **Business ID:** `NVARCHAR(50)` (supports prefix + date + random hex format: `PREFIX-YYYYMMDD-XXXXXX`)
- **Login Name:** `NVARCHAR(50)` (unique, used for authentication)

---

## 5. 🔒 Safety & Constraints

### 5.1 Password Storage

- All passwords must be stored using **bcrypt** hashing (cost factor 10).
- Never store plain-text passwords in any table.
- Admin accounts are created **exclusively via manual SQL** — no API endpoint exists for admin CRUD operations.

### 5.2 Indexing Standard

- **Unique Index / Constraint:** Applied to every Business ID (`*_id`) and every login name (`admin_name`).
- **Composite Index:** Applied to frequently queried fields, e.g. `(project_id, license_plate)`.
- **Nonclustered Index:** Applied to all foreign key columns.

### 5.3 Auto Update Trigger

An `AFTER UPDATE` trigger must exist on every table to automatically update `update_date`:

```sql
CREATE OR ALTER TRIGGER TRIG_AUTO_UPDATE_DATE_{table} ON {table} AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE t SET update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
    FROM {table} t INNER JOIN inserted i ON t.autoID = i.autoID;
END
GO
```

### 5.4 Auto ID Generation Trigger

An `INSTEAD OF INSERT` trigger must exist on every table to automatically generate business IDs:

```sql
CREATE OR ALTER TRIGGER TRIG_AUTO_GENERATE_ID_{table} ON {table} INSTEAD OF INSERT AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @today NVARCHAR(8) = FORMAT(CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATE), 'yyyyMMdd');
    DECLARE @random NVARCHAR(6) = LOWER(SUBSTRING(REPLACE(CONVERT(NVARCHAR(36), NEWID()), '-', ''), 1, 6));

    INSERT INTO {table} (...)
    SELECT '{PREFIX}', '{PREFIX}-' + @today + '-' + @random, ... FROM inserted;
END
GO
```

**Format:** `{PREFIX}-YYYYMMDD-XXXXXX` where `XXXXXX` = 6 random hex characters from `NEWID()`.

**Application integration:** Application code must pass an empty string (`''`) for the ID column. The trigger generates the real value. Use `OUTPUT INSERTED.{table}_id` to capture the generated ID back.

---

## 📝 Change Log

### v1.2.0 (2026-07-03)

- Added `INSTEAD OF INSERT` triggers for auto-generating business IDs on all 8 tables.
- Changed business ID format from `{PREFIX}-YYYYMMDDHHmmss` to `{PREFIX}-YYYYMMDD-XXXXXX` (date + 6 random hex chars from `NEWID()`).
- Application code no longer generates IDs — database triggers handle it exclusively.

### v1.1.0 (2026-06-28)

- Added `tb_admin` table with bcrypt password hashing standard.
- Added `admin_` prefix naming convention for admin-specific fields.
- Added `NVARCHAR(255)` type standard for password columns.
- Added security policy: admin accounts are manual-only, no API CRUD endpoints.
- Added unique constraint requirement on `admin_name` (login username).

### v1.0.0 (Initial Standard, 2026-06-26)

- Established the AAA database standard.
- Introduced the multi-tenant `project_id` structure.
- Defined 8 standard audit columns.
- Established naming conventions and indexing requirements.
