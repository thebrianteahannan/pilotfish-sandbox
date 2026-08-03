-- FHIR Patient Exchange demo
IF DB_ID(N'FhirPatientExchangeDemo') IS NULL
BEGIN
  CREATE DATABASE FhirPatientExchangeDemo;
END
GO

USE FhirPatientExchangeDemo;
GO

IF OBJECT_ID(N'dbo.FhirResources', N'U') IS NOT NULL DROP TABLE dbo.FhirResources;
IF OBJECT_ID(N'dbo.SourceSystems', N'U') IS NOT NULL DROP TABLE dbo.SourceSystems;
GO

CREATE TABLE dbo.SourceSystems (
  SourceCode NVARCHAR(32) NOT NULL PRIMARY KEY,
  SourceName NVARCHAR(120) NOT NULL
);

CREATE TABLE dbo.FhirResources (
  ResourceRowId INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  SourceCode NVARCHAR(32) NULL,
  ResourceType NVARCHAR(64) NULL,
  ResourceId NVARCHAR(128) NULL,
  PatientId NVARCHAR(64) NULL,
  PatientName NVARCHAR(200) NULL,
  IsBundle BIT NOT NULL CONSTRAINT DF_FhirResources_IsBundle DEFAULT (0),
  ValidationStatus NVARCHAR(32) NOT NULL CONSTRAINT DF_FhirResources_Val DEFAULT (N'PASS'),
  SourceFile NVARCHAR(260) NULL,
  RawFhir NVARCHAR(MAX) NULL,
  ReceivedAt DATETIME2 NOT NULL CONSTRAINT DF_FhirResources_ReceivedAt DEFAULT (SYSUTCDATETIME())
);

INSERT INTO dbo.SourceSystems (SourceCode, SourceName) VALUES
  (N'EHR-01', N'Metro General EHR'),
  (N'EHR-02', N'Riverside FHIR Gateway'),
  (N'EHR-03', N'Lakeside Patient Access API');
GO
