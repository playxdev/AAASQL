# Prompt for AI: Project AAA (Axis Access Auto) – BETA Release Development

## Context

Project AAA, also known as the **SAxis Access Auto System**, is an intelligent residential access management platform designed for gated communities. The system leverages **AI and IoT technologies** to reduce security guard workload, enhance security, and improve resident convenience.

The platform supports multiple authentication methods, including:

* Automatic License Plate Recognition (LPR)
* RFID
* QR Code
* PIN Code
* National ID Card Verification

The BETA Release architecture is designed around a **Multi-Tenant Architecture** and must support **Offline Operation with Edge-to-Cloud Synchronization**.

Please develop the system according to the following requirements for the three core components: **AAASQL**, **AAAAPP**, and **AAAAPI**.

---

# 1. 🗄️ AAASQL (Database Architecture)

The centralized database will use **Microsoft SQL Server hosted in the cloud** to ensure reliability, scalability, and security.

## Multi-Tenant Design

* Every transactional table must include a `project_id` column as a Foreign Key to support multiple residential projects (villages/communities) within a single platform.

## Standard Audit Columns

Every table must contain the following standard columns for audit trail purposes:

1. `autoID`

   * Use `INT IDENTITY(1,1)` for standard tables.
   * Use `BIGINT IDENTITY(1,1)` for high-volume log tables.

2. `[table_name]_id`

   * `NVARCHAR(20)`
   * Unique Business Identifier.

3. `is_active`

   * `BIT`
   * Default: `1`
   * Used for soft deletion.

4. `id_status`

   * `NVARCHAR(20)`
   * Default: `'ACTIVE'`

5. `create_date`

   * `DATETIME`

6. `update_date`

   * `DATETIME`
   * Automatically maintained using database triggers.

7. `created_by`

   * `NVARCHAR(50)`

8. `updated_by`

   * `NVARCHAR(50)`

## Indexing Requirements

* Create a **Unique Index** for every business identifier column (`*_id`).
* Create **Composite Indexes** for frequently queried data, such as:

```sql
(project_id, license_plate)
(project_id, qr_code)
(project_id, rfid_code)
```

---

# 2. 📱 AAAAPP (Mobile Application)

The mobile application is intended for residents and property management staff to manage access permissions.

## Core Features

### Pre-Registration System

Residents must be able to pre-register temporary access permissions for visitors by generating:

* Temporary Access Codes
* PIN Codes
* QR Codes

### Real-Time Access & Notifications

Whenever a visitor enters or exits through the gate using:

* QR Code
* RFID
* License Plate Recognition
* PIN Code

the system must immediately send a push notification to the homeowner's mobile application.

---

# 3. ⚙️ AAAAPI (Edge API & Cloud Synchronization)

The API layer serves as the communication bridge between the **Edge Gateway devices** located at the guard post and the centralized MSSQL Cloud platform.

## Hardware Integration

The API must support communication with:

* RFID Readers
* QR Code Reader Modules
* License Plate Recognition (LPR) Cameras (e.g., Hikvision)
* Barrier Gate Controllers

## Offline Resilience (Edge-to-Cloud Synchronization)

The Edge Gateway device operates as a stand-alone system.

The API must be designed so that Edge devices can periodically request (Pull) approved access data from the cloud, including:

* Authorized License Plates
* Approved QR Codes
* RFID Credentials
* PIN Codes

The retrieved data should be cached locally on the Edge device to ensure uninterrupted operation during internet outages.

## Log Synchronization

If internet connectivity is unavailable:

* The gate system must continue operating normally using locally cached data.
* All access transactions must be stored locally.

Once connectivity is restored, the Edge Gateway must automatically synchronize (Push) all pending transaction logs back to the cloud database.

The synchronized logs may include:

* Vehicle information
* Visitor information
* License plate data
* Captured images
* Timestamp information
* Access result (Granted/Denied)

---

# Task

Based on the requirements above, generate a complete boilerplate architecture including:

1. Database Schema (SQL Scripts)
2. API Structure (Node.js, Go, or equivalent backend framework)
3. Mobile Application Architecture
4. Folder Structure
5. Initial Models, Controllers, and Service Templates
6. Synchronization Workflow between Edge and Cloud
7. Best Practices for scalability, security, and maintainability

The solution should follow clean architecture principles and be production-ready for future expansion.
