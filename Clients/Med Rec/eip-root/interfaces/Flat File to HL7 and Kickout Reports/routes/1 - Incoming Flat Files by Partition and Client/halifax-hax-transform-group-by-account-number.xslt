<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:output encoding="UTF-8" indent="yes" method="xml" version="1.0" />
  <!-- Create a key for matching charges to demographics -->
  <xsl:key match="Charges/XCSData/XCSRecord" name="charges-by-account" use="HSP_CSN" />
  <!-- Create a key for unique demographics -->
  <xsl:key match="Demographics/XCSData/XCSRecord" name="demographics-by-account" use="HSP_CSN" />
  <!-- Handle the root element -->
  <xsl:template match="/">
    <XCSData>
      <!-- Process only the first occurrence of each account ID -->
      <xsl:for-each select="XCSData/Demographics/XCSData/XCSRecord[generate-id() = generate-id(key('demographics-by-account', HSP_CSN)[1])]">
        <Group key="{HSP_CSN}">
          <Demographics>
            <xsl:copy-of select="." />
          </Demographics>
          <Charges>
            <xsl:copy-of select="key('charges-by-account', HSP_CSN)" />
          </Charges>
        </Group>
      </xsl:for-each>
      <!-- Process charges without matching demographics -->
      <xsl:for-each select="XCSData/Charges/XCSRecord[not(key('demographics-by-account', HSP_CSN))]">
        <Charges>
          <xsl:attribute name="no-matching-demo-warning" select="'true'" />
          <xsl:copy-of select="." />
        </Charges>
      </xsl:for-each>
    </XCSData>
  </xsl:template>
</xsl:stylesheet>

