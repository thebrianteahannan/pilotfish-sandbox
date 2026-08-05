-- FHIR R4 Platform Phase 6 — PF Bulk export helpers (no custom Java)
USE FhirR4PlatformDemo;
GO

CREATE OR ALTER PROCEDURE dbo.FhirBulkSelectNdjsonByJob
  @JobId NVARCHAR(64)
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @TypesCsv NVARCHAR(400);
  SELECT @TypesCsv = TypesCsv FROM dbo.FhirExportJobs WHERE JobId = @JobId;

  IF NOT EXISTS (SELECT 1 FROM dbo.FhirExportJobs WHERE JobId = @JobId)
  BEGIN
    SELECT CAST(NULL AS NVARCHAR(64)) AS ResourceType,
           CAST(NULL AS NVARCHAR(MAX)) AS NdjsonBody,
           CAST(0 AS INT) AS ResourceCount
    WHERE 1 = 0;
    RETURN;
  END

  SELECT
    r.ResourceType,
    STRING_AGG(
      CAST(
        REPLACE(REPLACE(REPLACE(r.RawFhir, CHAR(13), N' '), CHAR(10), N' '), CHAR(9), N' ')
        AS NVARCHAR(MAX)
      ),
      CHAR(10)
    ) WITHIN GROUP (ORDER BY r.ResourceId) AS NdjsonBody,
    COUNT_BIG(*) AS ResourceCount
  FROM dbo.FhirResources r
  WHERE r.DeletedAt IS NULL
    AND (
      @TypesCsv IS NULL
      OR LTRIM(RTRIM(@TypesCsv)) = N''
      OR EXISTS (
        SELECT 1
        FROM STRING_SPLIT(@TypesCsv, N',') AS s
        WHERE LTRIM(RTRIM(s.value)) = r.ResourceType
      )
    )
  GROUP BY r.ResourceType
  ORDER BY r.ResourceType;
END
GO

CREATE OR ALTER PROCEDURE dbo.FhirBulkUpdateJobStatus
  @JobId NVARCHAR(64),
  @Status NVARCHAR(32),
  @Manifest NVARCHAR(MAX) = NULL,
  @ErrorText NVARCHAR(MAX) = NULL
AS
BEGIN
  SET NOCOUNT ON;
  UPDATE dbo.FhirExportJobs
  SET Status = @Status,
      OutputManifest = COALESCE(@Manifest, OutputManifest),
      ErrorText = @ErrorText,
      UpdatedAt = SYSUTCDATETIME(),
      CompletedAt = CASE
        WHEN @Status IN (N'completed', N'error') THEN SYSUTCDATETIME()
        ELSE CompletedAt
      END
  WHERE JobId = @JobId;

  -- Return a row so PilotFish DatabaseSqlProcessor (executeQuery path) succeeds.
  SELECT JobId, Status FROM dbo.FhirExportJobs WHERE JobId = @JobId;
END
GO
