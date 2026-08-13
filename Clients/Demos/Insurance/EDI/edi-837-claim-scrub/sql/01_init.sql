IF DB_ID(N'Edi837ClaimScrub') IS NULL
BEGIN
    CREATE DATABASE Edi837ClaimScrub;
END
GO

USE Edi837ClaimScrub;
GO

IF OBJECT_ID(N'dbo.ClaimLines', N'U') IS NOT NULL DROP TABLE dbo.ClaimLines;
IF OBJECT_ID(N'dbo.Claims', N'U') IS NOT NULL DROP TABLE dbo.Claims;
IF OBJECT_ID(N'dbo.PayerEditRules', N'U') IS NOT NULL DROP TABLE dbo.PayerEditRules;
IF OBJECT_ID(N'dbo.Providers', N'U') IS NOT NULL DROP TABLE dbo.Providers;
IF OBJECT_ID(N'dbo.Patients', N'U') IS NOT NULL DROP TABLE dbo.Patients;
GO

CREATE TABLE dbo.Patients (
    PatientId     NVARCHAR(20)  NOT NULL PRIMARY KEY,
    MemberId      NVARCHAR(30)  NOT NULL,
    LastName      NVARCHAR(50)  NOT NULL,
    FirstName     NVARCHAR(50)  NOT NULL,
    MiddleName    NVARCHAR(50)  NULL,
    BirthDate     DATE          NOT NULL,
    Sex           CHAR(1)       NOT NULL,
    Street        NVARCHAR(100) NOT NULL,
    City          NVARCHAR(50)  NOT NULL,
    State         CHAR(2)       NOT NULL,
    Zip           NVARCHAR(10)  NOT NULL,
    Phone         NVARCHAR(20)  NULL
);
GO

CREATE TABLE dbo.Providers (
    ProviderId    NVARCHAR(20)  NOT NULL PRIMARY KEY,
    Npi           NVARCHAR(10)  NOT NULL,
    OrgName       NVARCHAR(80)  NOT NULL,
    Street        NVARCHAR(100) NOT NULL,
    City          NVARCHAR(50)  NOT NULL,
    State         CHAR(2)       NOT NULL,
    Zip           NVARCHAR(10)  NOT NULL,
    Taxonomy      NVARCHAR(20)  NULL
);
GO

-- Synthetic payer profile / edit catalog (demo BI source for rule ownership)
CREATE TABLE dbo.PayerEditRules (
    RuleId            INT            NOT NULL PRIMARY KEY,
    PayerId           NVARCHAR(30)   NOT NULL,
    PayerName         NVARCHAR(80)   NOT NULL,
    RuleCode          NVARCHAR(40)   NOT NULL,
    Severity          NVARCHAR(20)   NOT NULL DEFAULT N'REJECT',
    Message           NVARCHAR(240)  NOT NULL,
    RequireReferringNpi BIT          NOT NULL DEFAULT 0,
    AllowedPosList    NVARCHAR(40)   NOT NULL DEFAULT N'11'
);
GO

CREATE TABLE dbo.Claims (
    ClaimId           INT            NOT NULL PRIMARY KEY,
    PatientId         NVARCHAR(20)   NOT NULL REFERENCES dbo.Patients(PatientId),
    BillingProviderId NVARCHAR(20)   NOT NULL REFERENCES dbo.Providers(ProviderId),
    PayerId           NVARCHAR(30)   NOT NULL,
    PayerName         NVARCHAR(80)   NOT NULL,
    ClaimNumber       NVARCHAR(40)   NOT NULL,
    ServiceDate       DATE           NOT NULL,
    ClaimAmount       DECIMAL(12,2)  NOT NULL,
    PlaceOfService    CHAR(2)        NOT NULL DEFAULT '11',
    ReferringNpi      NVARCHAR(10)   NULL,
    DiagnosisCode     NVARCHAR(10)   NOT NULL,
    Status            NVARCHAR(20)   NOT NULL DEFAULT N'PENDING',
    CreatedAt         DATETIME2(0)   NOT NULL DEFAULT SYSUTCDATETIME(),
    Notes             NVARCHAR(200)  NULL
);
GO

CREATE TABLE dbo.ClaimLines (
    ClaimLineId   INT            NOT NULL PRIMARY KEY,
    ClaimId       INT            NOT NULL REFERENCES dbo.Claims(ClaimId),
    LineNumber    INT            NOT NULL,
    ProcedureCode NVARCHAR(10)   NOT NULL,
    Modifier1     NVARCHAR(2)    NULL,
    ChargeAmount  DECIMAL(12,2)  NOT NULL,
    Units         DECIMAL(8,1)   NOT NULL DEFAULT 1,
    ServiceDate   DATE           NOT NULL
);
GO

