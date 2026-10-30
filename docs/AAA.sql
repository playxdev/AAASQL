-- ==========================================================
-- AAA (Axis Auto Access) Database Full Schema
-- Version : 1.2.0
-- Language Support : Thai (Thai_CI_AS)
-- ==========================================================

USE master;
GO

-- 1. สร้าง Database
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'AAA')
BEGIN
    CREATE DATABASE AAA COLLATE Thai_CI_AS;
END
GO

USE AAA;
GO

/* ==========================================================
   2. CREATE TABLES
   ========================================================== */

CREATE TABLE tb_project
(
    autoID             INT IDENTITY(1,1) PRIMARY KEY,
    prefix             NVARCHAR(3)   NOT NULL DEFAULT 'PRJ',
    project_id         NVARCHAR(50)  NOT NULL UNIQUE,
    project_name       NVARCHAR(100) NOT NULL,
    address            NVARCHAR(255),
    contact_number     NVARCHAR(20),
    update_by          NVARCHAR(50)  NOT NULL DEFAULT 'System',
    update_date        DATETIME      NOT NULL DEFAULT CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME),
    is_active          BIT           NOT NULL DEFAULT 1,
    is_delete          BIT           NOT NULL DEFAULT 0,
    id_status          NVARCHAR(20)  NOT NULL DEFAULT 'ACTIVE'
);
GO

CREATE TABLE tb_house
(
    autoID             INT IDENTITY(1,1) PRIMARY KEY,
    prefix             NVARCHAR(3)   NOT NULL DEFAULT 'HSE',
    house_id           NVARCHAR(50)  NOT NULL UNIQUE,
    project_id         NVARCHAR(50)  NOT NULL,
    house_number       NVARCHAR(50)  NOT NULL,
    zone_or_soi        NVARCHAR(100),
    update_by          NVARCHAR(50)  NOT NULL DEFAULT 'System',
    update_date        DATETIME      NOT NULL DEFAULT CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME),
    is_active          BIT           NOT NULL DEFAULT 1,
    is_delete          BIT           NOT NULL DEFAULT 0,
    id_status          NVARCHAR(20)  NOT NULL DEFAULT 'ACTIVE',
    CONSTRAINT FK_tb_house_project_id FOREIGN KEY(project_id) REFERENCES tb_project(project_id)
);
GO

CREATE TABLE tb_user
(
    autoID             INT IDENTITY(1,1) PRIMARY KEY,
    prefix             NVARCHAR(3)   NOT NULL DEFAULT 'USR',
    user_id            NVARCHAR(50)  NOT NULL UNIQUE,
    project_id         NVARCHAR(50)  NOT NULL,
    house_id           NVARCHAR(50),
    full_name          NVARCHAR(150) NOT NULL,
    phone_number       NVARCHAR(20),
    line_id            NVARCHAR(50),
    role               NVARCHAR(20)  NOT NULL DEFAULT 'RESIDENT',
    update_by          NVARCHAR(50)  NOT NULL DEFAULT 'System',
    update_date        DATETIME      NOT NULL DEFAULT CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME),
    is_active          BIT           NOT NULL DEFAULT 1,
    is_delete          BIT           NOT NULL DEFAULT 0,
    id_status          NVARCHAR(20)  NOT NULL DEFAULT 'ACTIVE',
    CONSTRAINT FK_tb_user_project_id FOREIGN KEY(project_id) REFERENCES tb_project(project_id),
    CONSTRAINT FK_tb_user_house_id FOREIGN KEY(house_id) REFERENCES tb_house(house_id)
);
GO

CREATE TABLE tb_vehicle
(
    autoID             INT IDENTITY(1,1) PRIMARY KEY,
    prefix             NVARCHAR(3)  NOT NULL DEFAULT 'VEH',
    vehicle_id         NVARCHAR(50) NOT NULL UNIQUE,
    project_id         NVARCHAR(50) NOT NULL,
    user_id            NVARCHAR(50) NOT NULL,
    license_plate      NVARCHAR(20) NOT NULL,
    province           NVARCHAR(50),
    brand              NVARCHAR(50),
    color              NVARCHAR(30),
    update_by          NVARCHAR(50) NOT NULL DEFAULT 'System',
    update_date        DATETIME     NOT NULL DEFAULT CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME),
    is_active          BIT          NOT NULL DEFAULT 1,
    is_delete          BIT          NOT NULL DEFAULT 0,
    id_status          NVARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    CONSTRAINT FK_tb_vehicle_project_id FOREIGN KEY(project_id) REFERENCES tb_project(project_id),
    CONSTRAINT FK_tb_vehicle_user_id FOREIGN KEY(user_id) REFERENCES tb_user(user_id)
);
GO

