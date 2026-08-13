-- FHIR R4 Platform Phase 3 — transaction + batch Bundle execution
USE FhirR4PlatformDemo;
GO

CREATE OR ALTER PROCEDURE dbo.FhirExecuteBundle
  @BundleJson NVARCHAR(MAX)
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  DECLARE @bundleType NVARCHAR(64) = LOWER(LTRIM(RTRIM(JSON_VALUE(@BundleJson, '$.type'))));
  DECLARE @resourceType NVARCHAR(64) = JSON_VALUE(@BundleJson, '$.resourceType');
  DECLARE @httpStatus INT = 200;
  DECLARE @responseJson NVARCHAR(MAX);
  DECLARE @isTxn BIT = CASE WHEN @bundleType = N'transaction' THEN 1 ELSE 0 END;
  DECLARE @respType NVARCHAR(64) = CASE WHEN @isTxn = 1 THEN N'transaction-response' ELSE N'batch-response' END;

  IF @resourceType <> N'Bundle' OR @bundleType NOT IN (N'transaction', N'batch')
  BEGIN
    SELECT 400 AS HttpStatus,
      N'{"resourceType":"OperationOutcome","issue":[{"severity":"error","code":"invalid","diagnostics":"Expected Bundle with type transaction or batch."}]}' AS RawFhir;
    RETURN;
  END

  DECLARE @entries TABLE (
    Idx INT IDENTITY(1,1) PRIMARY KEY,
    Method NVARCHAR(16) NOT NULL,
    Url NVARCHAR(400) NOT NULL,
    ResourceJson NVARCHAR(MAX) NULL,
    StatusCode INT NULL,
    StatusText NVARCHAR(80) NULL,
    Location NVARCHAR(400) NULL,
    RespBody NVARCHAR(MAX) NULL,
    Failed BIT NOT NULL DEFAULT (0)
  );

  INSERT INTO @entries (Method, Url, ResourceJson)
  SELECT
    UPPER(LTRIM(RTRIM(JSON_VALUE(e.value, '$.request.method')))),
    LTRIM(RTRIM(JSON_VALUE(e.value, '$.request.url'))),
    JSON_QUERY(e.value, '$.resource')
  FROM OPENJSON(@BundleJson, '$.entry') AS e;

  IF NOT EXISTS (SELECT 1 FROM @entries)
  BEGIN
    SELECT 400 AS HttpStatus,
      N'{"resourceType":"OperationOutcome","issue":[{"severity":"error","code":"invalid","diagnostics":"Bundle.entry is empty."}]}' AS RawFhir;
    RETURN;
  END

  IF (SELECT COUNT(*) FROM @entries) > 25
  BEGIN
    SELECT 400 AS HttpStatus,
      N'{"resourceType":"OperationOutcome","issue":[{"severity":"error","code":"too-costly","diagnostics":"Phase 3 demo limit is 25 Bundle entries."}]}' AS RawFhir;
    RETURN;
  END

  BEGIN TRY
    IF @isTxn = 1 BEGIN TRANSACTION;

    DECLARE @i INT = 1, @n INT = (SELECT MAX(Idx) FROM @entries);
    DECLARE @method NVARCHAR(16), @url NVARCHAR(400), @res NVARCHAR(MAX);
    DECLARE @path NVARCHAR(400), @qpos INT, @seg1 NVARCHAR(128), @seg2 NVARCHAR(128);
    DECLARE @slash INT, @rtype NVARCHAR(64), @rid NVARCHAR(128);
    DECLARE @found NVARCHAR(MAX);
    DECLARE @failDiag NVARCHAR(400);

    WHILE @i <= @n
    BEGIN
      SELECT @method = Method, @url = Url, @res = ResourceJson FROM @entries WHERE Idx = @i;
      SET @failDiag = NULL;
      SET @path = @url;
      SET @qpos = CHARINDEX(N'?', @path);
      IF @qpos > 0 SET @path = LEFT(@path, @qpos - 1);
      IF LEFT(@path, 1) = N'/' SET @path = SUBSTRING(@path, 2, 400);
      SET @slash = CHARINDEX(N'/', @path);
      IF @slash = 0
      BEGIN
        SET @seg1 = @path; SET @seg2 = NULL;
      END
      ELSE
      BEGIN
        SET @seg1 = LEFT(@path, @slash - 1);
        SET @seg2 = SUBSTRING(@path, @slash + 1, 400);
        IF CHARINDEX(N'/', @seg2) > 0 SET @seg2 = LEFT(@seg2, CHARINDEX(N'/', @seg2) - 1);
      END
      SET @rtype = @seg1;
      SET @rid = @seg2;

      IF @method IS NULL OR @method = N'' OR @rtype IS NULL OR @rtype = N''
      BEGIN
        SET @failDiag = N'Missing request.method or request.url resource type.';
      END
      ELSE IF @method = N'GET' AND (@rid IS NULL OR @rid = N'')
      BEGIN
        SET @failDiag = N'Phase 3 supports GET Type/id only (no search inside Bundle).';
      END
      ELSE IF @method IN (N'POST', N'PUT') AND (@res IS NULL OR LTRIM(RTRIM(@res)) = N'')
      BEGIN
        SET @failDiag = N'POST/PUT entry requires resource.';
      END
      ELSE IF @method = N'POST'
      BEGIN
        IF JSON_VALUE(@res, '$.resourceType') IS NULL OR JSON_VALUE(@res, '$.resourceType') <> @rtype
          SET @failDiag = N'resource.resourceType must match URL type for POST.';
        ELSE IF JSON_VALUE(@res, '$.id') IS NULL OR LTRIM(RTRIM(JSON_VALUE(@res, '$.id'))) = N''
          SET @failDiag = N'Phase 3 requires resource.id on POST entries.';
        ELSE
          SET @rid = LTRIM(RTRIM(JSON_VALUE(@res, '$.id')));
      END
      ELSE IF @method = N'PUT'
      BEGIN
        IF @rid IS NULL OR @rid = N''
          SET @failDiag = N'PUT requires Type/id URL.';
        ELSE IF JSON_VALUE(@res, '$.resourceType') IS NULL OR JSON_VALUE(@res, '$.resourceType') <> @rtype
          SET @failDiag = N'resource.resourceType must match URL type for PUT.';
        ELSE
        BEGIN
          -- force id from URL
          SET @res = JSON_MODIFY(@res, '$.id', @rid);
        END
      END
      ELSE IF @method = N'DELETE'
      BEGIN
        IF @rid IS NULL OR @rid = N''
          SET @failDiag = N'DELETE requires Type/id URL.';
      END
      ELSE IF @method <> N'GET'
      BEGIN
        SET @failDiag = N'Unsupported method in Bundle entry (use GET/POST/PUT/DELETE).';
      END

      IF @failDiag IS NOT NULL
      BEGIN
        IF @isTxn = 1
          THROW 50001, @failDiag, 1;

        UPDATE @entries SET
          Failed = 1,
          StatusCode = 400,
          StatusText = N'400 Bad Request',
          RespBody = N'{"resourceType":"OperationOutcome","issue":[{"severity":"error","code":"invalid","diagnostics":"'
            + REPLACE(REPLACE(@failDiag, N'\', N'\\'), N'"', N'\"') + N'"}]}'
        WHERE Idx = @i;
      END
      ELSE IF @method IN (N'POST', N'PUT')
      BEGIN
        MERGE dbo.FhirResources AS t
        USING (SELECT @rtype AS ResourceType, @rid AS ResourceId, @res AS RawFhir) AS s
        ON t.ResourceType = s.ResourceType AND t.ResourceId = s.ResourceId
        WHEN MATCHED THEN UPDATE SET
          RawFhir = s.RawFhir, ValidationStatus = N'PASS', SourceCode = N'BUNDLE', Source = N'local',
          DeletedAt = NULL, UpdatedAt = SYSUTCDATETIME()
        WHEN NOT MATCHED THEN INSERT
          (SourceCode, ResourceType, ResourceId, PatientId, PatientName, IsBundle, ValidationStatus, SourceFile, RawFhir, Source)
          VALUES (N'BUNDLE', s.ResourceType, s.ResourceId, N'', N'',
            CASE WHEN s.ResourceType = N'Bundle' THEN 1 ELSE 0 END, N'PASS', N'bundle', s.RawFhir, N'local');

        EXEC dbo.FhirReindexResource @rtype, @rid;

        UPDATE @entries SET
          StatusCode = CASE WHEN @method = N'POST' THEN 201 ELSE 200 END,
          StatusText = CASE WHEN @method = N'POST' THEN N'201 Created' ELSE N'200 OK' END,
          Location = @rtype + N'/' + @rid,
          RespBody = @res
        WHERE Idx = @i;
      END
      ELSE IF @method = N'DELETE'
      BEGIN
        UPDATE dbo.FhirResources
        SET DeletedAt = SYSUTCDATETIME(), UpdatedAt = SYSUTCDATETIME()
        WHERE ResourceType = @rtype AND ResourceId = @rid AND DeletedAt IS NULL;

        DELETE FROM dbo.FhirSearchTokens WHERE ResourceType = @rtype AND ResourceId = @rid;

        UPDATE @entries SET
          StatusCode = 200,
          StatusText = N'200 OK',
          RespBody = N'{"resourceType":"OperationOutcome","issue":[{"severity":"information","code":"informational","diagnostics":"Resource soft-deleted."}]}'
        WHERE Idx = @i;
      END
      ELSE IF @method = N'GET'
      BEGIN
        SELECT @found = RawFhir FROM dbo.FhirResources
        WHERE ResourceType = @rtype AND ResourceId = @rid AND DeletedAt IS NULL;

        IF @found IS NULL
        BEGIN
          IF @isTxn = 1
            THROW 50002, N'Resource not found during transaction GET.', 1;

          UPDATE @entries SET
            Failed = 1,
            StatusCode = 404,
            StatusText = N'404 Not Found',
            RespBody = N'{"resourceType":"OperationOutcome","issue":[{"severity":"error","code":"not-found","diagnostics":"Resource not found for the requested type/id."}]}'
          WHERE Idx = @i;
        END
        ELSE
        BEGIN
          UPDATE @entries SET
            StatusCode = 200,
            StatusText = N'200 OK',
            Location = @rtype + N'/' + @rid,
            RespBody = @found
          WHERE Idx = @i;
        END
      END

      SET @i += 1;
    END

    IF @isTxn = 1 AND XACT_STATE() = 1 COMMIT TRANSACTION;

    -- Build response Bundle JSON
    DECLARE @parts NVARCHAR(MAX) = N'';
    SELECT @parts = @parts + CASE WHEN @parts = N'' THEN N'' ELSE N',' END +
      N'{"response":{"status":"' + StatusText + N'"'
      + CASE WHEN Location IS NOT NULL THEN N',"location":"' + Location + N'"' ELSE N'' END
      + N'}'
      + CASE WHEN RespBody IS NOT NULL THEN N',"resource":' + RespBody ELSE N'' END
      + N'}'
    FROM @entries
    ORDER BY Idx;

    SET @responseJson =
      N'{"resourceType":"Bundle","type":"' + @respType + N'","entry":[' + @parts + N']}';
    SET @httpStatus = 200;
  END TRY
  BEGIN CATCH
    IF @isTxn = 1 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;

    DECLARE @err NVARCHAR(400) = ERROR_MESSAGE();
    SET @httpStatus = 400;
    SET @responseJson =
      N'{"resourceType":"OperationOutcome","issue":[{"severity":"error","code":"processing","diagnostics":"Transaction failed: '
      + REPLACE(REPLACE(@err, N'\', N'\\'), N'"', N'\"') + N'"}]}';
  END CATCH

  SELECT @httpStatus AS HttpStatus, @responseJson AS RawFhir;
END
GO
