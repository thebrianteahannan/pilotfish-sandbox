<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:datetime="http://exslt.org/dates-and-times" xmlns:dtFormatter="xalan://com.pilotfish.eip.gui.mapper.util.DateTimeFormatter" exclude-result-prefixes="datetime dtFormatter" version="3.1">
  <xsl:template match="/patients">
    <XCSData>
      <ediroot eid="1">
        <interchange AckRequest="0" Control="000000248" Date="{dtFormatter:format(datetime:date(),'yyyy-MM-dd','MMddyy')}" Standard="ANSI X.12" TestIndicator="P" Time="{dtFormatter:format(datetime:time(),'HH:mm:ss','HHmm')}" Version="00501" eid="1">
          <sender eid="1">
            <address Id="S32433" Qual="ZZ" eid="1" />
          </sender>
          <receiver eid="1">
            <address Id="Zirmed" Qual="ZZ" eid="2" />
          </receiver>
          <group ApplReceiver="Zirmed" ApplSender="S32433" Control="248" Date="20120923" GroupType="HC" StandardCode="X" StandardVersion="005010X222A1" Time="{dtFormatter:format(datetime:time(),'HH:mm:ss','HHmm')}" eid="1">
            <transaction Control="000000248" DocType="837" Name="Health Care Claim" eid="1">
              <BHT eid="1">
                <BHT01 eid="1">0019</BHT01>
                <BHT02 eid="1">00</BHT02>
                <BHT03 eid="1">000000248</BHT03>
                <BHT04 eid="1">20120923</BHT04>
                <BHT05 eid="1">2017</BHT05>
                <BHT06 eid="1">CH</BHT06>
              </BHT>
              <LOOP eid="1">
                <NM1 eid="1">
                  <NM101 eid="1">41</NM101>
                  <NM102 eid="1">2</NM102>
                  <NM103 eid="1">Mayo Clinic</NM103>
                  <NM108 eid="1">46</NM108>
                  <NM109 eid="1">S32433</NM109>
                </NM1>
                <PER eid="1">
                  <PER01 eid="1">IC</PER01>
                  <PER02 eid="1">Mayo Clinic</PER02>
                  <PER03 eid="1">TE</PER03>
                  <PER04 eid="1">9547487111</PER04>
                  <PER05 eid="1">FX</PER05>
                  <PER06 eid="1">9547487222</PER06>
                </PER>
              </LOOP>
              <LOOP eid="2">
                <NM1 eid="2">
                  <NM101 eid="2">40</NM101>
                  <NM102 eid="2">2</NM102>
                  <NM103 eid="2">Zirmed</NM103>
                  <NM108 eid="2">46</NM108>
                  <NM109 eid="2">Zirmed</NM109>
                </NM1>
              </LOOP>
              <xsl:for-each select="patient">
                <LOOP eid="1">
                  <HL eid="1">
                    <HL01 eid="1">1</HL01>
                    <HL03 eid="1">20</HL03>
                    <HL04 eid="1">1</HL04>
                  </HL>
                  <LOOP eid="1">
                    <NM1 eid="1">
                      <NM101 eid="3">85</NM101>
                      <NM102 eid="3">1</NM102>
                      <NM103 eid="1">Sean</NM103>
                      <NM104 eid="1">Smith</NM104>
                      <NM105 eid="1">K</NM105>
                      <NM108 eid="3">XX</NM108>
                      <NM109 eid="1">6565656565</NM109>
                    </NM1>
                    <N3 eid="1">
                      <N301 eid="1">5537 KINGS HIGHWAY</N301>
                      <N302 eid="1">APT 6G</N302>
                    </N3>
                    <N4 eid="1">
                      <N401 eid="1">Frisco City</N401>
                      <N402 eid="1">NY</N402>
                      <N403 eid="1">112348888</N403>
                    </N4>
                    <REF eid="1">
                      <REF01 eid="1">EI</REF01>
                      <REF02 eid="1">222222222</REF02>
                    </REF>
                  </LOOP>
                </LOOP>
                <LOOP eid="2">
                  <HL eid="2">
                    <HL01 eid="2">2</HL01>
                    <HL02 eid="1">1</HL02>
                    <HL03 eid="2">22</HL03>
                    <HL04 eid="2">0</HL04>
                  </HL>
                  <SBR eid="1">
                    <SBR01 eid="1">P</SBR01>
                    <SBR02 eid="1">18</SBR02>
                    <SBR03 eid="1">K34532</SBR03>
                    <SBR04 eid="1">GFAMPLAN</SBR04>
                    <SBR09 eid="1">ZZ</SBR09>
                  </SBR>
                  <LOOP eid="2">
                    <!--Patient Mapping-->
                    <NM1 eid="2">
                      <NM101 eid="4">IL</NM101>
                      <NM102 eid="4">1</NM102>
                      <NM103 eid="2">
                        SIMMONS
                        <xsl:value-of select="lastName" />
                      </NM103>
                      <NM104 eid="2">
                        <xsl:value-of select="firstName" />
                      </NM104>
                      <NM108 eid="4">MI</NM108>
                      <NM109 eid="2">
                        <xsl:value-of select="mrn" />
                      </NM109>
                    </NM1>
                    <N3 eid="2">
                      <N301 eid="2">
                        <xsl:value-of select="address" />
                      </N301>
                      <N302 eid="2" />
                    </N3>
                    <N4 eid="2">
                      <N401 eid="2">
                        <xsl:value-of select="city" />
                      </N401>
                      <N402 eid="2">
                        <xsl:value-of select="state" />
                      </N402>
                      <N403 eid="2">
                        <xsl:value-of select="postalCode" />
                      </N403>
                    </N4>
                    <DMG eid="1">
                      <DMG01 eid="1">D8</DMG01>
                      <DMG02 eid="1">
                        <xsl:value-of select="dob" />
                      </DMG02>
                      <DMG03 eid="1">M</DMG03>
                    </DMG>
                  </LOOP>
                  <LOOP eid="3">
                    <NM1 eid="3">
                      <NM101 eid="5">PR</NM101>
                      <NM102 eid="5">2</NM102>
                      <NM103 eid="3">AETNA HEALTH INC</NM103>
                      <NM108 eid="5">PI</NM108>
                      <NM109 eid="3">9393</NM109>
                    </NM1>
                    <N3 eid="3">
                      <N301 eid="3">P.O. BOX 1125</N301>
                    </N3>
                    <N4 eid="3">
                      <N401 eid="3">Blue Bell</N401>
                      <N402 eid="3">PA</N402>
                      <N403 eid="3">19422</N403>
                    </N4>
                  </LOOP>
                  <LOOP eid="1">
                    <CLM eid="1">
                      <CLM01 eid="1">249</CLM01>
                      <CLM02 eid="1">60</CLM02>
                      <CLM05 Composite="yes" eid="1">
                        <subelement Sequence="1" eid="1">11</subelement>
                        <subelement Sequence="2" eid="2">B</subelement>
                        <subelement Sequence="3" eid="3">1</subelement>
                      </CLM05>
                      <CLM06 eid="1">Y</CLM06>
                      <CLM07 eid="1">A</CLM07>
                      <CLM08 eid="1">Y</CLM08>
                      <CLM09 eid="1">Y</CLM09>
                    </CLM>
                    <REF eid="1">
                      <REF01 eid="1">X4</REF01>
                      <REF02 eid="1">CL324234</REF02>
                    </REF>
                    <HI eid="1">
                      <HI01 Composite="yes" eid="1">
                        <subelement Sequence="1" eid="4">BK</subelement>
                        <subelement Sequence="2" eid="5">41012</subelement>
                      </HI01>
                    </HI>
                    <LOOP eid="1">
                      <NM1 eid="1">
                        <NM101 eid="1">82</NM101>
                        <NM102 eid="1">1</NM102>
                        <NM103 eid="1">Sean</NM103>
                        <NM104 eid="1">Smith</NM104>
                        <NM105 eid="1">K</NM105>
                        <NM108 eid="1">XX</NM108>
                        <NM109 eid="1">6565656565</NM109>
                      </NM1>
                    </LOOP>
                    <LOOP eid="2">
                      <NM1 eid="2">
                        <NM101 eid="2">77</NM101>
                        <NM102 eid="2">2</NM102>
                        <NM103 eid="2">NY Office</NM103>
                        <NM108 eid="2">XX</NM108>
                        <NM109 eid="2">1336177328</NM109>
                      </NM1>
                      <N3 eid="1">
                        <N301 eid="1">5081 Tellus. Avenue</N301>
                        <N302 eid="1">668-2204 Non Rd.</N302>
                      </N3>
                      <N4 eid="1">
                        <N401 eid="1">White Plains</N401>
                        <N402 eid="1">NY</N402>
                        <N403 eid="1">809051232</N403>
                      </N4>
                      <REF eid="2">
                        <REF01 eid="2">LU</REF01>
                        <REF02 eid="2">484345</REF02>
                      </REF>
                    </LOOP>
                    <LOOP eid="1">
                      <LX eid="1">
                        <LX01 eid="1">1</LX01>
                      </LX>
                      <SV1 eid="1">
                        <SV101 Composite="yes" eid="1">
                          <subelement Sequence="1" eid="6">HC</subelement>
                          <subelement Sequence="2" eid="7">99214</subelement>
                        </SV101>
                        <SV102 eid="1">60</SV102>
                        <SV103 eid="1">UN</SV103>
                        <SV104 eid="1">1</SV104>
                        <SV105 eid="1">11</SV105>
                        <SV107 eid="1">1</SV107>
                      </SV1>
                      <DTP eid="1">
                        <DTP01 eid="1">472</DTP01>
                        <DTP02 eid="1">RD8</DTP02>
                        <DTP03 eid="1">20120921-20120921</DTP03>
                      </DTP>
                      <REF eid="3">
                        <REF01 eid="3">6R</REF01>
                        <REF02 eid="3">1134</REF02>
                      </REF>
                    </LOOP>
                  </LOOP>
                </LOOP>
              </xsl:for-each>
            </transaction>
          </group>
        </interchange>
      </ediroot>
    </XCSData>
  </xsl:template>
</xsl:stylesheet>

