# AAASQL — Axis Access Auto Database

Microsoft SQL Server schema for the Project AAA intelligent residential access management platform.

## Overview

The database supports multi-tenant gated community operations with 8 core tables:

| Table            | Prefix | Key          | Purpose                        |
|----------------- |------- |------------- |------------------------------- |
| `tb_project`     | PRJ    | INT          | Residential projects/communities |
| `tb_house`       | HSE    | INT          | Houses within a project         |
| `tb_user`        | USR    | INT          | Residents and staff             |
| `tb_vehicle`     | VEH    | INT          | Registered vehicles             |
| `tb_device`      | DEV    | INT          | Gate devices (cameras, readers) |
| `tb_access_log`  | ACL    | **BIGINT**   | High-volume access transaction log |
| `tb_blacklist`   | BLK    | INT          | Blacklisted license plates      |
| `tb_admin`       | ADM    | INT          | System administrators           |

## Quick Setup

```sql
-- Run the full schema script against your SQL Server instance
sqlcmd -S <server> -U <user> -P <password> -i AAASQL/docs/AAA.sql
```

The script creates the `AAA` database (Thai_CI_AS collation), all 8 tables, indexes, and auto-update triggers.

## Schema Standards

See [`docs/STANDARD.md`](docs/STANDARD.md) for the full naming and design standard.

### Every table includes:

- `autoID` — `INT IDENTITY(1,1)` primary key (`BIGINT` for `tb_access_log`)
- `[table]_id` — `NVARCHAR(50)` unique business identifier
- `prefix` — `NVARCHAR(3)` auto-generated prefix (PRJ/HSE/USR/VEH/DEV/ACL/BLK)
- `is_active` — `BIT` (1=active, 0=soft-deleted)
- `is_delete` — `BIT` (0=normal, reserved)
- `id_status` — `NVARCHAR(20)` status flag
- `project_id` — Foreign key to `tb_project` (multi-tenancy)
- `update_date` — `DATETIME` auto-updated via trigger
- `update_by` — `NVARCHAR(50)` audit field

### Indexing

- Unique index on every `[table]_id` column
- Composite indexes for frequent query patterns:
  - `(project_id, license_plate)` on `tb_vehicle` and `tb_blacklist`
  - `(project_id)` on all child tables
  - `(access_date)` on `tb_access_log`

### Triggers

All 8 tables have `AFTER UPDATE` triggers that auto-set `update_date` to the current time in the SE Asia timezone.

## Files

| File              | Purpose                          |
|------------------ |--------------------------------- |
| `docs/AAA.sql`    | Full DDL script (v1.2.0)        |
| `docs/CONCEPT.md` | Project requirements & architecture |
| `docs/STANDARD.md`| Database naming & design standard |

## Optional: Create a New Admin User

This section describes how to create a new administrator account using `bcrypt` password hashing.

### 1. Install `htpasswd`

Install the Apache utilities package which provides the `htpasswd` command.

```bash
sudo apt update
sudo apt install apache2-utils -y
```

---

### 2. Generate a `bcrypt` Password Hash

Use the following command to generate a secure `bcrypt` hash for the admin password.

```bash
htpasswd -nbBC 10 admin password
```

Example output:

```text
admin:$2y$10$KfQ8mU5VvJ5QGk7/LN9OeOujOPEwLjD3Oo4yEWDwEpr6/LkfuPWoK
```

---

### 3. Insert the Admin User into the Database

Reset existing admin records (optional) and create a new administrator account.

```sql
DELETE FROM tb_admin;
DBCC CHECKIDENT ('tb_admin', RESEED, 0);

INSERT INTO tb_admin
(
    admin_id,
    project_id,
    admin_name,
    admin_password,
    admin_level,
    update_by,
    id_status
)
VALUES
(
    'ADM00001',
    'PRJ00001',
    'admin',
    '$2y$10$KfQ8mU5VvJ5QGk7/LN9OeOujOPEwLjD3Oo4yEWDwEpr6/LkfuPWoK',
    'ADMIN',
    'System',
    'ACTIVE'
);
```

> **Note**
>
> * Replace `PRJ00001` with the appropriate project ID.
> * Replace `admin` and `password` with your desired username and password.
> * Always use `bcrypt` for password storage. Never store plain text passwords in the database.
