-- FHIR R4 Expandable Platform — Phase 2 search tokens + procs
-- Applied after 01_init.sql (compose runs both). Safe to re-run.

USE FhirR4PlatformDemo;
GO

IF OBJECT_ID(N'dbo.FhirSearchTokens', N'U') IS NULL
BEGIN
  CREATE TABLE dbo.FhirSearchTokens (
    TokenId BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ResourceType NVARCHAR(64) NOT NULL,
    ResourceId NVARCHAR(128) NOT NULL,
    ParamCode NVARCHAR(64) NOT NULL,
    System NVARCHAR(256) NULL,
    Value NVARCHAR(400) NOT NULL
  );
  CREATE INDEX IX_FhirSearch_Lookup
    ON dbo.FhirSearchTokens (ResourceType, ParamCode, Value)
    INCLUDE (ResourceId);
  CREATE INDEX IX_FhirSearch_Resource
    ON dbo.FhirSearchTokens (ResourceType, ResourceId);
END
GO

CREATE OR ALTER PROCEDURE dbo.FhirReindexResource
  @ResourceType NVARCHAR(64),
  @ResourceId NVARCHAR(128)
AS
BEGIN
  SET NOCOUNT ON;

  DELETE FROM dbo.FhirSearchTokens
  WHERE ResourceType = @ResourceType AND ResourceId = @ResourceId;

  DECLARE @json NVARCHAR(MAX);
  SELECT @json = RawFhir
  FROM dbo.FhirResources
  WHERE ResourceType = @ResourceType
    AND ResourceId = @ResourceId
    AND DeletedAt IS NULL;

  IF @json IS NULL OR LTRIM(RTRIM(@json)) = N''
    RETURN;

  /* Always index logical id */
  INSERT INTO dbo.FhirSearchTokens (ResourceType, ResourceId, ParamCode, System, Value)
  VALUES (@ResourceType, @ResourceId, N'_id', NULL, LOWER(@ResourceId));

  /* --- Patient / Practitioner name + demographics --- */
  IF @ResourceType IN (N'Patient', N'Practitioner')
  BEGIN
    INSERT INTO dbo.FhirSearchTokens (ResourceType, ResourceId, ParamCode, System, Value)
    SELECT @ResourceType, @ResourceId, N'family', NULL, LOWER(LTRIM(RTRIM(n.family)))
    FROM OPENJSON(@json, '$.name') WITH (family NVARCHAR(200) '$.family') AS n
    WHERE n.family IS NOT NULL AND LTRIM(RTRIM(n.family)) <> N'';

    INSERT INTO dbo.FhirSearchTokens (ResourceType, ResourceId, ParamCode, System, Value)
    SELECT @ResourceType, @ResourceId, N'given', NULL, LOWER(LTRIM(RTRIM(g.value)))
    FROM OPENJSON(@json, '$.name') AS n
    CROSS APPLY OPENJSON(n.value, '$.given') AS g
    WHERE g.value IS NOT NULL AND LTRIM(RTRIM(g.value)) <> N'';

    INSERT INTO dbo.FhirSearchTokens (ResourceType, ResourceId, ParamCode, System, Value)
    SELECT @ResourceType, @ResourceId, N'name', NULL, LOWER(LTRIM(RTRIM(n.family)))
    FROM OPENJSON(@json, '$.name') WITH (family NVARCHAR(200) '$.family') AS n
    WHERE n.family IS NOT NULL AND LTRIM(RTRIM(n.family)) <> N'';

    INSERT INTO dbo.FhirSearchTokens (ResourceType, ResourceId, ParamCode, System, Value)
    SELECT @ResourceType, @ResourceId, N'name', NULL, LOWER(LTRIM(RTRIM(g.value)))
    FROM OPENJSON(@json, '$.name') AS n
    CROSS APPLY OPENJSON(n.value, '$.given') AS g
    WHERE g.value IS NOT NULL AND LTRIM(RTRIM(g.value)) <> N'';

    INSERT INTO dbo.FhirSearchTokens (ResourceType, ResourceId, ParamCode, System, Value)
    SELECT @ResourceType, @ResourceId, N'identifier', id.system,
           LOWER(LTRIM(RTRIM(id.value)))
    FROM OPENJSON(@json, '$.identifier')
      WITH (system NVARCHAR(256) '$.system', value NVARCHAR(200) '$.value') AS id
    WHERE id.value IS NOT NULL AND LTRIM(RTRIM(id.value)) <> N'';

    INSERT INTO dbo.FhirSearchTokens (ResourceType, ResourceId, ParamCode, System, Value)
    SELECT @ResourceType, @ResourceId, N'identifier', id.system,
           LOWER(CASE WHEN id.system IS NULL OR id.system = N'' THEN id.value
                      ELSE id.system + N'|' + id.value END)
    FROM OPENJSON(@json, '$.identifier')
      WITH (system NVARCHAR(256) '$.system', value NVARCHAR(200) '$.value') AS id
    WHERE id.value IS NOT NULL AND LTRIM(RTRIM(id.value)) <> N''
      AND id.system IS NOT NULL AND LTRIM(RTRIM(id.system)) <> N'';
  END

  IF @ResourceType = N'Patient'
  BEGIN
    INSERT INTO dbo.FhirSearchTokens (ResourceType, ResourceId, ParamCode, System, Value)
    SELECT @ResourceType, @ResourceId, N'gender', NULL, LOWER(LTRIM(RTRIM(JSON_VALUE(@json, '$.gender'))))
    WHERE JSON_VALUE(@json, '$.gender') IS NOT NULL;

    INSERT INTO dbo.FhirSearchTokens (ResourceType, ResourceId, ParamCode, System, Value)
    SELECT @ResourceType, @ResourceId, N'birthdate', NULL, LTRIM(RTRIM(JSON_VALUE(@json, '$.birthDate')))
    WHERE JSON_VALUE(@json, '$.birthDate') IS NOT NULL;
  END

  /* --- Organization --- */
  IF @ResourceType = N'Organization'
  BEGIN
    INSERT INTO dbo.FhirSearchTokens (ResourceType, ResourceId, ParamCode, System, Value)
    SELECT @ResourceType, @ResourceId, N'name', NULL, LOWER(LTRIM(RTRIM(JSON_VALUE(@json, '$.name'))))
    WHERE JSON_VALUE(@json, '$.name') IS NOT NULL;

    INSERT INTO dbo.FhirSearchTokens (ResourceType, ResourceId, ParamCode, System, Value)
    SELECT @ResourceType, @ResourceId, N'active', NULL,
           LOWER(CASE WHEN JSON_VALUE(@json, '$.active') IN (N'true', N'1') THEN N'true'
                      WHEN JSON_VALUE(@json, '$.active') IN (N'false', N'0') THEN N'false'
                      ELSE LTRIM(RTRIM(JSON_VALUE(@json, '$.active'))) END)
    WHERE JSON_VALUE(@json, '$.active') IS NOT NULL;

    INSERT INTO dbo.FhirSearchTokens (ResourceType, ResourceId, ParamCode, System, Value)
    SELECT @ResourceType, @ResourceId, N'identifier', id.system, LOWER(LTRIM(RTRIM(id.value)))
    FROM OPENJSON(@json, '$.identifier')
      WITH (system NVARCHAR(256) '$.system', value NVARCHAR(200) '$.value') AS id
    WHERE id.value IS NOT NULL AND LTRIM(RTRIM(id.value)) <> N'';

    INSERT INTO dbo.FhirSearchTokens (ResourceType, ResourceId, ParamCode, System, Value)
    SELECT @ResourceType, @ResourceId, N'identifier', id.system,
           LOWER(id.system + N'|' + id.value)
    FROM OPENJSON(@json, '$.identifier')
      WITH (system NVARCHAR(256) '$.system', value NVARCHAR(200) '$.value') AS id
    WHERE id.value IS NOT NULL AND id.system IS NOT NULL
      AND LTRIM(RTRIM(id.system)) <> N'' AND LTRIM(RTRIM(id.value)) <> N'';
  END

  /* --- Observation / Encounter / Condition shared clinical bits --- */
  IF @ResourceType IN (N'Observation', N'Encounter', N'Condition')
  BEGIN
    DECLARE @subj NVARCHAR(200) = JSON_VALUE(@json, '$.subject.reference');
    IF @subj IS NOT NULL AND LTRIM(RTRIM(@subj)) <> N''
    BEGIN
      INSERT INTO dbo.FhirSearchTokens (ResourceType, ResourceId, ParamCode, System, Value)
      VALUES (@ResourceType, @ResourceId, N'patient', NULL, LOWER(LTRIM(RTRIM(@subj))));

      IF @subj LIKE N'Patient/%'
        INSERT INTO dbo.FhirSearchTokens (ResourceType, ResourceId, ParamCode, System, Value)
        VALUES (@ResourceType, @ResourceId, N'patient', NULL,
                LOWER(LTRIM(RTRIM(SUBSTRING(@subj, 9, 400)))));
    END
  END

  IF @ResourceType = N'Observation'
  BEGIN
    INSERT INTO dbo.FhirSearchTokens (ResourceType, ResourceId, ParamCode, System, Value)
    SELECT @ResourceType, @ResourceId, N'status', NULL, LOWER(LTRIM(RTRIM(JSON_VALUE(@json, '$.status'))))
    WHERE JSON_VALUE(@json, '$.status') IS NOT NULL;

    INSERT INTO dbo.FhirSearchTokens (ResourceType, ResourceId, ParamCode, System, Value)
    SELECT @ResourceType, @ResourceId, N'date', NULL, LTRIM(RTRIM(JSON_VALUE(@json, '$.effectiveDateTime')))
    WHERE JSON_VALUE(@json, '$.effectiveDateTime') IS NOT NULL;

    INSERT INTO dbo.FhirSearchTokens (ResourceType, ResourceId, ParamCode, System, Value)
    SELECT @ResourceType, @ResourceId, N'date', NULL, LTRIM(RTRIM(JSON_VALUE(@json, '$.effectivePeriod.start')))
    WHERE JSON_VALUE(@json, '$.effectivePeriod.start') IS NOT NULL;

    INSERT INTO dbo.FhirSearchTokens (ResourceType, ResourceId, ParamCode, System, Value)
    SELECT @ResourceType, @ResourceId, N'code', c.system, LOWER(LTRIM(RTRIM(c.code)))
    FROM OPENJSON(@json, '$.code.coding')
      WITH (system NVARCHAR(256) '$.system', code NVARCHAR(200) '$.code') AS c
    WHERE c.code IS NOT NULL AND LTRIM(RTRIM(c.code)) <> N'';

    INSERT INTO dbo.FhirSearchTokens (ResourceType, ResourceId, ParamCode, System, Value)
    SELECT @ResourceType, @ResourceId, N'code', c.system, LOWER(c.system + N'|' + c.code)
    FROM OPENJSON(@json, '$.code.coding')
      WITH (system NVARCHAR(256) '$.system', code NVARCHAR(200) '$.code') AS c
    WHERE c.code IS NOT NULL AND c.system IS NOT NULL
      AND LTRIM(RTRIM(c.system)) <> N'' AND LTRIM(RTRIM(c.code)) <> N'';

    INSERT INTO dbo.FhirSearchTokens (ResourceType, ResourceId, ParamCode, System, Value)
    SELECT @ResourceType, @ResourceId, N'category', cat.system, LOWER(LTRIM(RTRIM(cat.code)))
    FROM OPENJSON(@json, '$.category') AS catArr
    CROSS APPLY OPENJSON(catArr.value, '$.coding')
      WITH (system NVARCHAR(256) '$.system', code NVARCHAR(200) '$.code') AS cat
    WHERE cat.code IS NOT NULL AND LTRIM(RTRIM(cat.code)) <> N'';
  END

  IF @ResourceType = N'Encounter'
  BEGIN
    INSERT INTO dbo.FhirSearchTokens (ResourceType, ResourceId, ParamCode, System, Value)
    SELECT @ResourceType, @ResourceId, N'status', NULL, LOWER(LTRIM(RTRIM(JSON_VALUE(@json, '$.status'))))
    WHERE JSON_VALUE(@json, '$.status') IS NOT NULL;

    INSERT INTO dbo.FhirSearchTokens (ResourceType, ResourceId, ParamCode, System, Value)
    SELECT @ResourceType, @ResourceId, N'date', NULL, LTRIM(RTRIM(JSON_VALUE(@json, '$.period.start')))
    WHERE JSON_VALUE(@json, '$.period.start') IS NOT NULL;

    INSERT INTO dbo.FhirSearchTokens (ResourceType, ResourceId, ParamCode, System, Value)
    SELECT @ResourceType, @ResourceId, N'class', NULL, LOWER(LTRIM(RTRIM(JSON_VALUE(@json, '$.class.code'))))
    WHERE JSON_VALUE(@json, '$.class.code') IS NOT NULL;
  END

  IF @ResourceType = N'Condition'
  BEGIN
    INSERT INTO dbo.FhirSearchTokens (ResourceType, ResourceId, ParamCode, System, Value)
    SELECT @ResourceType, @ResourceId, N'clinical-status', NULL,
           LOWER(LTRIM(RTRIM(COALESCE(
             JSON_VALUE(@json, '$.clinicalStatus.coding[0].code'),
             JSON_VALUE(@json, '$.clinicalStatus.text')))))
    WHERE COALESCE(
            JSON_VALUE(@json, '$.clinicalStatus.coding[0].code'),
            JSON_VALUE(@json, '$.clinicalStatus.text')) IS NOT NULL;

    INSERT INTO dbo.FhirSearchTokens (ResourceType, ResourceId, ParamCode, System, Value)
    SELECT @ResourceType, @ResourceId, N'onset-date', NULL, LTRIM(RTRIM(JSON_VALUE(@json, '$.onsetDateTime')))
    WHERE JSON_VALUE(@json, '$.onsetDateTime') IS NOT NULL;

    INSERT INTO dbo.FhirSearchTokens (ResourceType, ResourceId, ParamCode, System, Value)
    SELECT @ResourceType, @ResourceId, N'code', c.system, LOWER(LTRIM(RTRIM(c.code)))
    FROM OPENJSON(@json, '$.code.coding')
      WITH (system NVARCHAR(256) '$.system', code NVARCHAR(200) '$.code') AS c
    WHERE c.code IS NOT NULL AND LTRIM(RTRIM(c.code)) <> N'';

    INSERT INTO dbo.FhirSearchTokens (ResourceType, ResourceId, ParamCode, System, Value)
    SELECT @ResourceType, @ResourceId, N'code', c.system, LOWER(c.system + N'|' + c.code)
    FROM OPENJSON(@json, '$.code.coding')
      WITH (system NVARCHAR(256) '$.system', code NVARCHAR(200) '$.code') AS c
    WHERE c.code IS NOT NULL AND c.system IS NOT NULL
      AND LTRIM(RTRIM(c.system)) <> N'' AND LTRIM(RTRIM(c.code)) <> N'';
  END
