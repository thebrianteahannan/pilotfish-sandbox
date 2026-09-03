<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" indent="yes" encoding="UTF-8"/>

  <xsl:function name="fn:seg" as="node()*" xmlns:fn="http://pilotfish.local/fn">
    <xsl:param name="ctx"/>
    <xsl:param name="code"/>
    <xsl:sequence select="
      $ctx/*[local-name()=$code] |
      $ctx/*[starts-with(local-name(), concat($code, '_'))] |
      $ctx/*[local-name()='Segment' and (*[1]=$code or Element[1]=$code)]
    "/>
  </xsl:function>

  <xsl:function name="fn:el" as="xs:string" xmlns:fn="http://pilotfish.local/fn" xmlns:xs="http://www.w3.org/2001/XMLSchema">
    <xsl:param name="seg"/>
    <xsl:param name="name"/>
    <xsl:param name="pos"/>
    <xsl:variable name="byName" select="$seg/*[local-name()=$name or starts-with(local-name(), concat($name, '_'))][1]"/>
    <xsl:choose>
      <xsl:when test="normalize-space($byName)!=''"><xsl:value-of select="normalize-space($byName)"/></xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="normalize-space(($seg/*[local-name()='Element'][number($pos)] | $seg/*[position()=$pos])[1])"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:template match="/">
    <xsl:variable name="members" select="//*[local-name()='Loop_2000']"/>
    <XCSData>
      <xsl:for-each select="if (exists($members)) then $members else //*[local-name()='INS' or starts-with(local-name(),'INS_')]">
        <xsl:variable name="loop" select="if (local-name()='Loop_2000') then . else .."/>
        <xsl:variable name="ins" select="($loop/*[local-name()='INS' or starts-with(local-name(),'INS_')])[1]"/>
        <xsl:variable name="ref0f" select="($loop/*[local-name()='REF' or starts-with(local-name(),'REF_')][(*[local-name()='REF01' or starts-with(local-name(),'REF01')])[1]='0F'])[1]"/>
        <xsl:variable name="nm1" select="($loop//*[(local-name()='NM1' or starts-with(local-name(),'NM1_')) and (*[local-name()='NM101' or starts-with(local-name(),'NM101')])[1]='IL'])[1]"/>
        <xsl:variable name="dmg" select="($loop//*[local-name()='DMG' or starts-with(local-name(),'DMG_')])[1]"/>
        <xsl:variable name="hd" select="($loop//*[local-name()='HD' or starts-with(local-name(),'HD_')])[1]"/>
        <xsl:variable name="dtp" select="($loop//*[(local-name()='DTP' or starts-with(local-name(),'DTP_')) and (*[local-name()='DTP01' or starts-with(local-name(),'DTP01')])[1]='348'])[1]"/>
        <xsl:variable name="n1p5" select="(//*[local-name()='Loop_1000A']//*[local-name()='N1' or starts-with(local-name(),'N1_')] | //*[(local-name()='N1' or starts-with(local-name(),'N1_')) and (*[local-name()='N101' or starts-with(local-name(),'N101')])[1]='P5'])[1]"/>
        <xsl:variable name="n1in" select="(//*[local-name()='Loop_1000B']//*[local-name()='N1' or starts-with(local-name(),'N1_')] | //*[(local-name()='N1' or starts-with(local-name(),'N1_')) and (*[local-name()='N101' or starts-with(local-name(),'N101')])[1]='IN'])[1]"/>
        <XCSRecord>
          <MemberId>
            <xsl:choose>
              <xsl:when test="normalize-space(($ref0f/*[local-name()='REF02' or starts-with(local-name(),'REF02')])[1])!=''">
                <xsl:value-of select="($ref0f/*[local-name()='REF02' or starts-with(local-name(),'REF02')])[1]"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="($nm1/*[local-name()='NM109' or starts-with(local-name(),'NM109')])[1]"/>
              </xsl:otherwise>
            </xsl:choose>
          </MemberId>
          <LastName><xsl:value-of select="($nm1/*[local-name()='NM103' or starts-with(local-name(),'NM103')])[1]"/></LastName>
          <FirstName><xsl:value-of select="($nm1/*[local-name()='NM104' or starts-with(local-name(),'NM104')])[1]"/></FirstName>
          <BirthDate><xsl:value-of select="($dmg/*[local-name()='DMG02' or starts-with(local-name(),'DMG02')])[1]"/></BirthDate>
          <GenderCode><xsl:value-of select="($dmg/*[local-name()='DMG03' or starts-with(local-name(),'DMG03')])[1]"/></GenderCode>
          <RelationshipCode><xsl:value-of select="($ins/*[local-name()='INS02' or starts-with(local-name(),'INS02')])[1]"/></RelationshipCode>
          <MaintenanceTypeCode><xsl:value-of select="($ins/*[local-name()='INS03' or starts-with(local-name(),'INS03')])[1]"/></MaintenanceTypeCode>
          <PlanId><xsl:value-of select="($hd/*[local-name()='HD04' or starts-with(local-name(),'HD04')])[1]"/></PlanId>
          <CoverageStartDate><xsl:value-of select="($dtp/*[local-name()='DTP03' or starts-with(local-name(),'DTP03')])[1]"/></CoverageStartDate>
          <SponsorName><xsl:value-of select="($n1p5/*[local-name()='N102' or starts-with(local-name(),'N102')])[1]"/></SponsorName>
          <SponsorId><xsl:value-of select="($n1p5/*[local-name()='N104' or starts-with(local-name(),'N104')])[1]"/></SponsorId>
          <PayerName><xsl:value-of select="($n1in/*[local-name()='N102' or starts-with(local-name(),'N102')])[1]"/></PayerName>
          <PayerId><xsl:value-of select="($n1in/*[local-name()='N104' or starts-with(local-name(),'N104')])[1]"/></PayerId>
        </XCSRecord>
      </xsl:for-each>
    </XCSData>
  </xsl:template>
</xsl:stylesheet>
