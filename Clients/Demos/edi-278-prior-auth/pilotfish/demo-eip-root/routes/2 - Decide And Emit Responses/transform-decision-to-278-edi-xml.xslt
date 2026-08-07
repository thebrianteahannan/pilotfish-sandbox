<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  exclude-result-prefixes="xsl xs">
  <!--
    AuthDecision XML → PilotFish EDI XML (278 response / 005010X217).
    EDITransformationProcessor (XML to EDI) emits the X12 wire.
    Do not hardcode ISA*/GS* text here — map structure only.
  -->
  <xsl:output method="xml" indent="yes" encoding="UTF-8"/>

  <xsl:variable name="trace" select="normalize-space((//AuthTraceNumber)[1])"/>
  <xsl:variable name="member" select="normalize-space((//MemberId)[1])"/>
  <xsl:variable name="last" select="normalize-space((//PatientLastName)[1])"/>
  <xsl:variable name="first" select="normalize-space((//PatientFirstName)[1])"/>
  <xsl:variable name="proc" select="normalize-space((//ProcedureCode)[1])"/>
  <xsl:variable name="dx" select="normalize-space((//DiagnosisCode)[1])"/>
  <xsl:variable name="bucket" select="normalize-space((//DecisionBucket)[1])"/>
  <xsl:variable name="reason" select="normalize-space((//Reason)[1])"/>
  <xsl:variable name="hicode" select="
    if ($bucket = 'approved') then 'A1'
    else if ($bucket = 'denied') then 'A3'
    else if ($bucket = 'pended') then 'A4'
    else 'A3'"/>
  <xsl:variable name="hctext" select="
    if ($bucket = 'approved') then 'Certified in total'
    else if ($bucket = 'denied') then 'Not certified'
    else if ($bucket = 'pended') then 'Pended'
    else 'Not certified - incomplete'"/>
  <xsl:variable name="digits" select="translate($trace, 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-_', '')"/>
  <xsl:variable name="isa13" select="
    if ($digits != '' and $digits castable as xs:integer)
    then format-number(xs:integer(substring(concat($digits, '000000279'), 1, 9)), '000000000')
    else '000000279'"/>
  <xsl:variable name="st02" select="
    if ($digits != '' and $digits castable as xs:integer)
    then format-number(xs:integer(substring(concat($digits, '0001'), 1, 4)), '0001')
    else '0001'"/>
  <xsl:variable name="traceSafe" select="if ($trace != '') then $trace else 'TRACE001'"/>
  <xsl:variable name="dateSafe" select="'20260807'"/>
  <xsl:variable name="yymmdd" select="'260807'"/>

  <xsl:template match="/">
    <XCSData>
      <Interchange AuthorizationQual="00" AuthorizationInfo="          "
                   SecurityQual="00" SecurityInfo="          "
                   Date="{$yymmdd}" Time="1315"
                   StandardsId="^" Version="00501" ControlNumber="{$isa13}"
                   AckRequested="0" TestIndicator="T"
                   ElementDelim="*" SubElementDelim=":" RepetitionDelim="^" SegmentDelim="~">
        <SenderId Qualifier="ZZ">PAYERDEMO</SenderId>
        <ReceiverId Qualifier="ZZ">PROVIDERDEMO</ReceiverId>
        <Group GroupType="HN" ApplSender="PAYERDEMO" ApplReceiver="PROVIDERDEMO"
               Date="{$dateSafe}" Time="1315" ControlNumber="1"
               StandardCode="X" StandardVersion="005010X217">
          <Transaction DocType="278" ControlNumber="{$st02}" StandardVersion="005010X217">
            <ST>
              <ST01>278</ST01>
              <ST02><xsl:value-of select="$st02"/></ST02>
              <ST03>005010X217</ST03>
            </ST>
            <BHT>
              <BHT01>0007</BHT01>
              <BHT02>11</BHT02>
              <BHT03><xsl:value-of select="$traceSafe"/></BHT03>
              <BHT04><xsl:value-of select="$dateSafe"/></BHT04>
              <BHT05>1315</BHT05>
            </BHT>
            <HL>
              <HL01>1</HL01>
              <HL03>20</HL03>
              <HL04>1</HL04>
            </HL>
            <NM1>
              <NM101>X3</NM101>
              <NM102>2</NM102>
              <NM103>DEMO PAYOR</NM103>
              <NM108>PI</NM108>
              <NM109>PAYERDEMO</NM109>
            </NM1>
            <HL>
              <HL01>2</HL01>
              <HL02>1</HL02>
              <HL03>21</HL03>
              <HL04>1</HL04>
            </HL>
            <NM1>
              <NM101>1P</NM101>
              <NM102>2</NM102>
              <NM103>DEMO PROVIDER</NM103>
              <NM108>XX</NM108>
              <NM109>1234567893</NM109>
            </NM1>
            <HL>
              <HL01>3</HL01>
              <HL02>2</HL02>
              <HL03>22</HL03>
              <HL04>1</HL04>
            </HL>
            <NM1>
              <NM101>IL</NM101>
              <NM102>1</NM102>
              <NM103><xsl:value-of select="$last"/></NM103>
              <NM104><xsl:value-of select="$first"/></NM104>
              <NM108>MI</NM108>
              <NM109><xsl:value-of select="$member"/></NM109>
            </NM1>
            <HL>
              <HL01>4</HL01>
              <HL02>3</HL02>
              <HL03>EV</HL03>
              <HL04>0</HL04>
            </HL>
            <TRN>
              <TRN01>2</TRN01>
              <TRN02><xsl:value-of select="$traceSafe"/></TRN02>
            </TRN>
            <xsl:choose>
              <xsl:when test="$bucket = 'incomplete'">
                <AAA>
                  <AAA01>Y</AAA01>
                  <AAA03>33</AAA03>
                  <AAA04>C</AAA04>
                </AAA>
              </xsl:when>
              <xsl:otherwise>
                <AAA>
                  <AAA01>N</AAA01>
                </AAA>
              </xsl:otherwise>
            </xsl:choose>
            <HCR>
              <HCR01><xsl:value-of select="$hicode"/></HCR01>
              <HCR02>DEMOAUTH</HCR02>
              <HCR03><xsl:value-of select="$hctext"/></HCR03>
            </HCR>
            <REF>
              <REF01>NT</REF01>
              <REF02><xsl:value-of select="$reason"/></REF02>
            </REF>
            <xsl:if test="string-length($dx) &gt; 0">
              <HI>
                <HI01>
                  <HI01_1>ABK</HI01_1>
                  <HI01_2><xsl:value-of select="$dx"/></HI01_2>
                </HI01>
              </HI>
            </xsl:if>
            <xsl:if test="string-length($proc) &gt; 0">
              <SV1>
                <SV101>
                  <SV101_1>HC</SV101_1>
                  <SV101_2><xsl:value-of select="$proc"/></SV101_2>
                </SV101>
              </SV1>
            </xsl:if>
          </Transaction>
        </Group>
      </Interchange>
    </XCSData>
  </xsl:template>
</xsl:stylesheet>
