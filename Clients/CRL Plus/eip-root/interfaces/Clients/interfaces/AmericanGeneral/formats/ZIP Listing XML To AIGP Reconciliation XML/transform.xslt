<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ta="xalan://com.pilotfish.eip.TransactionAttributes" xmlns:td="xalan://com.pilotfish.eip.TransactionData" exclude-result-prefixes="ta td" version="1.0">
  <xsl:param name="eiPlatformTransactionData" />
  <xsl:variable name="attributes" select="td:getAttributes($eiPlatformTransactionData)" />
  <xsl:variable name="zipFileName" select="concat(ta:getAttribute($attributes, 'zip.filename'),'.ZIP')" />
  <xsl:template match="/FileList">
    <NewDataSet>
      <xsl:for-each select="File">
        <xsl:variable name="idx" select="position()" />
        <xsl:if test="$idx mod 2 = 0">
          <Table>
            <ZipFileName>
              <xsl:value-of select="$zipFileName" />
            </ZipFileName>
            <xsl:choose>
              <xsl:when test="contains(FileName,'IDX')">
                <index>
                  <xsl:value-of select="FileName" />
                </index>
                <image>
                  <xsl:value-of select="../File[$idx - 1]/FileName" />
                </image>
              </xsl:when>
              <xsl:otherwise>
                <index>
                  <xsl:value-of select="../File[$idx - 1]/FileName" />
                </index>
                <image>
                  <xsl:value-of select="FileName" />
                </image>
              </xsl:otherwise>
            </xsl:choose>
          </Table>
        </xsl:if>
      </xsl:for-each>
    </NewDataSet>
  </xsl:template>
</xsl:stylesheet>

