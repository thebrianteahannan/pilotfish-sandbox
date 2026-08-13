-- FHIR R4 Expandable Platform (Phase 1 base schema)
-- Phase 2 search tokens/procs: see 02_phase2_search.sql (compose runs both).
IF DB_ID(N'FhirR4PlatformDemo') IS NULL
BEGIN
  CREATE DATABASE FhirR4PlatformDemo;
END
GO

USE FhirR4PlatformDemo;
GO

IF OBJECT_ID(N'dbo.FhirResources', N'U') IS NOT NULL DROP TABLE dbo.FhirResources;
GO

CREATE TABLE dbo.FhirResources (
  ResourceRowId INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  SourceCode NVARCHAR(32) NULL,
  ResourceType NVARCHAR(64) NOT NULL,
  ResourceId NVARCHAR(128) NOT NULL,
  PatientId NVARCHAR(64) NULL,
  PatientName NVARCHAR(200) NULL,
  IsBundle BIT NOT NULL CONSTRAINT DF_FhirR4_IsBundle DEFAULT (0),
  ValidationStatus NVARCHAR(32) NOT NULL CONSTRAINT DF_FhirR4_Val DEFAULT (N'PASS'),
  SourceFile NVARCHAR(260) NULL,
  RawFhir NVARCHAR(MAX) NOT NULL,
  Source NVARCHAR(32) NOT NULL CONSTRAINT DF_FhirR4_Source DEFAULT (N'local'),
  DeletedAt DATETIME2 NULL,
  ReceivedAt DATETIME2 NOT NULL CONSTRAINT DF_FhirR4_ReceivedAt DEFAULT (SYSUTCDATETIME()),
  UpdatedAt DATETIME2 NOT NULL CONSTRAINT DF_FhirR4_UpdatedAt DEFAULT (SYSUTCDATETIME()),
  CONSTRAINT UQ_FhirR4_TypeId UNIQUE (ResourceType, ResourceId)
);

CREATE INDEX IX_FhirR4_ResourceId ON dbo.FhirResources (ResourceId);
CREATE INDEX IX_FhirR4_Type_Deleted ON dbo.FhirResources (ResourceType, DeletedAt);
GO