END
GO

CREATE OR ALTER PROCEDURE dbo.FhirSearchResources
  @ResourceType NVARCHAR(64),
  @_id NVARCHAR(128) = NULL,
  @identifier NVARCHAR(400) = NULL,
  @family NVARCHAR(200) = NULL,
  @given NVARCHAR(200) = NULL,
  @name NVARCHAR(200) = NULL,
  @gender NVARCHAR(32) = NULL,
  @birthdate NVARCHAR(64) = NULL,
  @patient NVARCHAR(200) = NULL,
  @code NVARCHAR(400) = NULL,
  @date NVARCHAR(64) = NULL,
  @status NVARCHAR(64) = NULL,
  @category NVARCHAR(200) = NULL,
  @class NVARCHAR(64) = NULL,
  @clinicalStatus NVARCHAR(64) = NULL,
  @onsetDate NVARCHAR(64) = NULL,
  @active NVARCHAR(16) = NULL,
  @q NVARCHAR(200) = NULL
AS
BEGIN
  SET NOCOUNT ON;

  ;WITH Base AS (
    SELECT r.ResourceType, r.ResourceId, r.RawFhir, r.UpdatedAt
    FROM dbo.FhirResources r
    WHERE r.ResourceType = @ResourceType
      AND r.DeletedAt IS NULL
      AND (
        @_id IS NULL OR LTRIM(RTRIM(@_id)) = N''
        OR r.ResourceId = LTRIM(RTRIM(@_id))
      )
      AND (
        @q IS NULL OR LTRIM(RTRIM(@q)) = N''
        OR r.RawFhir LIKE N'%' + LTRIM(RTRIM(@q)) + N'%'
      )
  )
  SELECT TOP 50 b.ResourceType, b.ResourceId, b.RawFhir
  FROM Base b
  WHERE
    (
      @identifier IS NULL OR LTRIM(RTRIM(@identifier)) = N''
      OR EXISTS (
        SELECT 1 FROM dbo.FhirSearchTokens t
        WHERE t.ResourceType = b.ResourceType AND t.ResourceId = b.ResourceId
          AND t.ParamCode = N'identifier'
          AND t.Value = LOWER(LTRIM(RTRIM(@identifier)))
      )
    )
    AND (
      @family IS NULL OR LTRIM(RTRIM(@family)) = N''
      OR EXISTS (
        SELECT 1 FROM dbo.FhirSearchTokens t
        WHERE t.ResourceType = b.ResourceType AND t.ResourceId = b.ResourceId
          AND t.ParamCode = N'family'
          AND t.Value LIKE LOWER(LTRIM(RTRIM(@family))) + N'%'
      )
    )
    AND (
      @given IS NULL OR LTRIM(RTRIM(@given)) = N''
      OR EXISTS (
        SELECT 1 FROM dbo.FhirSearchTokens t
        WHERE t.ResourceType = b.ResourceType AND t.ResourceId = b.ResourceId
          AND t.ParamCode = N'given'
          AND t.Value LIKE LOWER(LTRIM(RTRIM(@given))) + N'%'
      )
    )
    AND (
      @name IS NULL OR LTRIM(RTRIM(@name)) = N''
      OR EXISTS (
        SELECT 1 FROM dbo.FhirSearchTokens t
        WHERE t.ResourceType = b.ResourceType AND t.ResourceId = b.ResourceId
          AND t.ParamCode = N'name'
          AND t.Value LIKE N'%' + LOWER(LTRIM(RTRIM(@name))) + N'%'
      )
    )
    AND (
      @gender IS NULL OR LTRIM(RTRIM(@gender)) = N''
      OR EXISTS (
        SELECT 1 FROM dbo.FhirSearchTokens t
        WHERE t.ResourceType = b.ResourceType AND t.ResourceId = b.ResourceId
          AND t.ParamCode = N'gender'
          AND t.Value = LOWER(LTRIM(RTRIM(@gender)))
      )
    )
    AND (
      @birthdate IS NULL OR LTRIM(RTRIM(@birthdate)) = N''
      OR EXISTS (
        SELECT 1 FROM dbo.FhirSearchTokens t
        WHERE t.ResourceType = b.ResourceType AND t.ResourceId = b.ResourceId
          AND t.ParamCode = N'birthdate'
          AND t.Value LIKE LTRIM(RTRIM(@birthdate)) + N'%'
      )
    )
    AND (
      @patient IS NULL OR LTRIM(RTRIM(@patient)) = N''
      OR EXISTS (
        SELECT 1 FROM dbo.FhirSearchTokens t
        WHERE t.ResourceType = b.ResourceType AND t.ResourceId = b.ResourceId
          AND t.ParamCode = N'patient'
          AND t.Value = LOWER(LTRIM(RTRIM(@patient)))
      )
    )
    AND (
      @code IS NULL OR LTRIM(RTRIM(@code)) = N''
      OR EXISTS (
        SELECT 1 FROM dbo.FhirSearchTokens t
        WHERE t.ResourceType = b.ResourceType AND t.ResourceId = b.ResourceId
          AND t.ParamCode = N'code'
          AND t.Value = LOWER(LTRIM(RTRIM(@code)))
      )
    )
    AND (
      @date IS NULL OR LTRIM(RTRIM(@date)) = N''
      OR EXISTS (
        SELECT 1 FROM dbo.FhirSearchTokens t
        WHERE t.ResourceType = b.ResourceType AND t.ResourceId = b.ResourceId
          AND t.ParamCode = N'date'
          AND t.Value LIKE LTRIM(RTRIM(@date)) + N'%'
      )
    )
    AND (
      @status IS NULL OR LTRIM(RTRIM(@status)) = N''
      OR EXISTS (
        SELECT 1 FROM dbo.FhirSearchTokens t
        WHERE t.ResourceType = b.ResourceType AND t.ResourceId = b.ResourceId
          AND t.ParamCode = N'status'
          AND t.Value = LOWER(LTRIM(RTRIM(@status)))
      )
    )
    AND (
      @category IS NULL OR LTRIM(RTRIM(@category)) = N''
      OR EXISTS (
        SELECT 1 FROM dbo.FhirSearchTokens t
        WHERE t.ResourceType = b.ResourceType AND t.ResourceId = b.ResourceId
          AND t.ParamCode = N'category'
          AND t.Value = LOWER(LTRIM(RTRIM(@category)))
      )
    )
    AND (
      @class IS NULL OR LTRIM(RTRIM(@class)) = N''
      OR EXISTS (
        SELECT 1 FROM dbo.FhirSearchTokens t
        WHERE t.ResourceType = b.ResourceType AND t.ResourceId = b.ResourceId
          AND t.ParamCode = N'class'
          AND t.Value = LOWER(LTRIM(RTRIM(@class)))
      )
    )
    AND (
      @clinicalStatus IS NULL OR LTRIM(RTRIM(@clinicalStatus)) = N''
      OR EXISTS (
        SELECT 1 FROM dbo.FhirSearchTokens t
        WHERE t.ResourceType = b.ResourceType AND t.ResourceId = b.ResourceId
          AND t.ParamCode = N'clinical-status'
          AND t.Value = LOWER(LTRIM(RTRIM(@clinicalStatus)))
      )
    )
    AND (
      @onsetDate IS NULL OR LTRIM(RTRIM(@onsetDate)) = N''
      OR EXISTS (
        SELECT 1 FROM dbo.FhirSearchTokens t
        WHERE t.ResourceType = b.ResourceType AND t.ResourceId = b.ResourceId
          AND t.ParamCode = N'onset-date'
          AND t.Value LIKE LTRIM(RTRIM(@onsetDate)) + N'%'
      )
    )
    AND (
      @active IS NULL OR LTRIM(RTRIM(@active)) = N''
      OR EXISTS (
        SELECT 1 FROM dbo.FhirSearchTokens t
        WHERE t.ResourceType = b.ResourceType AND t.ResourceId = b.ResourceId
          AND t.ParamCode = N'active'
          AND t.Value = LOWER(LTRIM(RTRIM(@active)))
      )
    )
  ORDER BY b.UpdatedAt DESC;
END
GO

/* Backfill tokens for any existing non-deleted resources */
DECLARE @t NVARCHAR(64), @id NVARCHAR(128);
DECLARE c CURSOR LOCAL FAST_FORWARD FOR
  SELECT ResourceType, ResourceId FROM dbo.FhirResources WHERE DeletedAt IS NULL;
OPEN c;
FETCH NEXT FROM c INTO @t, @id;
WHILE @@FETCH_STATUS = 0
BEGIN
  EXEC dbo.FhirReindexResource @t, @id;
  FETCH NEXT FROM c INTO @t, @id;
END
CLOSE c;
DEALLOCATE c;
GO
