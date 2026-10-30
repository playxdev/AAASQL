# AAASQL — Axis Auto Access Data Layer

Schema, migrations และ seed ของ AAA บน **Cloudflare D1** (+ R2 สำหรับภาพ: ออกแบบแล้ว ยังไม่ได้ทำ)

| ส่วน | ค่า |
|---|---|
| D1 database | `db1-aaa` (`e69cbde0-e4b3-4986-804c-ffab15a153a7`), region APAC |
| บัญชี Cloudflare | `30ec5dca725dd7acef6a6ef89342e403` |
| ผู้ใช้ | Worker `aaa-api` ใน repo [AAAAPI](https://github.com/playxdev/AAAAPI) (binding `DB`) |

ภาพรวมระบบและ tech stack อยู่ที่ repo **AAACLOUDF** (`SYSTEM/aaa-system-architecture.md`)

## โครงสร้าง

```
migrations/0001_init.sql           schema ตั้งต้น (v1.1.0)
migrations/0002_visitor_owner.sql  Visitor งานส่วนกลาง, house_code, ผูก LINE, tb_audit_log
seeds/default_policy.sql           policy ตั้งต้นของทุกโครงการ (รันซ้ำได้)
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
npx wrangler d1 migrations create db1-aaa <name>        # สร้างไฟล์ใหม่ใน AAASQL/migrations
npx wrangler d1 migrations apply db1-aaa --local        # ทดสอบ local
npx wrangler d1 migrations apply db1-aaa --remote       # production
```

wrangler 4.156.0: `d1 migrations ...` ไม่อ่าน `account_id` จาก `wrangler.jsonc` ถ้าขึ้น `More than one account available`
ให้ `export CLOUDFLARE_ACCOUNT_ID=30ec5dca725dd7acef6a6ef89342e403` ก่อน

ห้ามแก้ไฟล์ migration ที่ apply ขึ้น remote แล้ว ให้สร้างไฟล์ใหม่เสมอ ห้ามลบตาราง `d1_migrations` (wrangler ใช้จำว่า apply อะไรไปแล้ว)

## Seed

หลังเพิ่มโครงการใหม่ใน `tb_project` ต้องรัน (ไม่มี policy = ปฏิเสธทุกคน):

```sh
cd ../AAAAPI
npx wrangler d1 execute db1-aaa --remote --file=../AAASQL/seeds/default_policy.sql
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
| `tb_project` | โครงการ / หมู่บ้าน + `policy_version` |
| `tb_house` | บ้าน + `house_code` + `payment_status` (NORMAL / OVERDUE / OVERDUE_SEVERE) |
| `tb_user` | ลูกบ้าน + `line_user_id` (LIFF) |
| `tb_admin` | ผู้ดูแล (1 คน = 1 โครงการ) |
| `tb_vehicle` | รถของลูกบ้าน |
| `tb_device` | อุปกรณ์ SEMA + `device_secret_hash` |
| `tb_access_log` | ทุกการตัดสินสิทธิ์ที่ไม้กั้น (`log_id` = `event_id`) |
| `tb_blacklist` | ทะเบียนต้องห้าม |
| `tb_visitor` | ผู้เยี่ยมชม (`house_id` NULL = งานส่วนกลาง) |
| `tb_credential` | RFID / QRCODE / PIN / GUEST (เก็บเป็น HMAC เท่านั้น) |
| `tb_policy` | กลุ่ม × วิธีเข้า (ไม่มีแถว = ไม่อนุญาต) |
| `tb_audit_log` | การกระทำของ Admin / ลูกบ้าน |

## R2 (ออกแบบแล้ว ยังไม่ได้ทำ)

ออกแบบเต็มอยู่ที่ AAACLOUDF `SYSTEM/aaa-system-architecture.md` §8.6

| ส่วน | ค่า |
|---|---|
| Bucket | `aaa-images` (private, APAC) binding `IMAGES` ใน `aaa-api` |
| Key | `<project_id>/<YYYY-MM-DD>/<event_id>.jpg` เก็บใน `tb_access_log.image_url` ห้ามเก็บภาพใน D1 |
| อัปโหลด | SEMA → `PUT /api/v1/access/events/:event_id/image` (Device JWT, JPEG ≤ 2 MB) |
| Retention | 90 วัน (R2 Lifecycle Rule) |
| ผู้ดู | Admin ของโครงการ + ลูกบ้านเฉพาะ log ของบ้านตัวเอง |

ต้องเพิ่ม migration: `tb_access_log.house_id` (NULL ได้) + `IX_tb_access_log_house_date (house_id, timestamp)`