CREATE TABLE tb_device
(
    autoID             INT IDENTITY(1,1) PRIMARY KEY,
    prefix             NVARCHAR(3)   NOT NULL DEFAULT 'DEV',
    device_id          NVARCHAR(50)  NOT NULL UNIQUE,
    project_id         NVARCHAR(50)  NOT NULL,
    gate_name          NVARCHAR(100) NOT NULL,
    device_type        NVARCHAR(50),
    ip_address         NVARCHAR(50),
    update_by          NVARCHAR(50)  NOT NULL DEFAULT 'System',
    update_date        DATETIME      NOT NULL DEFAULT CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME),
    is_active          BIT           NOT NULL DEFAULT 1,
    is_delete          BIT           NOT NULL DEFAULT 0,
    id_status          NVARCHAR(20)  NOT NULL DEFAULT 'ACTIVE',
    CONSTRAINT FK_tb_device_project_id FOREIGN KEY(project_id) REFERENCES tb_project(project_id)
);
GO

CREATE TABLE tb_access_log
(
    autoID             BIGINT IDENTITY(1,1) PRIMARY KEY,
    prefix             NVARCHAR(3)  NOT NULL DEFAULT 'ACL',
    log_id             NVARCHAR(50) NOT NULL UNIQUE,
    project_id         NVARCHAR(50) NOT NULL,
    device_id          NVARCHAR(50),
    license_plate      NVARCHAR(20),
    access_type        NVARCHAR(20),
    user_type          NVARCHAR(20),
    access_date        DATETIME     NOT NULL DEFAULT CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME),
    image_url          NVARCHAR(MAX),
    remark             NVARCHAR(MAX),
    is_success         BIT          NOT NULL DEFAULT 1,
    update_by          NVARCHAR(50) NOT NULL DEFAULT 'System',
    update_date        DATETIME     NOT NULL DEFAULT CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME),
    is_active          BIT          NOT NULL DEFAULT 1,
    is_delete          BIT          NOT NULL DEFAULT 0,
    id_status          NVARCHAR(20) NOT NULL DEFAULT 'SUCCESS',
    CONSTRAINT FK_tb_access_log_project_id FOREIGN KEY(project_id) REFERENCES tb_project(project_id),
    CONSTRAINT FK_tb_access_log_device_id FOREIGN KEY(device_id) REFERENCES tb_device(device_id)
);
GO

CREATE TABLE tb_blacklist
(
    autoID             INT IDENTITY(1,1) PRIMARY KEY,
    prefix             NVARCHAR(3)  NOT NULL DEFAULT 'BLK',
    blacklist_id       NVARCHAR(50) NOT NULL UNIQUE,
    project_id         NVARCHAR(50) NOT NULL,
    license_plate      NVARCHAR(20) NOT NULL,
    reason             NVARCHAR(255),
    update_by          NVARCHAR(50) NOT NULL DEFAULT 'System',
    update_date        DATETIME     NOT NULL DEFAULT CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME),
    is_active          BIT          NOT NULL DEFAULT 1,
    is_delete          BIT          NOT NULL DEFAULT 0,
    id_status          NVARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    CONSTRAINT FK_tb_blacklist_project_id FOREIGN KEY(project_id) REFERENCES tb_project(project_id)
);
GO

