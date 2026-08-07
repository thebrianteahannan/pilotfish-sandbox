<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://ACORD.org/Standards/Life/2" xmlns:ns1="http://ACORD.org/Standards/Life/2" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="1.0">
  <!-- IdentityTransform -->
  <xsl:template match="/ | @* | node()">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()" />
    </xsl:copy>
  </xsl:template>
  <xsl:template match="ns1:OLifE">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()" />
      <xsl:element name="Party" namespace="{namespace-uri(.)}">
        <xsl:attribute name="id">Party_Requester_1</xsl:attribute>
        <xsl:element name="PartyTypeCode" namespace="{namespace-uri(.)}">
          <xsl:attribute name="tc">2</xsl:attribute>
          <xsl:text>Company</xsl:text>
        </xsl:element>
        <xsl:element name="FullName" namespace="{namespace-uri(.)}">ERIE 103 PRODUCTION</xsl:element>
        <xsl:element name="Organization" namespace="{namespace-uri(.)}">
          <xsl:element name="DBA" namespace="{namespace-uri(.)}">ERIE 103 PRODUCTION</xsl:element>
        </xsl:element>
      </xsl:element>
      <xsl:element name="Party" namespace="{namespace-uri(.)}">
        <xsl:attribute name="id">Party_Fulfiller_1</xsl:attribute>
        <xsl:element name="PartyTypeCode" namespace="{namespace-uri(.)}">
          <xsl:attribute name="tc">2</xsl:attribute>
          <xsl:text>Company</xsl:text>
        </xsl:element>
        <xsl:element name="FullName" namespace="{namespace-uri(.)}">CRL-Plus</xsl:element>
        <xsl:element name="Organization" namespace="{namespace-uri(.)}">
          <xsl:element name="DBA" namespace="{namespace-uri(.)}">CRL-Plus</xsl:element>
        </xsl:element>
      </xsl:element>
      <xsl:element name="Relation" namespace="{namespace-uri(.)}">
        <xsl:attribute name="OriginatingObjectID">Party_1</xsl:attribute>
        <xsl:attribute name="RelatedObjectID">Party_Requester_1</xsl:attribute>
        <xsl:attribute name="id">Relation_Requester_1</xsl:attribute>
        <xsl:element name="RelationRoleCode" namespace="{namespace-uri(.)}">
          <xsl:attribute name="tc">97</xsl:attribute>
          <xsl:text>Requestor</xsl:text>
        </xsl:element>
      </xsl:element>
      <xsl:element name="Relation" namespace="{namespace-uri(.)}">
        <xsl:attribute name="OriginatingObjectID">Party_1</xsl:attribute>
        <xsl:attribute name="RelatedObjectID">Party_Fulfiller_1</xsl:attribute>
        <xsl:attribute name="id">Relation_Fulfiller_1</xsl:attribute>
        <xsl:element name="RelationRoleCode" namespace="{namespace-uri(.)}">
          <xsl:attribute name="tc">99</xsl:attribute>
          <xsl:text>Fulfills</xsl:text>
        </xsl:element>
      </xsl:element>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="ns1:StatusEventCode">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()" />
      <xsl:call-template name="statusEventCodeMapping">
        <xsl:with-param name="tc" select="@tc" />
      </xsl:call-template>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="ns1:data[@id='originalText']" />
  <xsl:template match="ns1:RequirementInfo">
    <xsl:element name="RequirementInfo" namespace="{namespace-uri(.)}">
      <xsl:apply-templates select="@* | node()" />
    </xsl:element>
    <xsl:variable name="firstReq" select="." />
    <xsl:for-each select="ancestor::ns1:TXLife/ns1:data[@id='originalText']/ns1:TXLife/ns1:TXLifeRequest/ns1:OLifE/ns1:Holding/ns1:Policy/ns1:RequirementInfo[position()&gt;1]">
      <xsl:element name="RequirementInfo" namespace="{namespace-uri(.)}">
        <xsl:apply-templates select="@*" />
        <xsl:copy-of select="ns1:ReqCode" />
        <xsl:copy-of select="$firstReq/*[local-name()!='ReqCode' and local-name()!='Attachment']" />
      </xsl:element>
    </xsl:for-each>
  </xsl:template>
  <xsl:template name="statusEventCodeMapping">
    <xsl:param name="tc" />
    <xsl:choose>
      <xsl:when test="$tc=2147483647">Others</xsl:when>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>

