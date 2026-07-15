<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ns1="http://pilotfish.sqlxml" version="3.1">
  <xsl:template match="XCSExcelBook">
    <ns1:SQLXML>
      <xsl:for-each select="XCSExcelSheet/XCSExcelRow[string-length(SOFTWAREID) &gt; 0 and string-length(CLIENT) &gt; 0 and string-length(FACILITY) &gt; 0 and string-length(FACILITY_CODE) &gt; 0]">
        <ns1:Insert>
          <FACILITY_SPLITS_88363>
            <SOFTWAREID>
              <xsl:value-of select="SOFTWAREID" />
            </SOFTWAREID>
            <CLIENTNAME>
              <xsl:value-of select="CLIENTNAME" />
            </CLIENTNAME>
            <LOG_NAME>
              <xsl:value-of select="C_88363_Log_Name" />
            </LOG_NAME>
            <PARTITION>
              <xsl:value-of select="PARTITION" />
            </PARTITION>
            <CLIENT>
              <xsl:value-of select="CLIENT" />
            </CLIENT>
            <FACILITY>
              <xsl:value-of select="FACILITY" />
            </FACILITY>
            <FACILITY_CODE_88363>
              <xsl:value-of select="C_88363_Facility_Code" />
            </FACILITY_CODE_88363>
            <FACILITY_CODE>
              <xsl:value-of select="FACILITY_CODE" />
            </FACILITY_CODE>
            <DEFAULT_PERF_DR>
              <xsl:value-of select="DEFAULT_PERF_DR" />
            </DEFAULT_PERF_DR>
            <ACCOUNT_NUM_ALPHA>
              <xsl:value-of select="ACCOUNT_NUM_ALPHA" />
            </ACCOUNT_NUM_ALPHA>
            <DATE_RANGE>
              <xsl:value-of select="DATE_RANGE" />
            </DATE_RANGE>
            <IS_DEFAULT>
              <xsl:value-of select="IS_DEFAULT" />
            </IS_DEFAULT>
          </FACILITY_SPLITS_88363>
        </ns1:Insert>
      </xsl:for-each>
    </ns1:SQLXML>
  </xsl:template>
</xsl:stylesheet>

