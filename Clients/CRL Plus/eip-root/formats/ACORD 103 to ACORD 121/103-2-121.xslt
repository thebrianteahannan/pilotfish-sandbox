<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://ACORD.org/Standards/Life/2" xmlns:acord="http://ACORD.org/Standards/Life/2" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" exclude-result-prefixes="acord" version="1.0">
  <xsl:template match="/acord:TXLife">
    <TXLife schemaLocation="http://ACORD.org/Standards/Life/2 TXLife2.20.02.xsd">
      <xsl:apply-templates mode="copy" select="acord:UserAuthRequest" />
      <TXLifeRequest>
        <TransRefGUID>
          <xsl:value-of select="acord:TXLifeRequest/acord:TransRefGUID" />
        </TransRefGUID>
        <TransType tc="121">
          <xsl:text>General Requirement Order Request</xsl:text>
        </TransType>
        <TransExeDate>
          <xsl:value-of select="acord:TXLifeRequest/acord:TransExeDate" />
        </TransExeDate>
        <TransExeTime>
          <xsl:value-of select="acord:TXLifeRequest/acord:TransExeTime" />
        </TransExeTime>
        <xsl:choose>
          <xsl:when test="acord:TXLifeRequest/acord:TransMode">
            <TransMode tc="{acord:TXLifeRequest/acord:TransMode/@tc}">
              <xsl:value-of select="acord:TXLifeRequest/acord:TransMode" />
            </TransMode>
          </xsl:when>
          <xsl:otherwise>
            <TransMode tc="2">Original</TransMode>
          </xsl:otherwise>
        </xsl:choose>
          <xsl:apply-templates mode="copy" select="acord:TXLifeRequest/acord:TestIndicator" />
        <OLifE>
          <xsl:apply-templates mode="copy" select="acord:TXLifeRequest/acord:OLifE/acord:SourceInfo" />
          <Holding id="{acord:TXLifeRequest/acord:OLifE/acord:Holding/@id}">
            <xsl:apply-templates mode="copy" select="acord:TXLifeRequest/acord:OLifE/acord:Holding/acord:Policy" />
            <xsl:apply-templates mode="copy" select="acord:TXLifeRequest/acord:OLifE/acord:Holding/acord:Attachment" />
            <xsl:apply-templates mode="copy" select="acord:TXLifeRequest/acord:OLifE/acord:FormInstance/acord:Attachment" />
          </Holding>
          <xsl:apply-templates mode="copy" select="acord:TXLifeRequest/acord:OLifE/acord:Party" />
          <xsl:apply-templates mode="copy" select="acord:TXLifeRequest/acord:OLifE/acord:Relation" />
          <xsl:if test="not(acord:TXLifeRequest/acord:OLifE/acord:Relation/acord:RelationRoleCode[@tc='32'])">
            <xsl:if test="acord:TXLifeRequest/acord:OLifE/acord:Holding/acord:Policy/acord:Life/acord:Coverage/acord:LifeParticipant[acord:LifeParticipantRoleCode/@tc='1']">
              <xsl:variable name="relObjID" select="acord:TXLifeRequest/acord:OLifE/acord:Holding/acord:Policy/acord:Life/acord:Coverage/acord:LifeParticipant[acord:LifeParticipantRoleCode/@tc='1']/@PartyID" />
              <xsl:variable name="relObjID" select="acord:TXLifeRequest/acord:OLifE/acord:Holding/acord:Policy/acord:Life/acord:Coverage/acord:LifeParticipant[acord:LifeParticipantRoleCode/@tc='1']/@PartyID" />
              <Relation OriginatingObjectID="{acord:TXLifeRequest/acord:OLifE/acord:Holding/@id}" RelatedObjectID="{$relObjID}" id="{concat('Relation_',$relObjID)}">
                <OriginatingObjectType tc="4">Holding</OriginatingObjectType>
                <RelatedObjectType tc="6">Party</RelatedObjectType>
                <RelationRoleCode tc="32">Insured</RelationRoleCode>
              </Relation>
            </xsl:if>
          </xsl:if>
          <xsl:if test="not(acord:TXLifeRequest/acord:OLifE/acord:Relation/acord:RelationRoleCode[@tc='37'])">
            <xsl:if test="acord:TXLifeRequest/acord:OLifE/acord:Holding/acord:Policy/acord:Life/acord:Coverage/acord:LifeParticipant[acord:LifeParticipantRoleCode/@tc='15']">
              <xsl:variable name="relObjID" select="acord:TXLifeRequest/acord:OLifE/acord:Holding/acord:Policy/acord:Life/acord:Coverage/acord:LifeParticipant[acord:LifeParticipantRoleCode/@tc='15']/@PartyID" />
              <Relation OriginatingObjectID="{acord:TXLifeRequest/acord:OLifE/acord:Holding/@id}" RelatedObjectID="{$relObjID}" id="{concat('Relation_',$relObjID)}">
                <OriginatingObjectType tc="4">Holding</OriginatingObjectType>
                <RelatedObjectType tc="6">Party</RelatedObjectType>
                <RelationRoleCode tc="37">Agent</RelationRoleCode>
              </Relation>
            </xsl:if>
          </xsl:if>
          <xsl:for-each select="acord:TXLifeRequest/acord:OLifE/acord:FormInstance">
            <FormInstance>
              <xsl:apply-templates mode="copy" select="@*|node()[local-name() != 'Attachment']" />
            </FormInstance>
          </xsl:for-each>
        </OLifE>
      </TXLifeRequest>
    </TXLife>
  </xsl:template>
  <xsl:template match="acord:FullName[string-length(.)=0]" mode="copy" />
  <xsl:template match="acord:Person[(acord:FirstName = acord:LastName) and contains(normalize-space(acord:FirstName),' ') and string-length(../acord:FullName)=0]">
    <xsl:element name="FullName" namespace="{namespace-uri(.)}">
      <xsl:value-of select="acord:FirstName" />
    </xsl:element>
    <xsl:element name="Person" namespace="{namespace-uri(.)}">
      <xsl:element name="FirstName" namespace="{namespace-uri()}" />
      <xsl:element name="LastName" namespace="{namespace-uri()}" />
      <xsl:apply-templates mode="copy" select="@*|node()[name()!='FirstName' and name()!='LastName']" />
    </xsl:element>
  </xsl:template>
  <xsl:template match="acord:Person[(acord:FirstName = acord:LastName) and contains(normalize-space(acord:FirstName),' ') and string-length(../acord:FullName)=0]" mode="copy">
    <xsl:apply-templates select="." />
  </xsl:template>
  <xsl:template match="acord:Attachment[/acord:TXLife/acord:TXLifeRequest/acord:OLifE/acord:Holding/acord:Policy/acord:RequirementInfo[acord:RequirementAcctNum='71661']][acord:AttachmentData]">
    <!-- Don't copy ELFP image attachments -->
  </xsl:template>
  <xsl:template name="AttachmentBasicToAttachmentTypeMapping">
    <xsl:param name="value" />
    <xsl:choose>
      <xsl:when test="$value='1'">2</xsl:when>
      <xsl:when test="$value='2'">0</xsl:when>
      <xsl:when test="$value='3'">1</xsl:when>
      <xsl:otherwise>0</xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>
  <xsl:template match="*" mode="copy">
    <xsl:element name="{name()}" namespace="{namespace-uri(.)}">
      <xsl:apply-templates mode="copy" select="@*|node()" />
    </xsl:element>
  </xsl:template>
  <xsl:template match="@*|text()|comment()" mode="copy">
    <xsl:copy />
  </xsl:template>
</xsl:stylesheet>

