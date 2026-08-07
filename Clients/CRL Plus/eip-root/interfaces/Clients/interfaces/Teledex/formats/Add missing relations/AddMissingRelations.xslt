<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ns1="http://ACORD.org/Standards/Life/2" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" exclude-result-prefixes="ns1" version="1.0">
  <!-- IdentityTransform -->
  <xsl:template match="/ | @* | node()">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()" />
    </xsl:copy>
  </xsl:template>
  <xsl:template match="ns1:OLifE">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()" />
      <xsl:if test="not(ns1:Relation/ns1:RelationRoleCode[@tc='32'])">
        <xsl:if test="ns1:Holding/ns1:Policy/ns1:Life/ns1:Coverage/ns1:LifeParticipant[ns1:LifeParticipantRoleCode/@tc='1']">
          <xsl:variable name="relObjID" select="ns1:Holding/ns1:Policy/ns1:Life/ns1:Coverage/ns1:LifeParticipant[ns1:LifeParticipantRoleCode/@tc='1']/@PartyID" />
          <xsl:variable name="relObjID" select="ns1:Holding/ns1:Policy/ns1:Life/ns1:Coverage/ns1:LifeParticipant[ns1:LifeParticipantRoleCode/@tc='1']/@PartyID" />
          <ns1:Relation OriginatingObjectID="{ns1:Holding/@id}" RelatedObjectID="{$relObjID}" id="{concat('Relation_',$relObjID)}">
            <ns1:OriginatingObjectType tc="4">Holding</ns1:OriginatingObjectType>
            <ns1:RelatedObjectType tc="6">Party</ns1:RelatedObjectType>
            <ns1:RelationRoleCode tc="32">Insured</ns1:RelationRoleCode>
          </ns1:Relation>
        </xsl:if>
      </xsl:if>
      <xsl:if test="not(ns1:Relation/ns1:RelationRoleCode[@tc='37'])">
        <xsl:if test="ns1:Holding/ns1:Policy/ns1:Life/ns1:Coverage/ns1:LifeParticipant[ns1:LifeParticipantRoleCode/@tc='15']">
          <xsl:variable name="relObjID" select="ns1:Holding/ns1:Policy/ns1:Life/ns1:Coverage/ns1:LifeParticipant[ns1:LifeParticipantRoleCode/@tc='15']/@PartyID" />
          <ns1:Relation OriginatingObjectID="{ns1:Holding/@id}" RelatedObjectID="{$relObjID}" id="{concat('Relation_',$relObjID)}">
            <ns1:OriginatingObjectType tc="4">Holding</ns1:OriginatingObjectType>
            <ns1:RelatedObjectType tc="6">Party</ns1:RelatedObjectType>
            <ns1:RelationRoleCode tc="37">Agent</ns1:RelationRoleCode>
          </ns1:Relation>
        </xsl:if>
      </xsl:if>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="ns1:Attachment[/ns1:TXLife/ns1:TXLifeRequest/ns1:OLifE/ns1:Holding/ns1:Policy/ns1:RequirementInfo[ns1:RequirementAcctNum='71661']][ns1:AttachmentData]">
    <!-- Don't copy ELFP image attachments -->
  </xsl:template>
</xsl:stylesheet>

