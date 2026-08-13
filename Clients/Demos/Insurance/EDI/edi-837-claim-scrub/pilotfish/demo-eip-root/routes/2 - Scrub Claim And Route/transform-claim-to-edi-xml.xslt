<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" indent="yes" encoding="UTF-8"/>
  <xsl:variable name="c" select="(//CLAIM | //Claim | /CLAIM | /Claim)[1]"/>
  <xsl:variable name="claimId" select="normalize-space(($c/CLAIMID | $c/ClaimId)[1])"/>
  <xsl:variable name="claimNumber" select="normalize-space(($c/CLAIMNUMBER | $c/ClaimNumber)[1])"/>
  <xsl:variable name="svcDate" select="normalize-space(($c/SERVICEDATE | $c/ServiceDate)[1])"/>
  <xsl:variable name="amount" select="normalize-space(($c/CLAIMAMOUNT | $c/ClaimAmount)[1])"/>
  <xsl:variable name="pos" select="normalize-space(($c/PLACEOFSERVICE | $c/PlaceOfService)[1])"/>
  <xsl:variable name="dx" select="translate(normalize-space(($c/DIAGNOSISCODE | $c/DiagnosisCode)[1]), '.', '')"/>
  <xsl:variable name="lines" select="tokenize(normalize-space(($c/LINESBLOB | $c/LinesBlob)[1]), '\|')"/>
  <xsl:variable name="ctrl" select="format-number(number($claimId), '0000')"/>
  <xsl:variable name="isa13" select="format-number(number($claimId), '000000000')"/>
  <xsl:variable name="payerId" select="normalize-space(($c/PAYERID | $c/PayerId)[1])"/>
  <xsl:variable name="payerName" select="normalize-space(($c/PAYERNAME | $c/PayerName)[1])"/>
  <xsl:variable name="refNpi" select="normalize-space(($c/REFERRINGNPI | $c/ReferringNpi)[1])"/>

  <xsl:template match="/">
    <XCSData>
      <Interchange AuthorizationQual="00" AuthorizationInfo="          "
                   SecurityQual="00" SecurityInfo="          "
                   Date="{substring($svcDate, 3, 6)}" Time="1200"
                   StandardsId="^" Version="00501" ControlNumber="{$isa13}"
                   AckRequested="0" TestIndicator="T"
                   ElementDelim="*" SubElementDelim=":" RepetitionDelim="^" SegmentDelim="~">
        <SenderId Qualifier="ZZ">PILOTFISHDEMO</SenderId>
        <ReceiverId Qualifier="ZZ"><xsl:value-of select="$payerId"/></ReceiverId>
        <Group GroupType="HC" ApplSender="PILOTFISHDEMO" ApplReceiver="{$payerId}"
               Date="{$svcDate}" Time="1200" ControlNumber="{$claimId}"
               StandardCode="X" StandardVersion="005010X222A1">
          <Transaction DocType="837" ControlNumber="{$ctrl}" StandardVersion="005010X222A1">
            <ST>
              <ST01>837</ST01>
              <ST02><xsl:value-of select="$ctrl"/></ST02>
              <ST03>005010X222A1</ST03>
            </ST>
            <BHT>
              <BHT01>0019</BHT01>
              <BHT02>00</BHT02>
              <BHT03><xsl:value-of select="$claimNumber"/></BHT03>
              <BHT04><xsl:value-of select="$svcDate"/></BHT04>
              <BHT05>1200</BHT05>
              <BHT06>CH</BHT06>
            </BHT>
            <Loop_1000A>
              <NM1>
                <NM101>41</NM101><NM102>2</NM102>
                <NM103>PILOTFISH DEMO BILLING</NM103>
                <NM108>46</NM108><NM109>PFDEMO01</NM109>
              </NM1>
              <PER>
                <PER01>IC</PER01><PER02>DEMO SUPPORT</PER02>
                <PER03>TE</PER03><PER04>8605550100</PER04>
              </PER>
            </Loop_1000A>
            <Loop_1000B>
              <NM1>
                <NM101>40</NM101><NM102>2</NM102>
                <NM103><xsl:value-of select="$payerName"/></NM103>
                <NM108>46</NM108><NM109><xsl:value-of select="$payerId"/></NM109>
              </NM1>
            </Loop_1000B>
            <Loop_2000A>
              <HL><HL01>1</HL01><HL03>20</HL03><HL04>1</HL04></HL>
              <Loop_2010AA>
                <NM1>
                  <NM101>85</NM101><NM102>2</NM102>
                  <NM103><xsl:value-of select="($c/BILLINGORGNAME | $c/BillingOrgName)[1]"/></NM103>
                  <NM108>XX</NM108>
                  <NM109><xsl:value-of select="($c/BILLINGNPI | $c/BillingNpi)[1]"/></NM109>
                </NM1>
                <N3><N301><xsl:value-of select="($c/BILLINGSTREET | $c/BillingStreet)[1]"/></N301></N3>
                <N4>
                  <N401><xsl:value-of select="($c/BILLINGCITY | $c/BillingCity)[1]"/></N401>
                  <N402><xsl:value-of select="($c/BILLINGSTATE | $c/BillingState)[1]"/></N402>
                  <N403><xsl:value-of select="($c/BILLINGZIP | $c/BillingZip)[1]"/></N403>
                </N4>
              </Loop_2010AA>
            </Loop_2000A>
            <Loop_2000B>
              <HL><HL01>2</HL01><HL02>1</HL02><HL03>22</HL03><HL04>0</HL04></HL>
              <SBR><SBR01>P</SBR01><SBR02>18</SBR02><SBR09>CI</SBR09></SBR>
              <Loop_2010BA>
                <NM1>
                  <NM101>IL</NM101><NM102>1</NM102>
                  <NM103><xsl:value-of select="($c/LASTNAME | $c/LastName)[1]"/></NM103>
                  <NM104><xsl:value-of select="($c/FIRSTNAME | $c/FirstName)[1]"/></NM104>
                  <NM108>MI</NM108>
                  <NM109><xsl:value-of select="($c/MEMBERID | $c/MemberId)[1]"/></NM109>
                </NM1>
                <N3><N301><xsl:value-of select="($c/STREET | $c/Street)[1]"/></N301></N3>
                <N4>
                  <N401><xsl:value-of select="($c/CITY | $c/City)[1]"/></N401>
                  <N402><xsl:value-of select="($c/STATE | $c/State)[1]"/></N402>
                  <N403><xsl:value-of select="($c/ZIP | $c/Zip)[1]"/></N403>
                </N4>
                <DMG>
                  <DMG01>D8</DMG01>
                  <DMG02><xsl:value-of select="($c/BIRTHDATE | $c/BirthDate)[1]"/></DMG02>
                  <DMG03><xsl:value-of select="($c/SEX | $c/Sex)[1]"/></DMG03>
                </DMG>
              </Loop_2010BA>
              <Loop_2300>
                <CLM>
                  <CLM01><xsl:value-of select="$claimNumber"/></CLM01>
                  <CLM02><xsl:value-of select="$amount"/></CLM02>
                  <CLM05>
                    <CLM05_1><xsl:value-of select="$pos"/></CLM05_1>
                    <CLM05_2>B</CLM05_2>
                    <CLM05_3>1</CLM05_3>
                  </CLM05>
                  <CLM06>Y</CLM06><CLM07>A</CLM07><CLM08>Y</CLM08><CLM09>Y</CLM09>
                </CLM>
                <HI>
                  <HI01>
                    <HI01_1>ABK</HI01_1>
                    <HI01_2><xsl:value-of select="$dx"/></HI01_2>
                  </HI01>
                </HI>
                <xsl:if test="$refNpi != ''">
                  <Loop_2310A>
                    <NM1>
                      <NM101>DN</NM101><NM102>1</NM102>
                      <NM103>REFERRING</NM103><NM104>PROVIDER</NM104>
                      <NM108>XX</NM108>
                      <NM109><xsl:value-of select="$refNpi"/></NM109>
                    </NM1>
                  </Loop_2310A>
                </xsl:if>
                <xsl:for-each select="$lines[. != '']">
                  <xsl:variable name="p" select="tokenize(., '\^')"/>
                  <Loop_2400>
                    <LX><LX01><xsl:value-of select="$p[1]"/></LX01></LX>
                    <SV1>
                      <SV101>
                        <SV101_1>HC</SV101_1>
                        <SV101_2><xsl:value-of select="$p[2]"/></SV101_2>
                        <xsl:if test="$p[3] != ''"><SV101_3><xsl:value-of select="$p[3]"/></SV101_3></xsl:if>
                      </SV101>
                      <SV102><xsl:value-of select="$p[4]"/></SV102>
                      <SV103>UN</SV103>
                      <SV104><xsl:value-of select="$p[5]"/></SV104>
                      <SV107>1</SV107>
                    </SV1>
                    <DTP>
                      <DTP01>472</DTP01>
                      <DTP02>D8</DTP02>
                      <DTP03><xsl:value-of select="$p[6]"/></DTP03>
                    </DTP>
                  </Loop_2400>
                </xsl:for-each>
              </Loop_2300>
            </Loop_2000B>
          </Transaction>
        </Group>
      </Interchange>
    </XCSData>
  </xsl:template>
</xsl:stylesheet>
