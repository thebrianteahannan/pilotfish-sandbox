<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ns1="http://pilotfish.sqlxml" version="3.1">
  <xsl:template match="/">
    <ns1:SQLXML>
      <xsl:for-each select="XCSExcelBook/XCSExcelSheet[1]/XCSExcelRow">
        <ns1:Insert>
          <CLIENT_SPLITS_88363>
            <SOFTWAREID>
              <xsl:value-of select="SOFTWAREID" />
            </SOFTWAREID>
            <CLIENTNAME>
              <xsl:value-of select="CLIENTNAME" />
            </CLIENTNAME>
            <LOG_NAME>
              <xsl:value-of select="C_88363_Log_Name" />
            </LOG_NAME>
            <FACILITY_CODE_88363>
              <xsl:value-of select="C_88363_Facility_Code" />
            </FACILITY_CODE_88363>
            <PARTITION>
              <xsl:value-of select="PARTITION" />
            </PARTITION>
            <CLIENT>
              <xsl:value-of select="CLIENT" />
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
            <xsl:if test="IS_DEFAULT != 'null'">
              <IS_DEFAULT>
                <xsl:value-of select="IS_DEFAULT" />
              </IS_DEFAULT>
            </xsl:if>
          </CLIENT_SPLITS_88363>
        </ns1:Insert>
      </xsl:for-each>
      <xsl:for-each select="//Location_Code_Split">
        <xsl:variable name="split_codes" select="tokenize(.,',')" />
        <xsl:variable name="software_id" select="../SOFTWAREID" />
        <xsl:variable name="facility" select="../FACILITY" />
        <xsl:variable name="default_facility_with_software_id" select="//XCSExcelRow[SOFTWAREID = $software_id and IS_DEFAULT != 'null']/FACILITY" />
        <xsl:for-each select="$split_codes">
          <ns1:Insert>
            <CLIENT_CODES_88363>
              <SOFTWARE_ID>
                <xsl:value-of select="$software_id" />
              </SOFTWARE_ID>
              <FACILITY>
                <xsl:value-of select="$facility" />
              </FACILITY>
              <CODE>
                <xsl:value-of select="." />
              </CODE>
              <COMPARATOR>
                <xsl:value-of select="'='" />
              </COMPARATOR>
            </CLIENT_CODES_88363>
          </ns1:Insert>
        </xsl:for-each>
        <xsl:for-each select="$split_codes">
          <xsl:if test=". != 'null'">
            <ns1:Insert>
              <CLIENT_CODES_88363>
                <SOFTWARE_ID>
                  <xsl:value-of select="$software_id" />
                </SOFTWARE_ID>
                <FACILITY>
                  <xsl:value-of select="$default_facility_with_software_id" />
                </FACILITY>
                <CODE>
                  <xsl:value-of select="." />
                </CODE>
                <COMPARATOR>
                  <xsl:value-of select="'!='" />
                </COMPARATOR>
              </CLIENT_CODES_88363>
            </ns1:Insert>
          </xsl:if>
        </xsl:for-each>
      </xsl:for-each>
    </ns1:SQLXML>
  </xsl:template>
</xsl:stylesheet>

