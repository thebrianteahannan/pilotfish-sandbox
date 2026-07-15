<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:datetime="http://exslt.org/dates-and-times" exclude-result-prefixes="datetime" version="3.1">
  <xsl:template match="/XCSData">
    <XCSExcelBook>
      <XCSExcelSheet name="tblRefdPhysNPIList_IRL">
        <XCSExcelRow>
          <DocMnem>DocMnem</DocMnem>
          <DocNPI>DocNPI</DocNPI>
          <DocName>DocName</DocName>
          <DateAdded>DateAdded</DateAdded>
        </XCSExcelRow>
        <xsl:for-each-group group-by="concat(absattendingdocmnem,AttendDrNPI)" select="Import/Group[@stripped = 'false']/PatientDemographics">
          <xsl:sort select="absattendingdocmnem" />
          <XCSExcelRow>
            <DocMnem>
              <xsl:value-of select="absattendingdocmnem" />
            </DocMnem>
            <DocNPI>
              <xsl:value-of select="AttendDrNPI" />
            </DocNPI>
            <DocName>
              <xsl:value-of select="absattendingdocname" />
            </DocName>
            <DateAdded>
              <!-- <xsl:value-of select="absdischargedate" /> -->
              <!-- <xsl:value-of select="format-date(absdischargedate, '[M01]/[D01]/[Y0001]')"/> -->
              <xsl:value-of select="format-date(current-date(), '[M01]/[D01]/[Y0001]')" />
            </DateAdded>
          </XCSExcelRow>
        </xsl:for-each-group>
      </XCSExcelSheet>
    </XCSExcelBook>
  </xsl:template>
</xsl:stylesheet>

