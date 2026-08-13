-- SQL Server PilotFish XML Export — database + seed Captures
IF DB_ID(N'PilotFishDemo') IS NULL
BEGIN
  CREATE DATABASE PilotFishDemo;
END
GO

USE PilotFishDemo;
GO

IF OBJECT_ID(N'dbo.Captures', N'U') IS NOT NULL DROP TABLE dbo.Captures;
GO

CREATE TABLE dbo.Captures (
  CaptureId INT NOT NULL PRIMARY KEY,
  ClientName NVARCHAR(120) NOT NULL,
  DocumentType NVARCHAR(80) NOT NULL,
  Status NVARCHAR(40) NOT NULL,
  CapturePayload NVARCHAR(400) NOT NULL,
  CreatedAt DATETIME2 NOT NULL
);
GO

INSERT INTO dbo.Captures (CaptureId, ClientName, DocumentType, Status, CapturePayload, CreatedAt)
VALUES
  (1001, N'American General', N'ACORD 121', N'COMPLETE', N'Order POL-77821 accepted', '2026-07-16T09:15:00'),
  (1002, N'Prudential', N'ACORD 103', N'PENDING', N'Awaiting underwriting docs', '2026-07-16T10:02:00'),
  (1003, N'Erie', N'Image WS', N'COMPLETE', N'TIFF package delivered', '2026-07-16T11:40:00');
GO
