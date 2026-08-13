<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  exclude-result-prefixes="xsl xs">
  <!--
    ClaimStatusDecision XML → PilotFish EDI XML (277 response / 005010X212).
    EDITransformationProcessor (XML to EDI) emits the X12 wire.
    Do not hardcode ISA*/GS* text here — map structure only.
  -->
  <xsl:output method="xml" indent="yes" encoding="UTF-8"/>

  <xsl:variable name="trace" select="normalize-space((//TraceNumber)[1])"/>
  <xsl:variable name="member" select="normalize-space((//MemberId)[1])"/>
  <xsl:variable name="claim" select="normalize-space((//ClaimId)[1])"/>
  <xsl:variable name="amount" select="normalize-space((//Amount)[1])"/>
  <xsl:variable name="status" select="normalize-space((//StatusCode)[1])"/>
  <xsl:variable name="statusMsg" select="normalize-space((//StatusMessage)[1])"/>
  <xsl:variable name="bucket" select="normalize-space((//DecisionBucket)[1])"/>
  <xsl:variable name="reason" select="normalize-space((//Reason)[1])"/>
  <xsl:variable name="statusSafe" select="if ($status != '') then $status else 'E1'"/>
  <xsl:variable name="digits" select="translate($trace, 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-_', '')"/>
  <xsl:variable name="isa13" select="
    if ($digits != '' and $digits castable as xs:integer)
    then format-number(xs:integer(substring(concat($digits, '000000277'), 1, 9)), '000000000')
    else '000000277'"/>
  <xsl:variable name="st02" select="
    if ($digits != '' and $digits castable as xs:integer)
    then format-number(xs:integer(substring(concat($digits, '0001'), 1, 4)), '0001')
    else '0001'"/>
  <xsl:variable name="traceSafe" select="if ($trace != '') then $trace else 'TRACE001'"/>
  <xsl:variable name="dateSafe" select="'20260812'"/>
  <xsl:variable name="yymmdd" select="'260812'"/>
  <xsl:variable name="amtSafe" select="if ($amount != '') then $amount else '0'"/>

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
               StandardCode="X" StandardVersion="005010X212">
          <Transaction DocType="277" ControlNumber="{$st02}" StandardVersion="005010X212">
            <ST>
              <ST01>277</ST01>
              <ST02><xsl:value-of select="$st02"/></ST02>
              <ST03>005010X212</ST03>
            </ST>
            <BHT>
              <BHT01>0010</BHT01>
              <BHT02>08</BHT02>
              <BHT03><xsl:value-of select="$traceSafe"/></BHT03>
              <BHT04><xsl:value-of select="$dateSafe"/></BHT04>
              <BHT05>1315</BHT05>
              <BHT06>DG</BHT06>
            </BHT>
            <HL>
              <HL01>1</HL01>
              <HL03>20</HL03>
              <HL04>1</HL04>
            </HL>
            <NM1>
              <NM101>PR</NM101>
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
              <NM101>41</NM101>
              <NM102>2</NM102>
              <NM103>DEMO RECEIVER</NM103>
              <NM108>46</NM108>
              <NM109>RECVDEMO</NM109>
            </NM1>
            <HL>
              <HL01>3</HL01>
              <HL02>2</HL02>
              <HL03>19</HL03>
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
              <HL01>4</HL01>
              <HL02>3</HL02>
              <HL03>22</HL03>
              <HL04>0</HL04>
            </HL>
            <NM1>
              <NM101>IL</NM101>
              <NM102>1</NM102>
              <NM103>MEMBER</NM103>
              <NM104>DEMO</NM104>
              <NM108>MI</NM108>
              <NM109><xsl:value-of select="if ($member != '') then $member else 'UNKNOWN'"/></NM109>
            </NM1>
            <TRN>
              <TRN01>2</TRN01>
              <TRN02><xsl:value-of select="$traceSafe"/></TRN02>
            </TRN>
            <STC>
              <STC01>
                <STC01_1><xsl:value-of select="$statusSafe"/></STC01_1>
              </STC01>
              <STC02><xsl:value-of select="$dateSafe"/></STC02>
              <STC04><xsl:value-of select="$amtSafe"/></STC04>
            </STC>
            <xsl:if test="string-length($claim) &gt; 0">
              <REF>
                <REF01>EJ</REF01>
                <REF02><xsl:value-of select="$claim"/></REF02>
              </REF>
            </xsl:if>
            <REF>
              <REF01>D9</REF01>
              <REF02><xsl:value-of select="if ($reason != '') then $reason else $statusMsg"/></REF02>
            </REF>
            <REF>
              <REF01>1K</REF01>
              <REF02><xsl:value-of select="concat('DEMO-', $bucket)"/></REF02>
            </REF>
          </Transaction>
        </Group>
      </Interchange>
    </XCSData>
  </xsl:template>
</xsl:stylesheet>
