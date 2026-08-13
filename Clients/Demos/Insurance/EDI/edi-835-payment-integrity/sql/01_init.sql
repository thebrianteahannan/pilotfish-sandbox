IF DB_ID(N'Edi835PaymentIntegrity') IS NULL
BEGIN
    CREATE DATABASE Edi835PaymentIntegrity;
END
GO

USE Edi835PaymentIntegrity;
GO

IF OBJECT_ID(N'dbo.OpenAR', N'U') IS NOT NULL DROP TABLE dbo.OpenAR;
GO

CREATE TABLE dbo.OpenAR (
    ClaimControlNumber NVARCHAR(40)   NOT NULL PRIMARY KEY,
    PatientLastName    NVARCHAR(50)   NOT NULL,
    PatientFirstName   NVARCHAR(50)   NOT NULL,
    MemberId           NVARCHAR(30)   NOT NULL,
    ServiceDate        DATE           NOT NULL,
    BilledAmount       DECIMAL(12,2)  NOT NULL,
    ExpectedPaid       DECIMAL(12,2)  NOT NULL,
    Status             NVARCHAR(20)   NOT NULL DEFAULT N'OPEN',
    Notes              NVARCHAR(200)  NULL,
    UpdatedAt          DATETIME2(0)   NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

INSERT INTO dbo.OpenAR
    (ClaimControlNumber, PatientLastName, PatientFirstName, MemberId, ServiceDate, BilledAmount, ExpectedPaid, Status, Notes)
VALUES
    (N'PATCLAIM001', N'DOE',   N'JANE', N'MEM001', '2026-07-15', 500.00, 500.00, N'OPEN', N'Full expected allowed — remit underpays'),
    (N'PATCLAIM002', N'SMITH', N'JOHN', N'MEM002', '2026-07-18', 100.00,  88.00, N'OPEN', N'Contracted allowed amount — exact match'),
    (N'PATCLAIM003', N'LEE',   N'ANA',  N'MEM003', '2026-07-20', 250.00, 200.00, N'OPEN', N'Contracted allowed — exact match');
GO
