<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:datetime="http://exslt.org/dates-and-times" xmlns:dtFormatter="xalan://com.pilotfish.eip.gui.mapper.util.DateTimeFormatter" xmlns:mr="mr" xmlns:pf="pf" exclude-result-prefixes="datetime dtFormatter" version="3.1">
  <xsl:param name="partitionName" />
  <xsl:param name="facilityName" />
  <xsl:param name="facilityCode" />
  <xsl:param name="softwareID" />
  <xsl:param name="accountNumAlpha" />
  <xsl:param name="splitPrefix" />
  <xsl:param name="splitShortName" />
  <xsl:param name="isSpecAlphaSplit" />
  <xsl:template match="/XCSData">
    <XCSData>
      <xsl:variable name="datetime" select="substring(translate(datetime:dateTime(), '-T:', ''), 1, 12)" />
      <xsl:for-each select="//XCSRecord[string-length(PatientName) &gt; 0]">
        <!--ADT_A01-->
        <ADT_A01>
          <!--MSH-->
          <MSH>
            <MSH.1>
              <xsl:text>|</xsl:text>
            </MSH.1>
            <MSH.2>
              <xsl:text>^~\&amp;</xsl:text>
            </MSH.2>
            <MSH.3>
              <xsl:text>VWE</xsl:text>
            </MSH.3>
            <MSH.4>
              <xsl:choose>
                <xsl:when test="string-length($isSpecAlphaSplit) != 0">
                  <xsl:value-of select="$splitPrefix" />
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="$facilityCode" />
                </xsl:otherwise>
              </xsl:choose>
            </MSH.4>
            <MSH.5>
              <xsl:choose>
                <xsl:when test="string-length($isSpecAlphaSplit) != 0">
                  <xsl:value-of select="$splitShortName" />
                </xsl:when>
                <xsl:when test="string-length($splitShortName) != 0">
                  <xsl:value-of select="$splitShortName" />
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="$facilityName" />
                </xsl:otherwise>
              </xsl:choose>
            </MSH.5>
            <MSH.6>
              <xsl:value-of select="$partitionName" />
            </MSH.6>
            <MSH.7>
              <xsl:value-of select="$datetime" />
            </MSH.7>
            <MSH.8 />
            <MSH.9>
              <MSG.1>
                <xsl:text>DPT</xsl:text>
              </MSG.1>
              <MSG.2>
                <xsl:text>P03</xsl:text>
              </MSG.2>
            </MSH.9>
            <MSH.10>
              <xsl:value-of select="concat($datetime, mr:pad(position(), 4))" />
            </MSH.10>
            <MSH.11>
              <xsl:text>P</xsl:text>
            </MSH.11>
            <MSH.12>
              <xsl:text>2.4</xsl:text>
            </MSH.12>
            <MSH.13 />
            <MSH.14 />
            <MSH.15>
              <xsl:text>AL</xsl:text>
            </MSH.15>
            <MSH.16 />
            <MSH.17 />
            <MSH.18 />
            <MSH.19 />
            <MSH.20 />
          </MSH>
          <!--PID-->
          <PID>
            <PID.1>
              <xsl:text>0001</xsl:text>
            </PID.1>
            <PID.2 />
            <PID.3>
              <CX.1>
                <xsl:variable name="facilityCode2">
                  <xsl:choose>
                    <xsl:when test="string-length($isSpecAlphaSplit) != 0">
                      <xsl:value-of select="$splitPrefix" />
                    </xsl:when>
                    <xsl:when test="$softwareID = ('114','126','112','111','109','110','122','113','118','123','120')">
                      <xsl:value-of select="$accountNumAlpha" />
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="$facilityCode" />
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:variable>
                <xsl:variable name="PatientAcctNumNoAlpha">
                  <xsl:value-of select="translate(translate(PatientAcctNum,'ABCDEFGHIJKLMNOPQRSTUVWXYZ',''),'abcdefghijklmnopqrstuvwxyz','')" />
                </xsl:variable>
                <xsl:choose>
                  <xsl:when test="$partitionName = 'MID'">
                    <!--Add the Facility Code to the front of the Patient Account Number + last 11 digits of the Patient Account Number.  Example: HH12345678901-->
                    <xsl:value-of select="concat($facilityCode2, substring($PatientAcctNumNoAlpha, string-length($PatientAcctNumNoAlpha) - 10))" />
                  </xsl:when>
                  <xsl:when test="$partitionName = 'IRL' and ($facilityName = 'GRA' or $facilityName = 'SOS')">
                    <!--Add the Facility Code to the front of the Patient Account Number + last 10 digits of the Patient Account Number.  Example: HH1234567890-->
                    <xsl:value-of select="concat($facilityCode2, substring($PatientAcctNumNoAlpha, string-length($PatientAcctNumNoAlpha) - 9))" />
                  </xsl:when>
                  <xsl:when test="$partitionName = 'NTX' and ($facilityName = 'MED' or $facilityName = 'MER')">
                    <!--Add the Facility Code and '00' to the front of the Patient Account Number + last 9 digits of the Patient Account Number.  Example: HH1234567890-->
                    <xsl:value-of select="concat($facilityCode2, '00' ,substring($PatientAcctNumNoAlpha, string-length($PatientAcctNumNoAlpha) - 8))" />
                  </xsl:when>
                  <xsl:when test="$partitionName = 'IRL' and ($facilityName = 'KRT' or $facilityName = 'KRD' or $facilityName = 'WER' or $facilityName = 'PWE' or $facilityName = 'MER')">
                    <!--Add the Facility Code to the front of the Patient Account Number + last 8 digits of the Patient Account Number.  Example: HH1234567890-->
                    <xsl:value-of select="concat($facilityCode2, substring($PatientAcctNumNoAlpha, string-length($PatientAcctNumNoAlpha) - 7))" />
                  </xsl:when>
                  <xsl:otherwise>
                    <!--Add the Facility Code to the front of the Patient Account Number + last 9 digits of the Patient Account Number.  Example: HH123456789-->
                    <xsl:value-of select="concat($facilityCode2, substring($PatientAcctNumNoAlpha, string-length($PatientAcctNumNoAlpha) - 8))" />
                  </xsl:otherwise>
                </xsl:choose>
              </CX.1>
            </PID.3>
            <PID.4 />
            <PID.5>
              <XPN.1>
                <xsl:value-of select="normalize-space(substring-before(PatientName, ','))" />
              </XPN.1>
              <XPN.2>
                <xsl:value-of select="normalize-space(substring-after(PatientName, ','))" />
              </XPN.2>
            </PID.5>
            <PID.6 />
            <PID.7 />
            <PID.8 />
            <PID.9 />
            <PID.10 />
            <PID.11 />
            <PID.12 />
            <PID.13 />
            <PID.14 />
            <PID.15 />
            <PID.16 />
            <PID.17 />
            <PID.18 />
            <PID.19 />
            <PID.20 />
            <PID.21 />
            <PID.22 />
            <PID.23 />
            <PID.24 />
            <PID.25 />
            <PID.26 />
            <PID.27 />
            <PID.28 />
            <PID.29 />
            <PID.30 />
            <PID.31 />
          </PID>
          <FT1>
            <FT1.1 />
            <FT1.2 />
            <FT1.3 />
            <FT1.4>
              <xsl:variable name="DOS" select="pf:getDate(NewProcDocDateDOS)" />
              <xsl:value-of select="$DOS" />
            </FT1.4>
            <FT1.5 />
            <FT1.6 />
            <FT1.7>
              <!--CPT CODE-->
              <xsl:value-of select="'P8363'" />
            </FT1.7>
            <FT1.8 />
            <FT1.9 />
            <!--FT1.10 - Charge Value-->
            <FT1.10>
              <xsl:value-of select="Units" />
            </FT1.10>
            <FT1.11 />
            <FT1.12 />
            <FT1.13 />
            <FT1.14 />
            <FT1.15 />
            <FT1.16>
              <CX.1 />
              <CX.2 />
              <CX.3 />
              <CX.4>
                <xsl:choose>
                  <xsl:when test="string-length($isSpecAlphaSplit) != 0">
                    <xsl:value-of select="$splitPrefix" />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="$facilityCode" />
                  </xsl:otherwise>
                </xsl:choose>
              </CX.4>
              <CX.5 />
              <CX.6 />
            </FT1.16>
            <FT1.17 />
            <FT1.18 />
            <FT1.19 />
            <FT1.20>
              <CX.1>
                <!--PERFORMING DOCTORS-->
                <xsl:value-of select="translate(PerformingDoctors,'abcdefghijklmnopqrstuvwxyz','ABCDEFGHIJKLMNOPQRSTUVWXYZ')" />
              </CX.1>
              <CX.2 />
            </FT1.20>
            <FT1.21 />
            <FT1.22 />
            <FT1.23 />
            <FT1.24 />
            <FT1.25>
              <!--CPT CODE-->
              <xsl:value-of select="'P8363'" />
            </FT1.25>
            <FT1.26 />
            <FT1.27 />
          </FT1>
        </ADT_A01>
      </xsl:for-each>
    </XCSData>
  </xsl:template>
  <!--Helper Function to pad control ID-->
  <xsl:function name="mr:pad">
    <xsl:param name="value" />
    <xsl:param name="length" />
    <xsl:choose>
      <xsl:when test="string-length(string($value)) &lt; number($length)">
        <xsl:value-of select="mr:pad(concat('0', $value), $length)" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$value" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  <xsl:function name="pf:getDate">
    <xsl:param name="dateString" />
    <xsl:variable name="dateToken" select="tokenize($dateString, '/')" />
    <xsl:value-of select="concat(concat('20',$dateToken[last()]),$dateToken[1],$dateToken[2])" />
  </xsl:function>
</xsl:stylesheet>

