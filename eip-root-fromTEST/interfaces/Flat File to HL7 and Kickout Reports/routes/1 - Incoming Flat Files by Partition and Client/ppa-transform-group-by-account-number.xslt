<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:output encoding="UTF-8" indent="yes" method="xml" version="1.0" />
  <!-- Create a key for matching charges to demographics -->
  <xsl:key match="Charges/XCSRecord" name="charges-by-account" use="PATIENTACCOUNT" />
  <!-- Create a key for unique demographics -->
  <xsl:key match="Demographics/XCSRecord" name="demographics-by-account" use="HSP_ACCOUNT_ID" />
  <!-- Handle the root element -->
  <xsl:template match="/">
    <XCSData>
      <!-- Process only the first occurrence of each account ID -->
      <xsl:for-each select="XCSData/Demographics/XCSRecord[generate-id() = generate-id(key('demographics-by-account', HSP_ACCOUNT_ID)[1])]">
        <Group key="{HSP_ACCOUNT_ID}">
          <Demographics>
            <xsl:copy-of select="." />
          </Demographics>
          <Charges>
            <xsl:copy-of select="key('charges-by-account', HSP_ACCOUNT_ID)" />
          </Charges>
        </Group>
      </xsl:for-each>
      <!-- Process charges without matching demographics -->
      <xsl:for-each select="XCSData/Charges/XCSRecord[not(key('demographics-by-account', PATIENTACCOUNT))]">
        <Charges>
          <xsl:attribute name="no-matching-demo-warning" select="'true'" />
          <xsl:copy-of select="." />
        </Charges>
      </xsl:for-each>
    </XCSData>
  </xsl:template>
</xsl:stylesheet>

