<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:template match="/">
    <XCSExcelBook>
      <XCSExcelSheet name="tblCDMProcNotFound">
        <XCSExcelRow>
          <CDM>CDM</CDM>
          <CPT>CPT</CPT>
          <Department>Department</Department>
          <Description>Description</Description>
          <Interface_Type>Interface Type</Interface_Type>
          <!--<Facility_Code>Facility Code</Facility_Code>-->
          <!--<ADMLOCATION>ADM Location</ADMLOCATION>-->
          <!--<STRIPLOCATION1>StripLocationCount</STRIPLOCATION1>-->
          <!--<Filler2>Filler2</Filler2>-->
          <!--<AccountNum>AccountNum</AccountNum>-->
          <!--<FilterMe>FilterMe</FilterMe>-->
        </XCSExcelRow>
        <xsl:for-each-group group-by="concat(CDM,CPT,Department,Description)" select="//XCSExcelRow">
          <xsl:sort select="CDM" />
          <xsl:for-each select="(current-group())[1]">
            <XCSExcelRow>
              <CDM>
                <xsl:value-of select="CDM" />
              </CDM>
              <CPT>
                <xsl:value-of select="CPT" />
              </CPT>
              <Department>
                <xsl:value-of select="Department" />
              </Department>
              <Description>
                <xsl:value-of select="Description" />
              </Description>
              <Interface_Type>
                <xsl:value-of select="Interface_Type" />
              </Interface_Type>
              <!--<Facility_Code>-->
              <!--<xsl:value-of select="Facility_Code" />-->
              <!--</Facility_Code>-->
            </XCSExcelRow>
          </xsl:for-each>
        </xsl:for-each-group>
      </XCSExcelSheet>
    </XCSExcelBook>
  </xsl:template>
</xsl:stylesheet>

