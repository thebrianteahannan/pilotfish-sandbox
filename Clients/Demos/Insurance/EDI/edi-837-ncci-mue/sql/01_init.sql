IF DB_ID(N'Edi837NcciMue') IS NULL
BEGIN
    CREATE DATABASE Edi837NcciMue;
END
GO

USE Edi837NcciMue;
GO

IF OBJECT_ID(N'dbo.MueEdits', N'U') IS NOT NULL DROP TABLE dbo.MueEdits;
GO

-- Same idea as Med Rec MUE_EDITS (CPT + MAX_VALUE_PER_LINE). Demo-sized
-- CMS-shaped seed — not the official NCCI quarterly file.
CREATE TABLE dbo.MueEdits (
    Cpt              NVARCHAR(10)  NOT NULL PRIMARY KEY,
    MaxUnits         INT           NOT NULL,
    Mai              CHAR(1)       NOT NULL,
    Description      NVARCHAR(200) NOT NULL
);
GO

INSERT INTO dbo.MueEdits (Cpt, MaxUnits, Mai, Description)
VALUES
    (N'99213', 2, N'2', N'Office visit established - demo MUE max 2'),
    (N'97110', 4, N'3', N'Therapeutic exercises - demo MUE max 4'),
    (N'36415', 1, N'2', N'Venipuncture - demo MUE max 1'),
    (N'45378', 1, N'2', N'Colonoscopy diagnostic - demo MUE max 1');
GO
