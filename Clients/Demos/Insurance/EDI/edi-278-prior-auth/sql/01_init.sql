IF DB_ID(N'Edi278PriorAuth') IS NULL
BEGIN
    CREATE DATABASE Edi278PriorAuth;
END
GO

USE Edi278PriorAuth;
GO

IF OBJECT_ID(N'dbo.AuthCatalog', N'U') IS NOT NULL DROP TABLE dbo.AuthCatalog;
IF OBJECT_ID(N'dbo.AuthRequest', N'U') IS NOT NULL DROP TABLE dbo.AuthRequest;
GO

CREATE TABLE dbo.AuthCatalog (
    ProcedureCode        NVARCHAR(10)   NOT NULL PRIMARY KEY,
    ProcedureDescription NVARCHAR(120)  NOT NULL,
    RequiresDiagnosis    BIT            NOT NULL DEFAULT 1,
    RequiresAttachment   BIT            NOT NULL DEFAULT 0,
    DefaultDisposition   NVARCHAR(20)   NOT NULL,
    Notes                NVARCHAR(200)  NULL
);
GO

CREATE TABLE dbo.AuthRequest (
    AuthTraceNumber  NVARCHAR(40)   NOT NULL PRIMARY KEY,
    MemberId         NVARCHAR(30)   NOT NULL,
    PatientLastName  NVARCHAR(50)   NOT NULL,
    PatientFirstName NVARCHAR(50)   NOT NULL,
    ProcedureCode    NVARCHAR(10)   NOT NULL,
    DiagnosisCode    NVARCHAR(20)    NULL,
    AttachmentFlag   NVARCHAR(1)    NOT NULL DEFAULT N'N',
    Status           NVARCHAR(20)   NOT NULL DEFAULT N'OPEN',
    Notes            NVARCHAR(200)  NULL,
    UpdatedAt        DATETIME2(0)   NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

INSERT INTO dbo.AuthCatalog
    (ProcedureCode, ProcedureDescription, RequiresDiagnosis, RequiresAttachment, DefaultDisposition, Notes)
VALUES
    (N'27447', N'Total knee arthroplasty', 1, 1, N'APPROVE', N'Requires clinical attachment'),
    (N'70553', N'MRI brain w/ + w/o contrast', 1, 0, N'DENY', N'Demo medical-necessity deny theater'),
    (N'99214', N'Office visit established', 1, 0, N'APPROVE', N'Routine PA approval'),
    (N'72148', N'MRI lumbar spine w/o contrast', 1, 0, N'PEND', N'Demo pended for manual review');
GO

INSERT INTO dbo.AuthRequest
    (AuthTraceNumber, MemberId, PatientLastName, PatientFirstName, ProcedureCode, DiagnosisCode, AttachmentFlag, Status, Notes)
VALUES
    (N'PACOMPLETE01', N'MEM001', N'DOE',   N'JANE', N'27447', N'M17.11', N'Y', N'OPEN', N'Complete knee PA — expect APPROVE'),
    (N'PAINCOMPLETE01', N'MEM002', N'SMITH', N'JOHN', N'99214', NULL,     N'N', N'OPEN', N'Missing diagnosis on wire — expect INCOMPLETE'),
    (N'PADENY01',     N'MEM003', N'LEE',   N'ANA',  N'70553', N'G43.909', N'N', N'OPEN', N'Complete MRI brain — expect DENY'),
    (N'PAPEND01',     N'MEM004', N'NGUYEN',N'MINH', N'72148', N'M54.5',  N'N', N'OPEN', N'Complete lumbar MRI — expect PEND');
GO
