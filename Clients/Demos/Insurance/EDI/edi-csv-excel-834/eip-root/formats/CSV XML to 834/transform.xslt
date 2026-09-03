<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:fn="http://pilotfish.local/fn"
                exclude-result-prefixes="xs fn">
  <xsl:output method="xml" indent="yes" encoding="UTF-8"/>

  <xsl:function name="fn:col" as="xs:string">
    <xsl:param name="row"/>
    <xsl:param name="name"/>
    <xsl:value-of select="normalize-space(($row/*[upper-case(local-name())=upper-case($name)])[1])"/>
  </xsl:function>

  <xsl:variable name="records" select="//*[local-name()='XCSRecord']"/>
  <xsl:variable name="first" select="$records[1]"/>

  <xsl:template match="/">
    <xsl:variable name="sender" select="upper-case((if (fn:col($first,'SenderId')!='') then fn:col($first,'SenderId') else 'ACMEPAYER'))"/>
    <xsl:variable name="receiver" select="upper-case((if (fn:col($first,'ReceiverId')!='') then fn:col($first,'ReceiverId') else 'ACMESPONSOR'))"/>
    <xsl:variable name="sponsor" select="if (fn:col($first,'SponsorName')!='') then fn:col($first,'SponsorName') else 'ACME SPONSOR INC'"/>
    <xsl:variable name="sponsorId" select="if (fn:col($first,'SponsorId')!='') then fn:col($first,'SponsorId') else '123456789'"/>
    <xsl:variable name="payer" select="if (fn:col($first,'PayerName')!='') then fn:col($first,'PayerName') else 'ACME HEALTH PLAN'"/>
    <xsl:variable name="payerId" select="if (fn:col($first,'PayerId')!='') then fn:col($first,'PayerId') else '987654321'"/>
    <xsl:variable name="batch" select="if (fn:col($first,'BatchId')!='') then fn:col($first,'BatchId') else 'ENROLL001'"/>
    <xsl:variable name="digits" select="translate($batch,'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-','')"/>
    <xsl:variable name="isa13" select="if (number($digits)=number($digits)) then format-number(number(substring(concat($digits,'1'),1,9)), '000000000') else '000000001'"/>
    <xsl:variable name="ctrl" select="'0001'"/>
    <xsl:variable name="today" select="format-date(current-date(), '[Y0001][M01][D01]')"/>
    <xsl:variable name="yymmdd" select="substring($today, 3, 6)"/>
    <XCSData>
      <Interchange AuthorizationQual="00" AuthorizationInfo="          "
                   SecurityQual="00" SecurityInfo="          "
                   Date="{$yymmdd}" Time="1200"
                   StandardsId="^" Version="00501" ControlNumber="{$isa13}"
                   AckRequested="0" TestIndicator="T"
                   ElementDelim="*" SubElementDelim=":" RepetitionDelim="^" SegmentDelim="~">
        <SenderId Qualifier="ZZ"><xsl:value-of select="substring(concat($sender, '               '), 1, 15)"/></SenderId>
        <ReceiverId Qualifier="ZZ"><xsl:value-of select="substring(concat($receiver, '               '), 1, 15)"/></ReceiverId>
        <Group GroupType="BE" ApplSender="{$sender}" ApplReceiver="{$receiver}"
               Date="{$today}" Time="1200" ControlNumber="1"
               StandardCode="X" StandardVersion="005010X220A1">
          <Transaction DocType="834" ControlNumber="{$ctrl}" StandardVersion="005010X220A1">
            <ST>
              <ST01>834</ST01>
              <ST02><xsl:value-of select="$ctrl"/></ST02>
              <ST03>005010X220A1</ST03>
            </ST>
            <BGN>
              <BGN01>00</BGN01>
              <BGN02><xsl:value-of select="$batch"/></BGN02>
              <BGN03><xsl:value-of select="$today"/></BGN03>
              <BGN04>1200</BGN04>
              <BGN08>4</BGN08>
            </BGN>
            <Loop_1000A>
              <N1>
                <N101>P5</N101>
                <N102><xsl:value-of select="$sponsor"/></N102>
                <N103>FI</N103>
                <N104><xsl:value-of select="$sponsorId"/></N104>
              </N1>
            </Loop_1000A>
            <Loop_1000B>
              <N1>
                <N101>IN</N101>
                <N102><xsl:value-of select="$payer"/></N102>
                <N103>FI</N103>
                <N104><xsl:value-of select="$payerId"/></N104>
              </N1>
            </Loop_1000B>
            <xsl:for-each select="$records">
              <xsl:variable name="mid" select="if (fn:col(.,'MemberId')!='') then fn:col(.,'MemberId') else concat('MEM', position())"/>
              <xsl:variable name="last" select="upper-case(if (fn:col(.,'LastName')!='') then fn:col(.,'LastName') else 'SAMPLE')"/>
              <xsl:variable name="given" select="upper-case(if (fn:col(.,'FirstName')!='') then fn:col(.,'FirstName') else 'MEMBER')"/>
              <xsl:variable name="dob" select="if (fn:col(.,'BirthDate')!='') then fn:col(.,'BirthDate') else '19900101'"/>
              <xsl:variable name="sex" select="upper-case(if (fn:col(.,'GenderCode')!='') then fn:col(.,'GenderCode') else 'U')"/>
              <xsl:variable name="rel" select="if (fn:col(.,'RelationshipCode')!='') then fn:col(.,'RelationshipCode') else '18'"/>
              <xsl:variable name="mtc" select="if (fn:col(.,'MaintenanceTypeCode')!='') then fn:col(.,'MaintenanceTypeCode') else '030'"/>
              <xsl:variable name="plan" select="if (fn:col(.,'PlanId')!='') then fn:col(.,'PlanId') else 'PLANDEMO'"/>
              <xsl:variable name="cov" select="if (fn:col(.,'CoverageStartDate')!='') then fn:col(.,'CoverageStartDate') else '20260101'"/>
              <Loop_2000>
                <INS>
                  <INS01>Y</INS01>
                  <INS02><xsl:value-of select="$rel"/></INS02>
                  <INS03><xsl:value-of select="$mtc"/></INS03>
                  <INS04>XN</INS04>
                  <INS05>A</INS05>
                  <INS08>FT</INS08>
                </INS>
                <REF>
                  <REF01>0F</REF01>
                  <REF02><xsl:value-of select="$mid"/></REF02>
                </REF>
                <Loop_2100A>
                  <NM1>
                    <NM101>IL</NM101>
                    <NM102>1</NM102>
                    <NM103><xsl:value-of select="$last"/></NM103>
                    <NM104><xsl:value-of select="$given"/></NM104>
                    <NM108>34</NM108>
                    <NM109><xsl:value-of select="$mid"/></NM109>
                  </NM1>
                  <DMG>
                    <DMG01>D8</DMG01>
                    <DMG02><xsl:value-of select="$dob"/></DMG02>
                    <DMG03><xsl:value-of select="$sex"/></DMG03>
                  </DMG>
                </Loop_2100A>
                <Loop_2300>
                  <HD>
                    <HD01>030</HD01>
                    <HD03>HLT</HD03>
                    <HD04><xsl:value-of select="$plan"/></HD04>
                  </HD>
                  <DTP>
                    <DTP01>348</DTP01>
                    <DTP02>D8</DTP02>
                    <DTP03><xsl:value-of select="$cov"/></DTP03>
                  </DTP>
                </Loop_2300>
              </Loop_2000>
            </xsl:for-each>
          </Transaction>
        </Group>
      </Interchange>
    </XCSData>
  </xsl:template>
</xsl:stylesheet>
