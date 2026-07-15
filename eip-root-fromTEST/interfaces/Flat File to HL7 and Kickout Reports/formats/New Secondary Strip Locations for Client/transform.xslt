<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ns1="http://pilotfish.sqlxml" version="3.1">
  <xsl:template match="XCSExcelBook">
    <ns1:SQLXML>
      <xsl:variable name="SoftwareID" select="XCSExcelSheet/XCSExcelRow[1]/SOFTWAREID" />
      <xsl:for-each select="XCSExcelSheet/XCSExcelRow[string-length(STRIP_PRIMARY_LOCATION_CODE) &gt; 0 and string-length(STRIP_SECONDARY_LOCATION_CODE) &gt; 0]">
        <ns1:Insert>
          <STRIP_LOCATIONS>
            <LOCATION>
              <xsl:value-of select="STRIP_PRIMARY_LOCATION_CODE" />
            </LOCATION>
            <LOCATION2>
              <xsl:value-of select="STRIP_SECONDARY_LOCATION_CODE" />
            </LOCATION2>
            <SOFTWARE_ID>
              <xsl:value-of select="$SoftwareID" />
            </SOFTWARE_ID>
          </STRIP_LOCATIONS>
        </ns1:Insert>
      </xsl:for-each>
    </ns1:SQLXML>
  </xsl:template>
</xsl:stylesheet>

