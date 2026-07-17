<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ns1="http://pilotfish.sqlxml" version="3.1">
  <xsl:template match="XCSExcelBook">
    <ns1:SQLXML>
      <xsl:variable name="SoftwareID" select="XCSExcelSheet/XCSExcelRow[1]/SOFTWAREID" />
      <xsl:variable name="Partition" select="XCSExcelSheet/XCSExcelRow[1]/PARTITION" />
      <xsl:variable name="Client" select="XCSExcelSheet/XCSExcelRow[1]/CLIENT" />
      <xsl:variable name="ClientName" select="XCSExcelSheet/XCSExcelRow[1]/CLIENTNAME" />
      <xsl:for-each select="XCSExcelSheet/XCSExcelRow[string-length(SPLIT_FACILITY) &gt; 0 and string-length(COMPARATOR) &gt; 0]">
        <ns1:Insert>
          <CLIENT_CODES>
            <FACILITY>
              <xsl:value-of select="SPLIT_FACILITY" />
            </FACILITY>
            <CODE>
              <xsl:if test="string-length(SPLIT_CODE) &gt; 0">
                <xsl:value-of select="SPLIT_CODE" />
              </xsl:if>
            </CODE>
            <COMPARATOR>
              <xsl:value-of select="COMPARATOR" />
            </COMPARATOR>
            <SOFTWARE_ID>
              <xsl:value-of select="$SoftwareID" />
            </SOFTWARE_ID>
          </CLIENT_CODES>
        </ns1:Insert>
      </xsl:for-each>
      <xsl:for-each select="XCSExcelSheet/XCSExcelRow[string-length(CLIENT) &gt; 0 and string-length(FACILITY) &gt; 0 and string-length(FACILITY_CODE) &gt; 0]">
        <ns1:Insert>
          <CLIENT_SPLITS>
            <SOFTWAREID>
              <xsl:value-of select="$SoftwareID" />
            </SOFTWAREID>
            <CLIENTNAME>
              <xsl:value-of select="$ClientName" />
            </CLIENTNAME>
            <PARTITION>
              <xsl:value-of select="$Partition" />
            </PARTITION>
            <CLIENT>
              <xsl:value-of select="$Client" />
            </CLIENT>
            <FACILITY>
              <xsl:value-of select="FACILITY" />
            </FACILITY>
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
            <!--DONT INCLUDE IS_DEFAULT BECAUSE THE DEFAULT FACILITY ALREADY EXISTS AT THIS POINT-->
            <!--<xsl:if test="$NumSplits = 0 or position() = 1">-->
            <!--<IS_DEFAULT>1</IS_DEFAULT>-->
            <!--</xsl:if>-->
          </CLIENT_SPLITS>
        </ns1:Insert>
      </xsl:for-each>
    </ns1:SQLXML>
  </xsl:template>
</xsl:stylesheet>

