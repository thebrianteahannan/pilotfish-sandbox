<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:output encoding="UTF-8" indent="yes" method="xml" version="1.0" />
  <!-- Create a key for matching charges to demographics -->
  <xsl:key match="XCSData/Charges/XCSData/XCSRecord" name="charges-by-account" use="CSN" />
  <!-- Create a key for unique demographics -->
  <xsl:key match="XCSData/Demographics/XCSData/XCSRecord" name="demographics-by-account" use="HSP_CSN" />
  <!-- Handle the root element -->
  <xsl:template match="/">
    <XCSData>
      <!-- Process only the first occurrence of each account ID, excluding header row -->
      <xsl:for-each select="XCSData/Demographics/XCSData/XCSRecord[HSP_CSN != 'radAcctNum' and generate-id() = generate-id(key('demographics-by-account', HSP_CSN)[1])]">
        <Group key="{HSP_CSN}">
          <Demographics>
            <xsl:apply-templates mode="clean-nulls" select="." />
          </Demographics>
          <Charges>
            <xsl:apply-templates mode="clean-nulls" select="key('charges-by-account', HSP_CSN)" />
          </Charges>
        </Group>
      </xsl:for-each>
      <!-- Process charges without matching demographics, excluding header row -->
      <xsl:for-each select="XCSData/Charges/XCSData/XCSRecord[CSN != 'radAcctNum' and not(key('demographics-by-account', CSN))]">
        <Charges>
          <xsl:attribute name="no-matching-demo-warning" select="'true'" />
          <xsl:apply-templates mode="clean-nulls" select="." />
        </Charges>
      </xsl:for-each>
    </XCSData>
  </xsl:template>
  <!-- Template to clean NULL values from elements -->
  <xsl:template match="*" mode="clean-nulls">
    <xsl:choose>
      <xsl:when test="text() = 'NULL' or text() = ''">
        <!-- Skip NULL or empty elements -->
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy>
          <xsl:copy-of select="@*" />
          <xsl:apply-templates mode="clean-nulls" />
        </xsl:copy>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>

