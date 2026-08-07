<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ns2="http://ACORD.org/Standards/Life/2" xmlns:ta="xalan://com.pilotfish.eip.TransactionAttributes" xmlns:td="xalan://com.pilotfish.eip.TransactionData" exclude-result-prefixes="ta td" version="1.0">
  <xsl:param name="eiPlatformTransactionData" />
  <xsl:variable name="attributes" select="td:getAttributes($eiPlatformTransactionData)" />
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>
  <xsl:template match="ns2:GovtID/text()">
    <xsl:text />
  </xsl:template>
  <xsl:template match="ns2:FullName[ancestor::ns2:Party/@id = ancestor::ns2:OLifE/ns2:Relation[ns2:RelatedObjectType/@tc=6]/@RelatedObjectID]/text()">
    <xsl:text>John Doe</xsl:text>
  </xsl:template>
  <xsl:template match="ns2:FirstName[ancestor::ns2:Party/@id = ancestor::ns2:OLifE/ns2:Relation[ns2:RelatedObjectType/@tc=6]/@RelatedObjectID]/text()">
    <xsl:value-of select="ta:getAttribute($attributes, concat('teledex.ordernum.for.transrefguid.', ancestor::ns2:TXLifeRequest/ns2:TransRefGUID))" />
  </xsl:template>
  <xsl:template match="ns2:MiddleName[ancestor::ns2:Party/@id = ancestor::ns2:OLifE/ns2:Relation[ns2:RelatedObjectType/@tc=6]/@RelatedObjectID]/text()">
    <xsl:text>D</xsl:text>
  </xsl:template>
  <xsl:template match="ns2:LastName[ancestor::ns2:Party/@id = ancestor::ns2:OLifE/ns2:Relation[ns2:RelatedObjectType/@tc=6]/@RelatedObjectID]/text()">
    <xsl:text>Doe</xsl:text>
  </xsl:template>
  <xsl:template match="ns2:BirthDate/text()">
    <xsl:text>1950-01-01</xsl:text>
  </xsl:template>
  <xsl:template match="ns2:Address/ns2:Line1/text()">
    <xsl:text>943 1st Avenue</xsl:text>
  </xsl:template>
  <xsl:template match="ns2:Address/ns2:Line2/text()">
    <xsl:text />
  </xsl:template>
  <xsl:template match="ns2:Address/ns2:City/text()">
    <xsl:text>New York</xsl:text>
  </xsl:template>
  <xsl:template match="ns2:Address/ns2:AddressStateTC/text()">
    <xsl:text>NY</xsl:text>
  </xsl:template>
  <xsl:template match="ns2:Address/ns2:AddressState/text()">
    <xsl:text>NY</xsl:text>
  </xsl:template>
  <xsl:template match="ns2:Address/ns2:AddressStateTC/@tc">
    <xsl:attribute name="tc">37</xsl:attribute>
  </xsl:template>
  <xsl:template match="ns2:Address/ns2:Zip/text()">
    <xsl:text>10022</xsl:text>
  </xsl:template>
  <xsl:template match="ns2:Phone/ns2:DialNumber/text()">
    <xsl:text>5551234</xsl:text>
  </xsl:template>
  <xsl:template match="ns2:EMailAddress/ns2:AddrLine/text()">
    <xsl:text>john.doe@aol.com</xsl:text>
  </xsl:template>
</xsl:stylesheet>

