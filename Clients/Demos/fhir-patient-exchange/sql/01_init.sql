-- FHIR Patient Exchange demo (REST façade persistence)
IF DB_ID(N'FhirPatientExchangeDemo') IS NULL
BEGIN
  CREATE DATABASE FhirPatientExchangeDemo;
END
GO

USE FhirPatientExchangeDemo;
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
  IsBundle BIT NOT NULL CONSTRAINT DF_FhirResources_IsBundle DEFAULT (0),
  ValidationStatus NVARCHAR(32) NOT NULL CONSTRAINT DF_FhirResources_Val DEFAULT (N'PASS'),
  SourceFile NVARCHAR(260) NULL,
  RawFhir NVARCHAR(MAX) NOT NULL,
  ReceivedAt DATETIME2 NOT NULL CONSTRAINT DF_FhirResources_ReceivedAt DEFAULT (SYSUTCDATETIME()),
  CONSTRAINT UQ_FhirResources_TypeId UNIQUE (ResourceType, ResourceId)
);

CREATE INDEX IX_FhirResources_ResourceId ON dbo.FhirResources (ResourceId);
GO
