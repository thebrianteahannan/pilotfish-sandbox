<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:template match="/EIPData/RESULTS">
    <XCSData>
      <xsl:for-each select="RESULT">
        <XCSRecord>
          <PolicyNum>
            <xsl:value-of select="POLICYNUM" />
          </PolicyNum>
          <OrderNumber>
            <xsl:value-of select="ORDERNUMBER" />
          </OrderNumber>
          <Requirement_Type>
            <xsl:value-of select="REQUIREMENTTYPE" />
          </Requirement_Type>
          <Date_Opened>
            <xsl:value-of select="DATEOPENED" />
          </Date_Opened>
          <UniqueID>
            <xsl:value-of select="UNIQUEID" />
          </UniqueID>
          <Company>
            <xsl:value-of select="COMPANY" />
          </Company>
          <Additional_Info>
            <xsl:value-of select="ADDITONALINFO" />
          </Additional_Info>
        </XCSRecord>
      </xsl:for-each>
    </XCSData>
  </xsl:template>
</xsl:stylesheet>

