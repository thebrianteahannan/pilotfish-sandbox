-- HL7 Healthcare Automation demo (Primary Insurer-style case study)
IF DB_ID(N'Hl7AutomationDemo') IS NULL
BEGIN
  CREATE DATABASE Hl7AutomationDemo;
END
GO

USE Hl7AutomationDemo;
GO

IF OBJECT_ID(N'dbo.Hl7Messages', N'U') IS NOT NULL DROP TABLE dbo.Hl7Messages;
IF OBJECT_ID(N'dbo.Hospitals', N'U') IS NOT NULL DROP TABLE dbo.Hospitals;
GO

CREATE TABLE dbo.Hospitals (
  HospitalCode NVARCHAR(32) NOT NULL PRIMARY KEY,
  HospitalName NVARCHAR(120) NOT NULL
);

CREATE TABLE dbo.Hl7Messages (
  MessageId INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  HospitalCode NVARCHAR(32) NULL,
  MessageType NVARCHAR(20) NULL,
  TriggerEvent NVARCHAR(10) NULL,
  PatientId NVARCHAR(64) NULL,
  PatientName NVARCHAR(200) NULL,
  ControlId NVARCHAR(64) NULL,
  IsBatch BIT NOT NULL CONSTRAINT DF_Hl7Messages_IsBatch DEFAULT (0),
  ValidationStatus NVARCHAR(32) NOT NULL CONSTRAINT DF_Hl7Messages_Val DEFAULT (N'PASSED'),
  SourceFile NVARCHAR(260) NULL,
  RawHl7 NVARCHAR(MAX) NULL,
  ReceivedAt DATETIME2 NOT NULL CONSTRAINT DF_Hl7Messages_ReceivedAt DEFAULT (SYSUTCDATETIME())
);

INSERT INTO dbo.Hospitals (HospitalCode, HospitalName) VALUES
  (N'HOSP-01', N'Metro General Hospital'),
  (N'HOSP-02', N'Riverside Medical Center'),
  (N'HOSP-03', N'Lakeside Community Hospital');
GO