INSERT INTO dbo.Patients (PatientId, MemberId, LastName, FirstName, MiddleName, BirthDate, Sex, Street, City, State, Zip, Phone) VALUES
 (N'PAT-1001', N'MBR1001', N'CUNNINGHAM', N'BOB',     NULL, '1968-04-12', 'M', N'1974 HAMILTON DR', N'LAUREL',    N'MD', N'20707', N'3015550142'),
 (N'PAT-1002', N'MBR1002', N'NUNEZ',      N'FRANCIS', N'A', '1975-09-03', 'F', N'4149 ASHMOR DR',   N'BALTIMORE', N'MD', N'21201', N'4105550188'),
 (N'PAT-1003', N'MBR1003', N'PATEL',      N'RIYA',    NULL, '1990-01-22', 'F', N'88 MARKET ST',     N'ROCKVILLE', N'MD', N'20850', N'2405550199');
GO

INSERT INTO dbo.Providers (ProviderId, Npi, OrgName, Street, City, State, Zip, Taxonomy) VALUES
 (N'PRV-01', N'1234567893', N'KILDARE ASSOCIATES', N'2345 OCEAN BLVD', N'MIAMI',      N'FL', N'33111', N'207Q00000X'),
 (N'PRV-02', N'1987654321', N'CAPITAL CARE GROUP', N'500 WISCONSIN AVE', N'BETHESDA', N'MD', N'20814', N'207R00000X');
GO

INSERT INTO dbo.PayerEditRules (RuleId, PayerId, PayerName, RuleCode, Severity, Message, RequireReferringNpi, AllowedPosList) VALUES
 (1, N'66783JJT', N'AHLIC',      N'MISSING_REFERRING_NPI', N'REJECT', N'AHLIC requires a referring provider NPI (loop 2310A) before clearinghouse submit.', 1, N'11,12'),
 (2, N'66783JJT', N'AHLIC',      N'INVALID_POS',          N'REJECT', N'AHLIC allows Place of Service 11 or 12 only.', 1, N'11,12'),
 (3, N'MDCAID01', N'MEDICAID MD', N'INVALID_POS',          N'REJECT', N'MEDICAID MD allows Place of Service 11, 21, or 22 only.', 0, N'11,21,22');
GO

-- 5001 clean AHLIC (referring NPI + POS 11)
-- 5002 kickout AHLIC missing referring NPI
-- 5003 kickout AHLIC invalid POS 99
-- 5004 clean MEDICAID MD (no referring NPI required, POS 21)
INSERT INTO dbo.Claims (ClaimId, PatientId, BillingProviderId, PayerId, PayerName, ClaimNumber, ServiceDate, ClaimAmount, PlaceOfService, ReferringNpi, DiagnosisCode, Status, Notes) VALUES
 (5001, N'PAT-1001', N'PRV-01', N'66783JJT', N'AHLIC',      N'CLM-5001', '2026-07-15', 140.55, '11', N'1679576722', N'J06.9',  N'PENDING', N'Seed clean office visit'),
 (5002, N'PAT-1002', N'PRV-02', N'66783JJT', N'AHLIC',      N'CLM-5002', '2026-07-18', 225.00, '11', NULL,         N'M54.5',  N'PENDING', N'Seed kickout: missing referring NPI'),
 (5003, N'PAT-1003', N'PRV-01', N'66783JJT', N'AHLIC',      N'CLM-5003', '2026-07-20',  95.00, '99', N'1679576722', N'Z00.00', N'PENDING', N'Seed kickout: invalid POS'),
 (5004, N'PAT-1001', N'PRV-02', N'MDCAID01', N'MEDICAID MD', N'CLM-5004', '2026-07-22', 310.00, '21', NULL,         N'I10',    N'PENDING', N'Seed clean inpatient professional');
GO

INSERT INTO dbo.ClaimLines (ClaimLineId, ClaimId, LineNumber, ProcedureCode, Modifier1, ChargeAmount, Units, ServiceDate) VALUES
 (1, 5001, 1, N'99213', NULL, 140.55, 1, '2026-07-15'),
 (2, 5002, 1, N'97110', N'GP', 125.00, 1, '2026-07-18'),
 (3, 5002, 2, N'97140', N'GP', 100.00, 1, '2026-07-18'),
 (4, 5003, 1, N'99395', NULL,  95.00, 1, '2026-07-20'),
 (5, 5004, 1, N'99223', NULL, 310.00, 1, '2026-07-22');
GO
