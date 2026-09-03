IF DB_ID('CRLPlus') IS NULL
    CREATE DATABASE CRLPlus;
GO
USE CRLPlus;
GO
IF OBJECT_ID('dbo.sandbox_ping', 'U') IS NULL
    CREATE TABLE dbo.sandbox_ping (id INT IDENTITY PRIMARY KEY, note NVARCHAR(200) NOT NULL);
INSERT INTO dbo.sandbox_ping (note) VALUES ('crl-plus sandbox');
GO