-- ==========================================================
-- update+ สร้างตาราง tb_admin และปรับชื่อฟิลด์เป็น admin_XXXX
-- ==========================================================
CREATE TABLE tb_admin
(
    autoID             INT IDENTITY(1,1) PRIMARY KEY,
    prefix             NVARCHAR(3)   NOT NULL DEFAULT 'ADM',
    admin_id           NVARCHAR(50)  NOT NULL UNIQUE, -- Business ID สำหรับใช้ในระบบ
    admin_name         NVARCHAR(50)  NOT NULL UNIQUE, -- ใช้สำหรับชื่อผู้ดูแลระบบในการ Login
    admin_password     NVARCHAR(255) NOT NULL,        -- รองรับความยาวของ Bcrypt Hash String
    admin_level        NVARCHAR(20)  NOT NULL DEFAULT 'ADMIN',
    project_id         NVARCHAR(50)  NOT NULL,
    update_by          NVARCHAR(50)  NOT NULL DEFAULT 'System',
    update_date        DATETIME      NOT NULL DEFAULT CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME),
    is_active          BIT           NOT NULL DEFAULT 1,
    is_delete          BIT           NOT NULL DEFAULT 0,
    id_status          NVARCHAR(20)  NOT NULL DEFAULT 'ACTIVE',
    CONSTRAINT FK_tb_admin_project_id FOREIGN KEY(project_id) REFERENCES tb_project(project_id)
);
GO


/* ==========================================================
   3. INDEXES
   ========================================================== */

CREATE NONCLUSTERED INDEX IX_tb_house_project_id ON tb_house ([project_id]);
CREATE NONCLUSTERED INDEX IX_tb_user_project_id ON tb_user ([project_id]);
CREATE NONCLUSTERED INDEX IX_tb_user_house_id ON tb_user ([house_id]);
CREATE NONCLUSTERED INDEX IX_tb_vehicle_project_id ON tb_vehicle ([project_id]);
CREATE NONCLUSTERED INDEX IX_tb_vehicle_user_id ON tb_vehicle ([user_id]);
CREATE NONCLUSTERED INDEX IX_tb_vehicle_license_plate ON tb_vehicle ([license_plate]);
CREATE NONCLUSTERED INDEX IX_tb_access_log_project_id ON tb_access_log ([project_id]);
CREATE NONCLUSTERED INDEX IX_tb_access_log_access_date ON tb_access_log ([access_date]);
CREATE NONCLUSTERED INDEX IX_tb_access_log_license_plate ON tb_access_log ([license_plate]);
CREATE NONCLUSTERED INDEX IX_tb_blacklist_license_plate ON tb_blacklist ([license_plate]);
CREATE NONCLUSTERED INDEX IX_tb_admin_project_id ON tb_admin ([project_id]);
GO

/* ==========================================================
   4. TRIGGERS
   ========================================================== */

CREATE OR ALTER TRIGGER TRIG_AUTO_UPDATE_DATE_tb_project ON tb_project AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE t SET update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
    FROM tb_project t INNER JOIN inserted i ON t.autoID = i.autoID;
END
GO

CREATE OR ALTER TRIGGER TRIG_AUTO_UPDATE_DATE_tb_house ON tb_house AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE t SET update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
    FROM tb_house t INNER JOIN inserted i ON t.autoID = i.autoID;
END
GO

CREATE OR ALTER TRIGGER TRIG_AUTO_UPDATE_DATE_tb_user ON tb_user AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE t SET update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
    FROM tb_user t INNER JOIN inserted i ON t.autoID = i.autoID;
END
GO

CREATE OR ALTER TRIGGER TRIG_AUTO_UPDATE_DATE_tb_vehicle ON tb_vehicle AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE t SET update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
    FROM tb_vehicle t INNER JOIN inserted i ON t.autoID = i.autoID;
END
GO

CREATE OR ALTER TRIGGER TRIG_AUTO_UPDATE_DATE_tb_device ON tb_device AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE t SET update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
    FROM tb_device t INNER JOIN inserted i ON t.autoID = i.autoID;
END
GO

CREATE OR ALTER TRIGGER TRIG_AUTO_UPDATE_DATE_tb_blacklist ON tb_blacklist AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE t SET update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
    FROM tb_blacklist t INNER JOIN inserted i ON t.autoID = i.autoID;
END
GO

CREATE OR ALTER TRIGGER TRIG_AUTO_UPDATE_DATE_tb_access_log ON tb_access_log AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE t SET update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
    FROM tb_access_log t INNER JOIN inserted i ON t.autoID = i.autoID;
END
GO

CREATE OR ALTER TRIGGER TRIG_AUTO_UPDATE_DATE_tb_admin ON tb_admin AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE t SET update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
    FROM tb_admin t INNER JOIN inserted i ON t.autoID = i.autoID;
END
GO