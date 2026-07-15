<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:param name="txtInterfaceType" />
  <xsl:param name="txtFacilityCode" />
  <xsl:template match="/XCSData">
    <XCSExcelBook>
      <XCSExcelSheet name="IRL_No_RespParty">
        <XCSExcelRow>
          <admAcctNum>admAcctNum</admAcctNum>
        </XCSExcelRow>
      </XCSExcelSheet>
    </XCSExcelBook>
  </xsl:template>
</xsl:stylesheet>

