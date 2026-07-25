-- SQL Server Housing Administration seed for DOC healthcare demo
-- Oracle OMS events live in the separate Oracle container.

IF DB_ID(N'DocHealthcare') IS NULL
BEGIN
    CREATE DATABASE DocHealthcare;
END
GO

USE DocHealthcare;
GO

IF OBJECT_ID(N'dbo.OperationalEvents', N'U') IS NOT NULL
    DROP TABLE dbo.OperationalEvents;
GO

IF OBJECT_ID(N'dbo.Patients', N'U') IS NOT NULL
    DROP TABLE dbo.Patients;
GO

CREATE TABLE dbo.Patients (
    OffenderId      NVARCHAR(20)  NOT NULL PRIMARY KEY,
    Mrn             NVARCHAR(20)  NOT NULL,
    LastName        NVARCHAR(50)  NOT NULL,
    FirstName       NVARCHAR(50)  NOT NULL,
    MiddleName      NVARCHAR(50)  NULL,
    BirthDate       DATE          NOT NULL,
    Sex             CHAR(1)       NOT NULL,
    Street          NVARCHAR(100) NOT NULL,
    City            NVARCHAR(50)  NOT NULL,
    State           CHAR(2)       NOT NULL,
    Zip             NVARCHAR(10)  NOT NULL,
    Phone           NVARCHAR(20)  NULL
);
GO

CREATE TABLE dbo.OperationalEvents (
    EventId           INT            NOT NULL PRIMARY KEY,
    SourceSystem      NVARCHAR(40)   NOT NULL,  -- SQLSERVER_HOUSING
    EventType         NVARCHAR(30)   NOT NULL,  -- TRANSFER | BED_ASSIGN | MULTI
    ChildEventTypes   NVARCHAR(200)  NULL,
    OffenderId        NVARCHAR(20)   NOT NULL,
    FacilityCode      NVARCHAR(20)   NOT NULL,
    UnitCode          NVARCHAR(20)   NULL,
    BedCode           NVARCHAR(20)   NULL,
    PriorFacilityCode NVARCHAR(20)   NULL,
    PriorUnitCode     NVARCHAR(20)   NULL,
    PriorBedCode      NVARCHAR(20)   NULL,
    AttendingNpi      NVARCHAR(20)   NULL,
    AttendingName     NVARCHAR(80)   NULL,
    EventTimestamp    DATETIME2(0)   NOT NULL,
    Status            NVARCHAR(20)   NOT NULL DEFAULT N'PENDING',
    Notes             NVARCHAR(200)  NULL
);
GO

INSERT INTO dbo.Patients (
    OffenderId, Mrn, LastName, FirstName, MiddleName, BirthDate, Sex,
    Street, City, State, Zip, Phone
)
VALUES
    (N'OFF-10021', N'MRN10021', N'GARCIA',   N'MIGUEL',  N'A', '1984-03-12', 'M', N'14 CEDAR LN',     N'SPRINGFIELD', N'IL', N'62701', N'2175550142'),
    (N'OFF-10044', N'MRN10044', N'JOHNSON',  N'DEANDRE', N'L', '1991-11-02', 'M', N'880 RIVER RD',    N'PEORIA',      N'IL', N'61602', N'3095550188'),
    (N'OFF-10057', N'MRN10057', N'WILLIAMS', N'ASHLEY',  N'R', '1988-07-25', 'F', N'221 OAK ST APT 4',N'CHAMPAIGN',   N'IL', N'61820', N'2175550199'),
    (N'OFF-10063', N'MRN10063', N'BROWN',    N'TYRONE',  NULL, '1979-01-30', 'M', N'55 PINE AVE',     N'DECATUR',     N'IL', N'62521', N'2175550110');
GO

INSERT INTO dbo.OperationalEvents (
    EventId, SourceSystem, EventType, ChildEventTypes, OffenderId,
    FacilityCode, UnitCode, BedCode, PriorFacilityCode, PriorUnitCode, PriorBedCode,
    AttendingNpi, AttendingName, EventTimestamp, Status, Notes
)
VALUES
    (1003, N'SQLSERVER_HOUSING', N'TRANSFER', NULL, N'OFF-10021',
     N'NORTH', N'C-WING', N'308', N'NORTH', N'A-WING', N'101',
     N'1234567890', N'SMITH^JANE^MD', '2026-07-24T10:42:00', N'PENDING',
     N'Unit transfer within North (SQL Server Housing)'),

    (1004, N'SQLSERVER_HOUSING', N'BED_ASSIGN', NULL, N'OFF-10057',
     N'SOUTH', N'D-WING', N'012', N'SOUTH', N'D-WING', N'008',
     N'1987654321', N'LEE^DAVID^MD', '2026-07-24T11:05:00', N'PENDING',
     N'Bed reassignment (SQL Server Housing)'),

    (1006, N'SQLSERVER_HOUSING', N'MULTI', N'TRANSFER,BED_ASSIGN', N'OFF-10063',
     N'EAST', N'E-WING', N'401', N'NORTH', N'C-WING', N'220',
     N'1122334455', N'PATEL^RINA^MD', '2026-07-24T13:55:00', N'PENDING',
     N'Inter-facility transfer package (SQL Server Housing)');
GO

SELECT EventId, SourceSystem, EventType, ChildEventTypes, OffenderId, Status
FROM dbo.OperationalEvents
ORDER BY EventId;
GO
