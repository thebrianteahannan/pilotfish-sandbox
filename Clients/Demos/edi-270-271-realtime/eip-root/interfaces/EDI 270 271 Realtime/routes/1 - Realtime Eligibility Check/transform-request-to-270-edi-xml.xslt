<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <!-- EligibilityRequest XML → PilotFish EDI XML (270 / 005010X279A1). -->
  <xsl:output method="xml" indent="yes" encoding="UTF-8"/>

  <xsl:variable name="r" select="(//EligibilityRequest | /EligibilityRequest)[1]"/>
  <xsl:variable name="memberId" select="normalize-space(($r/MemberId)[1])"/>
  <xsl:variable name="last" select="upper-case(normalize-space(($r/LastName)[1]))"/>
  <xsl:variable name="first" select="upper-case(normalize-space(($r/FirstName)[1]))"/>
  <xsl:variable name="dob" select="normalize-space(($r/BirthDate)[1])"/>
  <xsl:variable name="gender" select="upper-case(normalize-space(($r/Gender)[1]))"/>
  <xsl:variable name="payerId" select="normalize-space(($r/PayerId)[1])"/>
  <xsl:variable name="payerName" select="normalize-space(($r/PayerName)[1])"/>
  <xsl:variable name="npi" select="normalize-space(($r/ProviderNpi)[1])"/>
  <xsl:variable name="providerName" select="normalize-space(($r/ProviderName)[1])"/>
  <xsl:variable name="svcType" select="normalize-space(($r/ServiceTypeCode)[1])"/>
  <xsl:variable name="trace" select="normalize-space(($r/TraceNumber)[1])"/>
  <xsl:variable name="svcDate" select="normalize-space(($r/ServiceDate)[1])"/>
  <xsl:variable name="isa13" select="format-number(number(substring(translate($trace,'ABCDEFGHIJKLMNOPQRSTUVWXYZ-',''),1,9)), '000000000')"/>
  <xsl:variable name="ctrl" select="format-number(number(substring(translate($trace,'ABCDEFGHIJKLMNOPQRSTUVWXYZ-',''),1,4)), '0001')"/>
  <xsl:variable name="yymmdd" select="substring($svcDate, 3, 6)"/>
  <xsl:variable name="payerIdSafe" select="if ($payerId!='') then $payerId else 'MOCKPAYER'"/>
  <xsl:variable name="payerNameSafe" select="if ($payerName!='') then $payerName else 'MOCK PAYER'"/>
  <xsl:variable name="npiSafe" select="if ($npi!='') then $npi else '1234567893'"/>
  <xsl:variable name="providerSafe" select="if ($providerName!='') then $providerName else 'PILOTFISH DEMO CLINIC'"/>
  <xsl:variable name="svcSafe" select="if ($svcType!='') then $svcType else '30'"/>
  <xsl:variable name="traceSafe" select="if ($trace!='') then $trace else 'TRACE001'"/>
  <xsl:variable name="dateSafe" select="if ($svcDate!='') then $svcDate else '20260804'"/>

  <xsl:template match="/">
    <XCSData>
      <Interchange AuthorizationQual="00" AuthorizationInfo="          "
                   SecurityQual="00" SecurityInfo="          "
                   Date="{$yymmdd}" Time="1200"
                   StandardsId="^" Version="00501" ControlNumber="{$isa13}"
                   AckRequested="0" TestIndicator="T"
                   ElementDelim="*" SubElementDelim=":" RepetitionDelim="^" SegmentDelim="~">
        <SenderId Qualifier="ZZ">CLINICDEMO</SenderId>
        <ReceiverId Qualifier="ZZ"><xsl:value-of select="$payerIdSafe"/></ReceiverId>
        <Group GroupType="HS" ApplSender="CLINICDEMO" ApplReceiver="{$payerIdSafe}"
               Date="{$dateSafe}" Time="1200" ControlNumber="1"
               StandardCode="X" StandardVersion="005010X279A1">
          <Transaction DocType="270" ControlNumber="{$ctrl}" StandardVersion="005010X279A1">
            <BHT>
              <BHT01>0022</BHT01>
              <BHT02>13</BHT02>
              <BHT03><xsl:value-of select="$traceSafe"/></BHT03>
              <BHT04><xsl:value-of select="$dateSafe"/></BHT04>
              <BHT05>1200</BHT05>
            </BHT>
            <Loop_2000A>
              <HL><HL01>1</HL01><HL03>20</HL03><HL04>1</HL04></HL>
              <Loop_2100A>
                <NM1>
                  <NM101>PR</NM101><NM102>2</NM102>
                  <NM103><xsl:value-of select="$payerNameSafe"/></NM103>
                  <NM108>PI</NM108><NM109><xsl:value-of select="$payerIdSafe"/></NM109>
                </NM1>
              </Loop_2100A>
            </Loop_2000A>
            <Loop_2000B>
              <HL><HL01>2</HL01><HL02>1</HL02><HL03>21</HL03><HL04>1</HL04></HL>
              <Loop_2100B>
                <NM1>
                  <NM101>1P</NM101><NM102>2</NM102>
                  <NM103><xsl:value-of select="$providerSafe"/></NM103>
                  <NM108>XX</NM108><NM109><xsl:value-of select="$npiSafe"/></NM109>
                </NM1>
              </Loop_2100B>
            </Loop_2000B>
            <Loop_2000C>
              <HL><HL01>3</HL01><HL02>2</HL02><HL03>22</HL03><HL04>0</HL04></HL>
              <TRN>
                <TRN01>1</TRN01>
                <TRN02><xsl:value-of select="$traceSafe"/></TRN02>
                <TRN03>1<xsl:value-of select="$npiSafe"/></TRN03>
              </TRN>
              <Loop_2100C>
                <NM1>
                  <NM101>IL</NM101><NM102>1</NM102>
                  <NM103><xsl:value-of select="$last"/></NM103>
                  <NM104><xsl:value-of select="$first"/></NM104>
                  <NM108>MI</NM108>
                  <NM109><xsl:value-of select="$memberId"/></NM109>
                </NM1>
                <DMG>
                  <DMG01>D8</DMG01>
                  <DMG02><xsl:value-of select="$dob"/></DMG02>
                  <DMG03><xsl:value-of select="$gender"/></DMG03>
                </DMG>
                <DTP>
                  <DTP01>291</DTP01>
                  <DTP02>D8</DTP02>
                  <DTP03><xsl:value-of select="$dateSafe"/></DTP03>
                </DTP>
                <EQ>
                  <EQ01><xsl:value-of select="$svcSafe"/></EQ01>
                </EQ>
              </Loop_2100C>
            </Loop_2000C>
          </Transaction>
        </Group>
      </Interchange>
    </XCSData>
  </xsl:template>
</xsl:stylesheet>
