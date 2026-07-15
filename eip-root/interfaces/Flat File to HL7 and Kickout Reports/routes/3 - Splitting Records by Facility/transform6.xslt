<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:template match="/RESULT">
    <XCSData>
      <SplitInfo>
        <xsl:for-each-group group-by="FACILITY" select="SIMPLEQUERY">
          <Split>
            <xsl:attribute name="split_code" select="current-group()[1]/FACILITY" />
            <xsl:attribute name="facility_code" select="current-group()[1]/FACILITYCODE" />
            <xsl:attribute name="account_num_alpha" select="current-group()[1]/ACCOUNTNUMALPHA" />
            <xsl:attribute name="default_perf_dr" select="current-group()[1]/DEFAULTPERFDR" />
            <xsl:if test="ISDEFAULT = '1'">
              <IsDefault>true</IsDefault>
            </xsl:if>
            <ClientCodes>
              <xsl:attribute name="comparator" select="current-group()[1]/COMPARATOR" />
              <xsl:for-each select="current-group()/CODE">
                <ClientCode>
                  <xsl:value-of select="." />
                </ClientCode>
              </xsl:for-each>
            </ClientCodes>
          </Split>
        </xsl:for-each-group>
      </SplitInfo>
    </XCSData>
  </xsl:template>
</xsl:stylesheet>

