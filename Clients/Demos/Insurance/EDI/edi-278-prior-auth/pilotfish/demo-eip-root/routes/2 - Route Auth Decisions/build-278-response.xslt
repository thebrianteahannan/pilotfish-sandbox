<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" indent="yes" encoding="UTF-8"/>
  <xsl:variable name="d" select="(//AuthDecision | /AuthDecision)[1]"/>
  <xsl:variable name="trace" select="normalize-space(($d/AuthTraceNumber)[1])"/>
  <xsl:variable name="disp" select="upper-case(normalize-space(($d/Disposition)[1]))"/>
  <xsl:variable name="hcr">
    <xsl:choose>
      <xsl:when test="$disp = 'APPROVED'">A1</xsl:when>
      <xsl:when test="$disp = 'DENIED'">A3</xsl:when>
      <xsl:otherwise>A4</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <xsl:variable name="isa13" select="format-number(number(substring(translate(concat($trace, '000000000'), 'ABCDEFGHIJKLMNOPQRSTUVWXYZ-', ''), 1, 9)), '000000000')"/>
  <xsl:variable name="ctrl" select="format-number(number(substring(translate(concat($trace, '0001'), 'ABCDEFGHIJKLMNOPQRSTUVWXYZ-', ''), 1, 4)), '0001')"/>
  <xsl:template match="/">
    <XCSData>
      <Interchange AuthorizationQual="00" AuthorizationInfo="          "
                   SecurityQual="00" SecurityInfo="          "
                   Date="260813" Time="1200"
                   StandardsId="^" Version="00501" ControlNumber="{$isa13}"
                   AckRequested="0" TestIndicator="T"
                   ElementDelim="*" SubElementDelim=":" RepetitionDelim="^" SegmentDelim="~">
        <SenderId Qualifier="ZZ">PAYERDEMO</SenderId>
        <ReceiverId Qualifier="ZZ">PROVIDERDEMO</ReceiverId>
        <Group GroupType="HI" ApplSender="PAYERDEMO" ApplReceiver="PROVIDERDEMO"
               Date="20260813" Time="1200" ControlNumber="1"
               StandardCode="X" StandardVersion="005010X217">
          <Transaction DocType="278" ControlNumber="{$ctrl}" StandardVersion="005010X217">
            <BHT>
              <BHT01>0007</BHT01><BHT02>11</BHT02>
              <BHT03><xsl:value-of select="$trace"/></BHT03>
              <BHT04>20260813</BHT04><BHT05>1200</BHT05>
            </BHT>
            <Loop_2000A>
              <HL><HL01>1</HL01><HL03>20</HL03><HL04>1</HL04></HL>
              <Loop_2010A>
                <NM1>
                  <NM101>X3</NM101><NM102>2</NM102>
                  <NM103>DEMO PAYOR</NM103>
                  <NM108>PI</NM108><NM109>PAYERDEMO</NM109>
                </NM1>
              </Loop_2010A>
            </Loop_2000A>
            <Loop_2000B>
              <HL><HL01>2</HL01><HL02>1</HL02><HL03>21</HL03><HL04>1</HL04></HL>
              <Loop_2010B>
                <NM1>
                  <NM101>1P</NM101><NM102>2</NM102>
                  <NM103>DEMO PROVIDER</NM103>
                  <NM108>XX</NM108><NM109>1234567893</NM109>
                </NM1>
              </Loop_2010B>
            </Loop_2000B>
            <Loop_2000C>
              <HL><HL01>3</HL01><HL02>2</HL02><HL03>22</HL03><HL04>1</HL04></HL>
              <Loop_2010C>
                <NM1>
                  <NM101>IL</NM101><NM102>1</NM102>
                  <NM103><xsl:value-of select="($d/PatientLastName)[1]"/></NM103>
                  <NM104><xsl:value-of select="($d/PatientFirstName)[1]"/></NM104>
                  <NM108>MI</NM108>
                  <NM109><xsl:value-of select="($d/MemberId)[1]"/></NM109>
                </NM1>
              </Loop_2010C>
            </Loop_2000C>
            <Loop_2000E>
              <HL><HL01>4</HL01><HL02>3</HL02><HL03>EV</HL03><HL04>0</HL04></HL>
              <TRN>
                <TRN01>2</TRN01>
                <TRN02><xsl:value-of select="$trace"/></TRN02>
              </TRN>
              <UM>
                <UM01>HS</UM01><UM02>I</UM02><UM03>1</UM03>
              </UM>
              <HCR>
                <HCR01><xsl:value-of select="$hcr"/></HCR01>
                <HCR02><xsl:value-of select="$trace"/></HCR02>
              </HCR>
              <xsl:if test="$disp = 'INCOMPLETE'">
                <AAA>
                  <AAA01>N</AAA01><AAA03>15</AAA03><AAA04>C</AAA04>
                </AAA>
              </xsl:if>
            </Loop_2000E>
          </Transaction>
        </Group>
      </Interchange>
    </XCSData>
  </xsl:template>
</xsl:stylesheet>
