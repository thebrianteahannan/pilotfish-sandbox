IF DB_ID(N'Edi837NcciPtp') IS NULL
BEGIN
    CREATE DATABASE Edi837NcciPtp;
END
GO

USE Edi837NcciPtp;
GO

IF OBJECT_ID(N'dbo.PtpEdits', N'U') IS NOT NULL DROP TABLE dbo.PtpEdits;
GO

-- CMS NCCI Procedure-to-Procedure shape: column 1 / column 2 / modifier indicator.
-- Demo-sized seed - not the official quarterly PTP file. Med Rec has MUE only, not PTP.
CREATE TABLE dbo.PtpEdits (
    Column1              NVARCHAR(10)  NOT NULL,
    Column2              NVARCHAR(10)  NOT NULL,
    ModifierIndicator    CHAR(1)       NOT NULL,
    Description          NVARCHAR(200) NOT NULL,
    CONSTRAINT PK_PtpEdits PRIMARY KEY (Column1, Column2)
);
GO

INSERT INTO dbo.PtpEdits (Column1, Column2, ModifierIndicator, Description)
VALUES
    (N'45378', N'45380', N'1', N'Colonoscopy + biopsy - modifier 59 may bypass'),
    (N'93000', N'93005', N'0', N'EKG tracing pair - modifier never allowed');
GO
