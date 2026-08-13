-- FHIR R4 Platform Phase 6 — Bulk $export job tracking
USE FhirR4PlatformDemo;
GO

IF OBJECT_ID(N'dbo.FhirExportJobs', N'U') IS NULL
BEGIN
  CREATE TABLE dbo.FhirExportJobs (
    JobId NVARCHAR(64) NOT NULL CONSTRAINT PK_FhirExportJobs PRIMARY KEY,
    Status NVARCHAR(32) NOT NULL, -- accepted | in-progress | completed | error
    RequestUrl NVARCHAR(400) NULL,
    TypesCsv NVARCHAR(400) NULL,
    OutputManifest NVARCHAR(MAX) NULL,
    ErrorText NVARCHAR(MAX) NULL,
    CreatedAt DATETIME2 NOT NULL CONSTRAINT DF_FhirExportJobs_CreatedAt DEFAULT (SYSUTCDATETIME()),
    UpdatedAt DATETIME2 NOT NULL CONSTRAINT DF_FhirExportJobs_UpdatedAt DEFAULT (SYSUTCDATETIME()),
    CompletedAt DATETIME2 NULL
  );
END
GO
