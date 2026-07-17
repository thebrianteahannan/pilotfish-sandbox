<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:err="http://www.pilotfishtechnology.com/eip/RouteErrorReport" version="3.1">
  <xsl:template match="/">
    <ErrorReport>
      <FileUploadError>
        <FileName>
          <xsl:value-of select="concat(//err:transactionAttributes[@name='FileName'],'.',//err:transactionAttributes[@name='FileExtension'])" />
        </FileName>
        <ErrorText>
          <xsl:value-of select="//err:transactionAttributes[@name='SyncResponseError']" />
        </ErrorText>
        <FacilityName_ShouldBe>
          <xsl:value-of select="//err:transactionAttributes[@name='FacilityNameShouldBe']" />
        </FacilityName_ShouldBe>
        <FacilityName_InFile>
          <xsl:value-of select="//err:transactionAttributes[@name='FacilityNameFromFile']" />
        </FacilityName_InFile>
        <Partition>
          <xsl:value-of select="//err:transactionAttributes[@name='Partition']" />
        </Partition>
        <Client>
          <xsl:value-of select="//err:transactionAttributes[@name='Client']" />
        </Client>
        <ErrorRoute>
          <xsl:value-of select="//err:errorRoute" />
        </ErrorRoute>
        <ErrorComponent>
          <xsl:value-of select="//err:errorComponent" />
        </ErrorComponent>
        <ErrorStage>
          <xsl:value-of select="//err:errorStage" />
        </ErrorStage>
      </FileUploadError>
    </ErrorReport>
  </xsl:template>
</xsl:stylesheet>

