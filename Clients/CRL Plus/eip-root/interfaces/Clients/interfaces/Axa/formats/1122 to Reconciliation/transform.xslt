<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:datetime="http://exslt.org/dates-and-times" xmlns:ns1="http://ACORD.org/Standards/Life/2" exclude-result-prefixes="ns1 datetime" version="1.0">
  <xsl:template match="/ns1:TXLife">
    <XCSData>
      <XCSRecord row="0">
        <xsl:variable name="primaryInsured" select="ns1:TXLifeRequest/ns1:OLifE/ns1:Party[@id=../ns1:Relation[ns1:RelationRoleCode/@tc=32]/@RelatedObjectID]" />
        <TransRefGUID>
          <xsl:value-of select="ns1:TXLifeRequest/ns1:TransRefGUID" />
        </TransRefGUID>
        <CompanyProducerID>
          <xsl:value-of select="//ns1:CompanyProducerID" />
        </CompanyProducerID>
        <DOB>
          <xsl:call-template name="FormatDate">
            <xsl:with-param name="date">
              <xsl:value-of select="$primaryInsured/ns1:Person/ns1:BirthDate" />
            </xsl:with-param>
          </xsl:call-template>
        </DOB>
        <FirstName>
          <xsl:value-of select="$primaryInsured/ns1:Person/ns1:FirstName" />
        </FirstName>
        <LastName>
          <xsl:value-of select="$primaryInsured/ns1:Person/ns1:LastName" />
        </LastName>
        <PolNumber>
          <xsl:value-of select="ns1:TXLifeRequest/ns1:OLifE/ns1:Holding/ns1:Policy/ns1:PolNumber" />
        </PolNumber>
        <DateTimeSent>
          <xsl:value-of select="datetime:format-date(datetime:date-time(),'M/d/yyyy hh:mm:ss a')" />
        </DateTimeSent>
        <WHOLESALE>WHOLESALE</WHOLESALE>
        <EXAM>EXAM</EXAM>
      </XCSRecord>
    </XCSData>
  </xsl:template>
  <xsl:template name="FormatDate">
    <xsl:param name="date" />
    <xsl:choose>
      <xsl:when test="string-length($date) = 10">
        <xsl:choose>
          <xsl:when test="substring($date, 6, 1) = '0'">
            <xsl:value-of select="substring($date, 7, 1)" />
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="substring($date, 6, 2)" />
          </xsl:otherwise>
        </xsl:choose>
        <xsl:value-of select="'/'" />
        <xsl:choose>
          <xsl:when test="substring($date, 9, 1) = '0'">
            <xsl:value-of select="substring($date, 10, 1)" />
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="substring($date, 9, 2)" />
          </xsl:otherwise>
        </xsl:choose>
        <xsl:value-of select="'/'" />
        <xsl:value-of select="substring($date, 1, 4)" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$date" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="TwoDigits">
    <xsl:param name="string" />
    <xsl:if test="string-length($string) &lt; 2">
      <xsl:value-of select="'0'" />
    </xsl:if>
    <xsl:value-of select="$string" />
  </xsl:template>
</xsl:stylesheet>

