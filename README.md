# AAASQL — Axis Auto Access Data Layer

Schema, migrations และ seed ของ AAA บน **Cloudflare D1** (+ R2 สำหรับภาพ: ออกแบบแล้ว ยังไม่ได้ทำ)

| ส่วน | ค่า |
|---|---|
| D1 database | `aaa-d1` (`256177bc-1cb6-449f-b5c6-f5cac2f2b046`), region APAC (เปลี่ยนชื่อจาก `db1-aaa` 2026-11-25, ตัวเก่าลบแล้ว) |
| บัญชี Cloudflare | `30ec5dca725dd7acef6a6ef89342e403` |
| ผู้ใช้ | Worker `aaa-api` ใน repo [AAAAPI](https://github.com/playxdev/AAAAPI) (binding `DB`) |

ภาพรวมระบบและ tech stack อยู่ที่ repo **AAACLOUDF** (`SYSTEM/aaa-system-architecture.md`)

## โครงสร้าง

```
migrations/0001_init.sql           schema ตั้งต้น (v1.1.0)
migrations/0002_visitor_owner.sql  Visitor งานส่วนกลาง, house_code, ผูก LINE, tb_audit_log
migrations/0003_access_log_house_number.sql  tb_access_log.house_number (บ้านเลขที่ที่ตอบ SEMA)
migrations/0004_house_owned_access.sql  รถ / credential เป็นของบ้าน (house_id), occupancy_status, role ของผู้ติดต่อ
migrations/0005_project_code.sql   tb_project.project_code (AAAA-AA11, login Admin), admin_name ห้ามซ้ำต่อโครงการ
migrations/0006_roles_refs_labels.sql  ROOT / ADMIN, เจ้าบ้าน 1 คนต่อบ้าน, ref, label, ผู้สร้าง credential, โครงการ PLAY-0013
migrations/0007_admin_password_change.sql  tb_admin.must_change_password (บังคับเปลี่ยนรหัสหลัง Root สร้าง / รีเซ็ต)
migrations/0008_visitor_province.sql  รถผู้มาติดต่อ (province / brand / color), tb_project.common_area_code (ค่าเริ่มต้น 0000)
seeds/default_policy.sql           policy ตั้งต้นของทุกโครงการ (รันซ้ำได้)
seeds/sample_plates.sql            ป้ายทะเบียนตัวอย่างทุกรูปแบบใน PRJ-000 (ทดสอบ ANPR, รันซ้ำได้)
docs/STANDARD.md                   มาตรฐานการออกแบบตาราง / การเก็บ secret
```

## Migrations

`AAAAPI/wrangler.jsonc` ชี้ `migrations_dir` มาที่ `../AAASQL/migrations` ต้อง clone ทั้งสอง repo ไว้ข้างกัน:

```
aaa/v1/
├── AAAAPI/
└── AAASQL/
```

```sh
cd ../AAAAPI
npx wrangler d1 migrations create aaa-d1 <name>        # สร้างไฟล์ใหม่ใน AAASQL/migrations
npx wrangler d1 migrations apply aaa-d1 --local        # ทดสอบ local
npx wrangler d1 migrations apply aaa-d1 --remote       # production
```

wrangler 4.156.0: `d1 migrations ...` ไม่อ่าน `account_id` จาก `wrangler.jsonc` ถ้าขึ้น `More than one account available`
ให้ `export CLOUDFLARE_ACCOUNT_ID=30ec5dca725dd7acef6a6ef89342e403` ก่อน

ห้ามแก้ไฟล์ migration ที่ apply ขึ้น remote แล้ว ให้สร้างไฟล์ใหม่เสมอ ห้ามลบตาราง `d1_migrations` (wrangler ใช้จำว่า apply อะไรไปแล้ว)

## Seed

หลังเพิ่มโครงการใหม่ใน `tb_project` (ต้องมี `project_code`, ดู AAAAPI README "สร้างโครงการ + Admin คนแรก") ต้องรัน (ไม่มี policy = ปฏิเสธทุกคน):

```sh
cd ../AAAAPI
npx wrangler d1 execute aaa-d1 --remote --file=../AAASQL/seeds/default_policy.sql
```

| กลุ่ม | วิธีเข้า |
|---|---|
| `RESIDENT` | ANPR / RFID / QRCODE / PIN |
| `RESIDENT_OVERDUE` | RFID / PIN |
| `RESIDENT_OVERDUE_SEVERE` | PIN |
| `VISITOR` | QRCODE / PIN (Guest Code) |

## ตาราง

| Table | เก็บอะไร |
|---|---|
| `tb_project` | โครงการ (หมู่บ้าน / คอนโด / อาคาร / สถานที่) + `project_code` (`AAAA-AA11` เช่น `PROJ-0001` ใช้ login Admin, ห้ามซ้ำ) + `policy_version` |
| `tb_house` | บ้าน + `house_code` + `payment_status` (NORMAL / OVERDUE / OVERDUE_SEVERE) + `occupancy_status` (OCCUPIED / VACANT) |
| `tb_user` | คนในบ้าน `role` = OWNER (เจ้าบ้าน, 1 คนต่อบ้าน) / FAMILY / RESIDENT / TENANT + `ref` (เช่น `PROJ-0001-9806-01`, ห้ามซ้ำ) + `line_user_id` (LINE Mini App) |
| `tb_admin` | ผู้ดูแล `admin_level` = ROOT (PlayDevX, ทุกโครงการ) / ADMIN (1 โครงการ) + `ref` (เช่น `PROJ-0001-A01`); `admin_name` ห้ามซ้ำเฉพาะในโครงการ |
| `tb_vehicle` | รถของบ้าน (`house_id`) ทะเบียนเก็บแบบไม่มีช่องว่าง / ขีด + จังหวัดชื่อเต็ม + `label` |
| `tb_device` | อุปกรณ์ SEMA + `device_secret_hash` |
| `tb_access_log` | ทุกการตัดสินสิทธิ์ที่ไม้กั้น (`log_id` = `event_id`) |
| `tb_blacklist` | ทะเบียนต้องห้าม |
| `tb_visitor` | ผู้เยี่ยมชม (`house_id` NULL = งานส่วนกลาง) + รถ (ทะเบียน / จังหวัด / ยี่ห้อ / สี) |
| `tb_credential` | RFID / QRCODE / PIN ของบ้าน (`house_id`) หรือ GUEST ของ Visitor (`visitor_id`) เก็บเป็น HMAC เท่านั้น + `label` + ผู้สร้าง (`issued_by_type` / `issued_by_id`) |
| `tb_policy` | กลุ่ม × วิธีเข้า (ไม่มีแถว = ไม่อนุญาต) |
| `tb_audit_log` | การกระทำของ Admin / ผู้ติดต่อ (LINE) |

## R2 (ออกแบบแล้ว ยังไม่ได้ทำ)

ออกแบบเต็มอยู่ที่ AAACLOUDF `SYSTEM/aaa-system-architecture.md` §8.6

| ส่วน | ค่า |
|---|---|
| Bucket | `aaa-images` (private, APAC) binding `IMAGES` ใน `aaa-api` |
| Key | `<project_id>/<YYYY-MM-DD>/<event_id>.jpg` เก็บใน `tb_access_log.image_url` ห้ามเก็บภาพใน D1 |
| อัปโหลด | SEMA → `PUT /api/v1/access/events/:event_id/image` (Device JWT, JPEG ≤ 2 MB) |
| Retention | 90 วัน (R2 Lifecycle Rule) |
| ผู้ดู | Admin ของโครงการ + ผู้ติดต่อของบ้านเฉพาะ log ของบ้านตัวเอง |

ต้องเพิ่ม migration: `tb_access_log.house_id` (NULL ได้) + `IX_tb_access_log_house_date (house_id, timestamp)`
