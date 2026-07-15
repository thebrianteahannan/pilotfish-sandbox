<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:datetime="http://exslt.org/dates-and-times" xmlns:dtFormatter="xalan://com.pilotfish.eip.gui.mapper.util.DateTimeFormatter" xmlns:mr="mr" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="datetime dtFormatter" version="3.1">
  <xsl:param name="accountNumAlpha" />
  <xsl:param name="file_name" />
  <xsl:param name="partitionName" />
  <xsl:param name="clientName" />
  <xsl:param name="facilityName" />
  <xsl:param name="facilityCode" />
  <xsl:param name="softwareID" />
  <xsl:template match="/XCSData">
    <XCSData>
      <xsl:variable name="datetime" select="substring(translate(datetime:dateTime(), '-T:', ''), 1, 12)" />
      <!--<xsl:variable name="dataset" select="Import/Group[not(@stripped = 'true') and count(./PatientDemographics[not(./@stripped = 'true')]) &gt; 0 and count(./Charge[not(./@stripped = 'true')]) &gt; 0 and sum(./Charge[not(./@stripped = 'true')]/radNumOfTimes) &gt; 0]" />-->
      <xsl:variable name="dataset" select="Import/Group[not(@stripped = 'true') and count(./PatientDemographics[not(./@stripped = 'true')]) &gt; 0]" />
      <xsl:for-each select="$dataset">
        <xsl:sort order="ascending" select="./PatientDemographics/admAcctNum" />
        <xsl:variable name="PatientDOBFormatted" select="if (string-length(PatientDemographics/admbirthdate) != 0) then dtFormatter:format(PatientDemographics/admbirthdate,'yyyyMMdd','yyyy-MM-dd') else ''" />
        <xsl:variable name="birthDate" select="if (string-length($PatientDOBFormatted) != 0) then xs:date($PatientDOBFormatted) else ''" />
        <xsl:variable name="today" select="current-date()" />
        <xsl:variable name="PatientAge">
          <!--CALL TEMPLATE TO CALCULATE AGE BASED ON DOB AND CURRENT DATE-->
          <xsl:if test="string-length(string($birthDate)) != 0">
            <xsl:call-template name="calculateAge">
              <xsl:with-param name="birthDate" select="$birthDate" />
              <xsl:with-param name="currentDate" select="$today" />
            </xsl:call-template>
          </xsl:if>
        </xsl:variable>
        <!--ADT_A04-->
        <ADT_A01>
          <xsl:if test="position() = 1">
            <BHS>
              <BHS.1>
                <xsl:text>|</xsl:text>
              </BHS.1>
              <BHS.2>
                <xsl:text>^~\&amp;</xsl:text>
              </BHS.2>
              <BHS.3>
                <xsl:text>VWE</xsl:text>
              </BHS.3>
              <BHS.4 />
              <BHS.5>
                <xsl:value-of select="$facilityName" />
              </BHS.5>
              <BHS.6>
                <xsl:choose>
                  <xsl:when test="$partitionName = 'ARA'">
                    <xsl:value-of select="mr:getPartitionForARA($facilityName)" />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="$partitionName" />
                  </xsl:otherwise>
                </xsl:choose>
              </BHS.6>
              <BHS.7>
                <xsl:value-of select="$datetime" />
              </BHS.7>
              <BHS.8 />
              <BHS.9>
                <MSG.1>
                  <xsl:text>ADT</xsl:text>
                </MSG.1>
              </BHS.9>
              <BHS.10 />
              <BHS.11>
                <xsl:value-of select="substring(translate(datetime:dateTime(), '-T:', ''), 1, 14)" />
              </BHS.11>
              <BHS.12>
                <xsl:value-of select="$file_name" />
              </BHS.12>
              <BHS.13 />
            </BHS>
          </xsl:if>
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
              <xsl:value-of select="$facilityCode" />
            </MSH.4>
            <MSH.5>
              <xsl:value-of select="$facilityName" />
            </MSH.5>
            <MSH.6>
              <xsl:choose>
                <xsl:when test="$partitionName = 'ARA'">
                  <xsl:value-of select="mr:getPartitionForARA($facilityName)" />
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="$partitionName" />
                </xsl:otherwise>
              </xsl:choose>
            </MSH.6>
            <MSH.7>
              <xsl:value-of select="$datetime" />
            </MSH.7>
            <MSH.8 />
            <MSH.9>
              <MSG.1>
                <xsl:text>ADT</xsl:text>
              </MSG.1>
              <MSG.2>
                <xsl:text>A04</xsl:text>
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
                    <xsl:when test="$softwareID = ('114','126','112','111','109','110','122','113','118','123','120','800','801','517','514','515','516','652','760','761')">
                      <xsl:choose>
                        <xsl:when test="$softwareID = '801' and (PatientDemographics/admLocation = 'ATNACU' or PatientDemographics/admLocation = 'PBPACU')">
                          <xsl:value-of select="'PAI'" />
                        </xsl:when>
                        <xsl:otherwise>
                          <xsl:value-of select="$accountNumAlpha" />
                        </xsl:otherwise>
                      </xsl:choose>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="$facilityCode" />
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:variable>
                <xsl:choose>
                  <xsl:when test="$partitionName = 'MID'">
                    <!--Add the Facility Code to the front of the Patient Account Number + last 11 digits of the Patient Account Number.  Example: HH12345678901-->
                    <xsl:value-of select="concat($facilityCode2, substring(PatientDemographics/admAcctNum, string-length(PatientDemographics/admAcctNum) - 10))" />
                  </xsl:when>
                  <xsl:when test="$partitionName = 'NGP' and $clientName = 'CAQ'">
                    <!--Add the Facility Code to the front of the Patient Account Number + last 11 digits of the Patient Account Number.  Example: HH12345678901-->
                    <xsl:value-of select="concat($facilityCode2, substring(PatientDemographics/admAcctNum, string-length(PatientDemographics/admAcctNum) - 10))" />
                  </xsl:when>
                  <xsl:when test="$partitionName = 'IRL' and ($facilityName = 'GRA' or $facilityName = 'SOS')">
                    <!--Add the Facility Code to the front of the Patient Account Number + last 10 digits of the Patient Account Number.  Example: HH1234567890-->
                    <xsl:value-of select="concat($facilityCode2, substring(PatientDemographics/admAcctNum, string-length(PatientDemographics/admAcctNum) - 9))" />
                  </xsl:when>
                  <xsl:when test="$partitionName = 'NTX' and ($facilityName = 'MED' or $facilityName = 'MER')">
                    <!--Add the Facility Code and '00' to the front of the Patient Account Number + last 9 digits of the Patient Account Number.  Example: HH00123456789-->
                    <xsl:value-of select="concat($facilityCode2, '00' ,substring(PatientDemographics/admAcctNum, string-length(PatientDemographics/admAcctNum) - 8))" />
                  </xsl:when>
                  <xsl:when test="$partitionName = 'IRL' and ($facilityName = 'KRT' or $facilityName = 'KRD' or $facilityName = 'WER' or $facilityName = 'PWE' or $facilityName = 'MER')">
                    <!--Add the Facility Code to the front of the Patient Account Number + last 8 digits of the Patient Account Number.  Example: HH1234567890-->
                    <xsl:value-of select="concat($facilityCode2, substring(PatientDemographics/admAcctNum, string-length(PatientDemographics/admAcctNum) - 7))" />
                  </xsl:when>
                  <xsl:when test="$partitionName = 'ARA'">
                    <xsl:value-of select="concat($facilityCode2, translate(substring(PatientDemographics/admAcctNum, string-length(PatientDemographics/admAcctNum) - 8),'-',''))" />
                  </xsl:when>
                  <xsl:when test="$partitionName = 'HAL'">
                    <!--Add the Facility Code to the front of the Patient Account Number + ALL digits of the Patient Account Number.  Example: HH11123456789-->
                    <xsl:value-of select="concat($facilityCode2, PatientDemographics/admAcctNum)" />
                  </xsl:when>
                  <xsl:otherwise>
                    <!--Add the Facility Code to the front of the Patient Account Number + last 9 digits of the Patient Account Number.  Example: HH123456789-->
                    <xsl:value-of select="concat($facilityCode2, substring(PatientDemographics/admAcctNum, string-length(PatientDemographics/admAcctNum) - 8))" />
                  </xsl:otherwise>
                </xsl:choose>
              </CX.1>
              <CX.5>
                <xsl:text>PT</xsl:text>
              </CX.5>
            </PID.3>
            <PID.3>
              <CX.1>
                <!--KEEP AS BACKUP FOR NOW-->
                <!--<xsl:value-of select="PatientDemographics/absPatientUnit" />-->
                <!--NOW DOING FULL ACCOUNT NUMBER HERE INSTEAD OF ABS PATIENT UNIT-->
                <!--ARA: when canonical ClientID is present, use it here so CX.5/PID-3.5 can be Misc2-->
                <xsl:choose>
                  <xsl:when test="$partitionName = 'ARA' and string-length(normalize-space(PatientDemographics/ClientID)) != 0">
                    <xsl:value-of select="PatientDemographics/ClientID" />
                  </xsl:when>
                  <xsl:when test="$softwareID = ('800')">
                    <xsl:value-of select="translate(PatientDemographics/admAcctNum,'-','')" />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="PatientDemographics/admAcctNum" />
                  </xsl:otherwise>
                </xsl:choose>
              </CX.1>
              <CX.5>
                <xsl:text>MR</xsl:text>
              </CX.5>
            </PID.3>
            <PID.4>
              <xsl:choose>
                <xsl:when test="$partitionName = 'NTX' and $clientName = ('ANC','FTW')">
                  <xsl:choose>
                    <xsl:when test="string-length(PatientDemographics/absAdmitdate) = 0">
                      <!--IF ADMIT DATE IS NOT THERE WE WANT TO PUT THE FIRST DATE OF SERVICE FROM ALL THE CHARGES (radExamServDate) INSTEAD-->
                      <xsl:variable name="oldestServiceDate">
                        <xsl:for-each select="Charge">
                          <xsl:sort order="ascending" select="radExamServDate" />
                          <xsl:if test="position() = 1">
                            <xsl:value-of select="radExamServDate" />
                          </xsl:if>
                        </xsl:for-each>
                      </xsl:variable>
                      <xsl:value-of select="$oldestServiceDate" />
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="PatientDemographics/absAdmitdate" />
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="PatientDemographics/absAdmitdate" />
                </xsl:otherwise>
              </xsl:choose>
            </PID.4>
            <PID.5>
              <xsl:choose>
                <xsl:when test="$partitionName = 'ARA' and Insurance1/adminsmne = 'C'">
                  <xsl:choose>
                    <xsl:when test="string-length(Insurance1/subscribername) = 0 or Insurance1/subscribername = ','">
                      <xsl:value-of select="PatientDemographics/admname" />
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="Insurance1/subscribername" />
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                  <XPN.1>
                    <xsl:value-of select="normalize-space(substring-before(PatientDemographics/admname, ','))" />
                  </XPN.1>
                  <XPN.2>
                    <xsl:value-of select="normalize-space(substring-after(PatientDemographics/admname, ','))" />
                  </XPN.2>
                </xsl:otherwise>
              </xsl:choose>
            </PID.5>
            <PID.6 />
            <PID.7>
              <xsl:value-of select="PatientDemographics/admbirthdate" />
            </PID.7>
            <PID.8>
              <xsl:value-of select="PatientDemographics/admpatsex" />
            </PID.8>
            <PID.9 />
            <PID.10 />
            <PID.11>
              <XAD.1>
                <xsl:variable name="patientAddr" select="upper-case(translate(translate(concat(PatientDemographics/admstreet,' ', PatientDemographics/admstreet2), '.#', ''),'-', ''))" />
                <xsl:value-of select="translate(replace($patientAddr, '^\s+|\s+$', ''),'/',' ')" />
              </XAD.1>
              <XAD.2 />
              <XAD.3>
                <xsl:value-of select="PatientDemographics/admpatcity" />
              </XAD.3>
              <XAD.4>
                <xsl:value-of select="PatientDemographics/admpatstate" />
              </XAD.4>
              <XAD.5>
                <xsl:value-of select="PatientDemographics/admzipcode" />
              </XAD.5>
            </PID.11>
            <PID.12 />
            <PID.13>
              <xsl:value-of select="PatientDemographics/admpatphone" />
            </PID.13>
            <PID.14>
              <xsl:value-of select="PatientDemographics/admemplphone" />
            </PID.14>
            <PID.15 />
            <PID.16>
              <xsl:choose>
                <xsl:when test="$partitionName = 'NGP' and string-length(PatientDemographics/admmaritalstatus) = 0">
                  <xsl:value-of select="'U'" />
                </xsl:when>
                <xsl:when test="$partitionName = 'HAL' or $partitionName = 'PPA' or $partitionName = 'ARA' or $partitionName = 'PPS' or $partitionName = 'NSP' or ($partitionName = 'NGP' and string-length(PatientDemographics/admmaritalstatus) &gt; 0)">
                  <xsl:value-of select="PatientDemographics/admmaritalstatus" />
                </xsl:when>
                <xsl:when test="$partitionName = 'IRL' and $softwareID = ('517','514','515','516','518','519','520','521','522')">
                  <xsl:value-of select="'U'" />
                </xsl:when>
                <xsl:when test="$partitionName = 'FPS' and $softwareID = ('314','315','316','317','318','319','320','321','322','330','331')">
                  <xsl:value-of select="'U'" />
                </xsl:when>
                <xsl:when test="$partitionName = 'GLF' and $softwareID = ('329','384','385','386','387','388','389')">
                  <xsl:value-of select="'U'" />
                </xsl:when>
              </xsl:choose>
            </PID.16>
            <PID.17 />
            <PID.18 />
            <PID.19>
              <xsl:value-of select="PatientDemographics/admssn" />
            </PID.19>
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
          <!--NK1-->
          <NK1>
            <NK1.1>
              <xsl:text>0001</xsl:text>
            </NK1.1>
            <NK1.2 />
            <NK1.3>
              <xsl:text>E</xsl:text>
            </NK1.3>
            <NK1.4>
              <XAD.1>
                <xsl:variable name="admGuarEmplAddr" select="replace(translate(concat(Guarantor/admGuarEmplAddr1,' ',Guarantor/admGuarEmplAddr2), '.', ''), ', ,', '')" />
                <xsl:value-of select="upper-case(normalize-space(replace($admGuarEmplAddr,'-',' ')))" />
              </XAD.1>
              <XAD.2 />
              <XAD.3>
                <xsl:value-of select="upper-case(Guarantor/admGuarEmplCity)" />
              </XAD.3>
              <XAD.4>
                <xsl:value-of select="upper-case(Guarantor/admGuarEmplState)" />
              </XAD.4>
              <XAD.5>
                <xsl:value-of select="Guarantor/admGuarEmplZip" />
              </XAD.5>
              <XAD.6 />
            </NK1.4>
            <NK1.5 />
            <NK1.6>
              <xsl:value-of select="Guarantor/admGuarEmplPhone" />
            </NK1.6>
            <NK1.7 />
            <NK1.8 />
            <NK1.9 />
            <NK1.10 />
            <NK1.11 />
            <NK1.12 />
            <NK1.13>
              <xsl:value-of select="Guarantor/admGuarEmployer" />
            </NK1.13>
            <NK1.14 />
            <NK1.15 />
            <NK1.16 />
            <NK1.17 />
            <NK1.18 />
            <NK1.19 />
            <NK1.20 />
            <NK1.21 />
            <NK1.22 />
            <NK1.23 />
            <NK1.24 />
            <NK1.25 />
            <NK1.26 />
            <NK1.27 />
            <NK1.28 />
            <NK1.29 />
            <NK1.30 />
            <NK1.31 />
            <NK1.32 />
            <NK1.33 />
            <NK1.34 />
            <NK1.35 />
            <NK1.36 />
            <NK1.37 />
            <NK1.38 />
          </NK1>
          <!--PV1-->
          <PV1>
            <PV1.1 />
            <PV1.2>
              <xsl:choose>
                <xsl:when test="$facilityName = 'TPH' and PatientDemographics/admLocation = 'D.TPATH'">
                  <xsl:value-of select="concat(PatientDemographics/admpatienttype,PatientDemographics/admLocation)" />
                </xsl:when>
                <xsl:when test="$facilityName = 'RIO' and PatientDemographics/admLocation = 'H.LIND'">
                  <xsl:value-of select="concat(PatientDemographics/admpatienttype,PatientDemographics/admLocation)" />
                </xsl:when>
                <xsl:when test="$partitionName = 'NTX' and $facilityName = 'ANC' and PatientDemographics/admLocation = 'BB.SOLIS'">
                  <xsl:value-of select="concat(PatientDemographics/admpatienttype,PatientDemographics/admLocation)" />
                </xsl:when>
                <xsl:when test="$partitionName = 'NTX' and $facilityName = 'FTW' and PatientDemographics/admLocation = 'M.ASC'">
                  <xsl:value-of select="concat(PatientDemographics/admpatienttype,PatientDemographics/admLocation)" />
                </xsl:when>
                <xsl:when test="$partitionName = 'NTX' and ($facilityName = 'PLA' or $facilityName = 'FRI' or $facilityName = 'SAC') and (PatientDemographics/admLocation = 'E.SOLIS' or PatientDemographics/admLocation = 'E.DS')">
                  <xsl:value-of select="concat(PatientDemographics/admpatienttype,PatientDemographics/admLocation)" />
                </xsl:when>
                <xsl:when test="$facilityName = 'CLO' and PatientDemographics/admLocation = 'G.BASC'">
                  <xsl:value-of select="concat(PatientDemographics/admpatienttype,PatientDemographics/admLocation)" />
                </xsl:when>
                <xsl:when test="$partitionName = 'NTX' and $facilityName = 'ARL' and PatientDemographics/admLocation = 'I.TPC'">
                  <xsl:value-of select="'24'" />
                </xsl:when>
                <xsl:when test="$partitionName = 'ARA' and PatientDemographics/admLocation = 'PBPPA24'">
                  <xsl:value-of select="'24'" />
                </xsl:when>
                <!--NGP - HEALTH FIRST-->
                <xsl:when test="$partitionName = 'NGP' and $clientName = 'CAQ' and PatientDemographics/admpatienttype = 'NA'">
                  <xsl:value-of select="'22'" />
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="PatientDemographics/admpatienttype" />
                </xsl:otherwise>
              </xsl:choose>
            </PV1.2>
            <PV1.3>
              <PL.1 />
              <PL.2 />
              <PL.3 />
              <PL.4>
                <xsl:value-of select="$facilityCode" />
              </PL.4>
              <PL.5 />
            </PV1.3>
            <PV1.4 />
            <PV1.5 />
            <PV1.6 />
            <PV1.7 />
            <PV1.8>
              <xsl:choose>
                <!--NON NHL-->
                <xsl:when test="$partitionName != 'NHL' and $facilityName != 'NOA' and string-length(PatientDemographics/AttendDrNPI) != 0 and string-length(PatientDemographics/absattendingdocname) != 0">
                  <XCN.1>
                    <xsl:choose>
                      <xsl:when test="$partitionName = 'ARA'">
                        <xsl:value-of select="concat(PatientDemographics/AttendDrNPI,'A',translate(PatientDemographics/ClientID,'-',''))" />
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="PatientDemographics/AttendDrNPI" />
                      </xsl:otherwise>
                    </xsl:choose>
                  </XCN.1>
                  <XCN.2>
                    <xsl:value-of select="normalize-space(substring-before(PatientDemographics/absattendingdocname, ','))" />
                  </XCN.2>
                  <XCN.3>
                    <xsl:variable name="docLastName" select="substring-after(PatientDemographics/absattendingdocname, ',')" />
                    <xsl:choose>
                      <xsl:when test="$partitionName = 'SPG' and string-length($docLastName) = 0">
                        <xsl:value-of select="PatientDemographics/absattendingdocname" />
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:choose>
                          <xsl:when test="starts-with($docLastName, ' ')">
                            <xsl:value-of select="substring-after($docLastName, ' ')" />
                          </xsl:when>
                          <xsl:otherwise>
                            <xsl:value-of select="$docLastName" />
                          </xsl:otherwise>
                        </xsl:choose>
                      </xsl:otherwise>
                    </xsl:choose>
                  </XCN.3>
                </xsl:when>
                <!--FOR NHL and FPS and NOA ONLY-->
                <xsl:when test="$partitionName = 'NHL' or ($partitionName = 'FPS' and $facilityName = ('REA','REC','STB','CHJ','HEO','JRN','JWI','PAS','REU','SPP','LGX','ALX','MNX','PXL')) or $facilityName = 'NOA' or ($partitionName = 'IRL' and $facilityName = ('LAM','PUX','MAX','NFX','OCX','DEX','MIX','NXX','OMC','OXX','SUN','JFX','PWX','LWX','COX','CAX','GUX','TWX','WAX','WFX','GUP','GUQ','DEV','DEW','PES','WFP','WFQ')) or ($partitionName = 'GLF' and $facilityName = ('HMD','TON','CMX','KIX','CYX','HWX','TWX'))">
                  <XCN.1>
                    <xsl:value-of select="Charge[string-length(orderingDrNPI) != 0 and string-length(misOrderingPhyName) != 0][1]/orderingDrNPI[1]" />
                  </XCN.1>
                  <XCN.2>
                    <xsl:value-of select="normalize-space(substring-before(Charge[string-length(orderingDrNPI) != 0 and string-length(misOrderingPhyName) != 0][1]/misOrderingPhyName[1], ','))" />
                  </XCN.2>
                  <XCN.3>
                    <xsl:variable name="docLastName" select="substring-after(Charge[string-length(orderingDrNPI) != 0 and string-length(misOrderingPhyName) != 0][1]/misOrderingPhyName[1], ',')" />
                    <xsl:choose>
                      <xsl:when test="starts-with($docLastName, ' ')">
                        <xsl:value-of select="substring-after($docLastName, ' ')" />
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="$docLastName" />
                      </xsl:otherwise>
                    </xsl:choose>
                  </XCN.3>
                </xsl:when>
                <!--DEFAULT-->
                <xsl:otherwise>
                  <xsl:choose>
                    <xsl:when test="$partitionName = 'SPG' and string-length(PatientDemographics/AttendDrNPI) = 0">
                      <xsl:value-of select="'1255414983'" />
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:choose>
                        <xsl:when test="$partitionName = 'PPA' and string-length(PatientDemographics/AttendDrNPI) = 0">
                          <xsl:value-of select="concat($accountNumAlpha,'99')" />
                        </xsl:when>
                        <xsl:otherwise>
                          <xsl:value-of select="'9999'" />
                        </xsl:otherwise>
                      </xsl:choose>
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:otherwise>
              </xsl:choose>
            </PV1.8>
            <PV1.9 />
            <PV1.10 />
            <PV1.11 />
            <PV1.12 />
            <PV1.13 />
            <PV1.14 />
            <PV1.15 />
            <PV1.16 />
            <PV1.17 />
            <PV1.18 />
            <PV1.19 />
            <PV1.20 />
            <PV1.21 />
            <PV1.22 />
            <PV1.23 />
            <PV1.24 />
            <PV1.25 />
            <PV1.26 />
            <PV1.27 />
            <PV1.28 />
            <PV1.29 />
            <PV1.30 />
            <PV1.31 />
            <PV1.32 />
            <PV1.33 />
            <PV1.34 />
            <PV1.35 />
            <PV1.36 />
            <PV1.37 />
            <PV1.38 />
            <PV1.39 />
            <PV1.40 />
            <PV1.41 />
            <PV1.42 />
            <PV1.43 />
            <!--FOR CODES IN THE LIST OF ER PLANS FROM THE DB - DON'T SHOW ADMIT OR DISCHARGE DATE-->
            <!--IF PV1.2 = 'E' AND PLAN CODE MATCHES ONES OF THE ONES IN THE ER_INS_PLAN_CODES DB TABLE-->
            <xsl:variable name="PatientType" select="PatientDemographics/admpatienttype" />
            <xsl:variable name="InsPlanCode" select="Insurance1/adminsmne" />
            <xsl:choose>
              <xsl:when test="$PatientType != 'E' or count(//ER_INS_PLAN_CODES[CODE = $InsPlanCode]) = 0">
                <PV1.44>
                  <!--This field is for showing the date a signature was obtained, so if absAdmitdate is greater than earliest radExamServDate then we use radExamServDate-->
                  <!-- -->
                  <!--The admPatientType must equal "I".-->
                  <!--The admLocation must not equal "G.FPSW"-->
                  <!--If the radExamServDate is less than the absAdmitDate then use the first absAdmitDate as the DOS otherwise use the radExamServDate.-->
                  <!--For PV2.28, if your system processes the PV1 segment first and then processes the PV2 data, you can tell your tool to use the data from PV1.44 to populate PV2.28.-->
                  <xsl:for-each select="Charge[not(@stripped = 'true')]">
                    <xsl:sort order="ascending" select="radExamServDate" />
                    <!--The first one is the earliest charge date-->
                    <xsl:if test="position() = 1 and $partitionName != 'ARA'">
                      <xsl:choose>
                        <xsl:when test="./radExamServDate &lt; ../PatientDemographics/absAdmitdate and ../PatientDemographics/admpatienttype = 'I'  and not(../PatientDemographics/admLocation = 'G.FPSW')">
                          <xsl:value-of select="./radExamServDate" />
                        </xsl:when>
                        <xsl:otherwise>
                          <xsl:value-of select="../PatientDemographics/absAdmitdate" />
                        </xsl:otherwise>
                      </xsl:choose>
                    </xsl:if>
                  </xsl:for-each>
                  <!--ADD THE ADMIT DATE FROM PATIENT DEMOGRAPHICS IF THERE ARE NO CHARGES, FOR NGP AND GLF ONLY-->
                  <xsl:if test="($partitionName = 'NGP' or $partitionName = 'GLF') and count(Charge[not(@stripped = 'true')]) = 0">
                    <xsl:value-of select="PatientDemographics/absAdmitdate" />
                  </xsl:if>
                </PV1.44>
                <PV1.45>
                  <xsl:if test="$partitionName != 'ARA'">
                    <xsl:value-of select="PatientDemographics/absdischargedate" />
                  </xsl:if>
                </PV1.45>
              </xsl:when>
              <xsl:otherwise>
                <PV1.44 />
                <PV1.45 />
              </xsl:otherwise>
            </xsl:choose>
            <PV1.46 />
            <PV1.47 />
            <PV1.48 />
            <PV1.49 />
            <PV1.50 />
            <PV1.51 />
            <PV1.52 />
            <PV1.53 />
          </PV1>
          <!--PV2-->
          <PV2>
            <PV2.1 />
            <PV2.2 />
            <PV2.3 />
            <PV2.4 />
            <PV2.5 />
            <PV2.6 />
            <PV2.7 />
            <PV2.8 />
            <PV2.9 />
            <PV2.10 />
            <PV2.11 />
            <PV2.12 />
            <PV2.13 />
            <PV2.14 />
            <PV2.15 />
            <PV2.16 />
            <PV2.17 />
            <PV2.18 />
            <PV2.19 />
            <PV2.20 />
            <PV2.21 />
            <PV2.22 />
            <PV2.23 />
            <PV2.24 />
            <PV2.25 />
            <PV2.26 />
            <PV2.27 />
            <PV2.28>
              <!--This field is for showing the date a signature was obtained, so if absAdmitdate is greater than earliest radExamServDate then we use radExamServDate-->
              <!-- -->
              <!--The admPatientType must equal "I".-->
              <!--The admLocation must not equal "G.FPSW"-->
              <!--If the radExamServDate is less than the absAdmitDate then use the first absAdmitDate as the DOS otherwise use the radExamServDate.-->
              <!--For PV2.28, if your system processes the PV1 segment first and then processes the PV2 data, you can tell your tool to use the data from PV1.44 to populate PV2.28.-->
              <xsl:for-each select="Charge[not(@stripped = 'true')]">
                <xsl:sort order="ascending" select="radExamServDate" />
                <!--The first one is the earliest charge date-->
                <xsl:if test="position() = 1">
                  <xsl:choose>
                    <xsl:when test="$partitionName = 'SPG'">
                      <!--SPG ALWAYS USE THE RADEXAMSERVDATE-->
                      <xsl:value-of select="./radExamServDate" />
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:choose>
                        <xsl:when test="./radExamServDate &lt; ../PatientDemographics/absAdmitdate and ../PatientDemographics/admpatienttype = 'I'  and not(../PatientDemographics/admLocation = 'G.FPSW')">
                          <xsl:value-of select="./radExamServDate" />
                        </xsl:when>
                        <xsl:otherwise>
                          <xsl:value-of select="../PatientDemographics/absAdmitdate" />
                        </xsl:otherwise>
                      </xsl:choose>
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:if>
              </xsl:for-each>
              <!--ADD THE ADMIT DATE FROM PATIENT DEMOGRAPHICS IF THERE ARE NO CHARGES, FOR NGP ONLY-->
              <xsl:if test="$partitionName = 'NGP' and count(Charge[not(@stripped = 'true')]) = 0">
                <xsl:value-of select="PatientDemographics/absAdmitdate" />
              </xsl:if>
            </PV2.28>
            <PV2.29 />
            <PV2.30 />
          </PV2>
          <!--PV9-->
          <PV9>
            <PV9.1>A</PV9.1>
            <PV9.2 />
            <PV9.3 />
            <PV9.4 />
            <PV9.5 />
            <PV9.6 />
            <PV9.7 />
            <PV9.8 />
            <PV9.9 />
            <PV9.10 />
            <PV9.11 />
            <PV9.12 />
            <PV9.13 />
            <PV9.14 />
            <PV9.15 />
            <PV9.16 />
            <PV9.17 />
            <PV9.18 />
            <PV9.19 />
            <PV9.20 />
            <PV9.21 />
            <xsl:variable name="value" select="Insurance1/adminsmne" />
            <xsl:choose>
              <xsl:when test="count(/XCSData/query_results/MEDIPASS_CERT_CODES/MEDIPASS_CERT_CODES[INS_PLANS = $value]) != 0">
                <PV9.22>
                  <xsl:value-of select="Insurance1/adminstreatmentauth" />
                </PV9.22>
                <!--No mention of PV9.23 in the mapping spreadsheet-->
                <PV9.23>
                  <xsl:value-of select="Insurance1/adminstreatmentauth" />
                </PV9.23>
              </xsl:when>
              <xsl:otherwise>
                <PV9.22 />
                <PV9.23 />
              </xsl:otherwise>
            </xsl:choose>
            <PV9.24 />
            <PV9.25 />
            <PV9.26 />
            <PV9.27 />
            <PV9.28 />
            <PV9.29 />
            <PV9.30 />
            <PV9.31 />
            <PV9.32 />
            <PV9.33 />
            <PV9.34 />
            <PV9.35 />
            <PV9.36 />
            <PV9.37 />
            <PV9.38 />
            <!--ChiefComplaint - Update field to show the first 21 characters of the ChiefComplaint field-->
            <PV9.39>
              <xsl:variable name="ChiefComplaint" select="substring(PatientDemographics/ChiefComplaint, 1, 21)" />
              <xsl:value-of select="replace($ChiefComplaint, '^\s+|\s+$', '')" />
            </PV9.39>
            <PV9.40>
              <!--Mapping sheet shows this but Terry's output doesn't show this so should we include it or not?-->
              <!--ChiefComplaint - Update field to show the last 21 characters of the ChiefCompliant field-->
              <!--<xsl:value-of select="substring(PatientDemographics/ChiefComplaint, 22, string-length(PatientDemographics/ChiefComplaint))" />-->
            </PV9.40>
          </PV9>
          <!--DG1-->
          <xsl:variable name="DiagnosisCodesList" select="DiagnosisCodes/Diag" />
          <xsl:for-each-group group-by="." select="$DiagnosisCodesList">
            <!--<xsl:sort data-type="text" order="ascending" select="number(@sort_rank)" />-->
            <!--<xsl:sort data-type="text" order="ascending" select="." />-->
            <xsl:if test="string-length(.) &gt; 0">
              <DG1>
                <DG1.1 />
                <DG1.2 />
                <DG1.3>
                  <xsl:value-of select="." />
                </DG1.3>
                <DG1.4 />
                <DG1.5 />
                <DG1.6 />
                <DG1.7 />
                <DG1.8 />
                <DG1.9 />
                <DG1.10 />
                <DG1.11 />
                <DG1.12 />
                <DG1.13 />
                <DG1.14 />
                <DG1.15 />
                <DG1.16 />
                <DG1.17 />
                <DG1.18 />
                <DG1.19 />
              </DG1>
            </xsl:if>
          </xsl:for-each-group>
          <!--GT1-->
          <GT1>
            <GT1.1>
              <xsl:text>0001</xsl:text>
            </GT1.1>
            <GT1.2>
              <xsl:variable name="facilityCode2">
                <xsl:choose>
                  <xsl:when test="$softwareID = ('114','126','112','111','109','110','122','113','118','123','120','801','800','514','515','516','517')">
                    <xsl:choose>
                      <xsl:when test="$softwareID = '801' and (PatientDemographics/admLocation = 'ATNACU' or PatientDemographics/admLocation = 'PBPACU')">
                        <xsl:value-of select="'PAI'" />
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="$accountNumAlpha" />
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="$facilityCode" />
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:variable>
              <xsl:value-of select="$facilityCode2" />
              <xsl:value-of select="substring(Guarantor/admAcctNum, 3, 6)" />
            </GT1.2>
            <GT1.3>
              <!--DEFAULT TO PATIENT NAME IF NO GUARANTOR NAME-->
              <xsl:choose>
                <xsl:when test="string-length(Guarantor/admGuarName) = 0">
                  <XPN.1>
                    <xsl:value-of select="normalize-space(substring-before(PatientDemographics/admname, ','))" />
                  </XPN.1>
                  <XPN.2>
                    <xsl:value-of select="normalize-space(substring-after(PatientDemographics/admname, ','))" />
                  </XPN.2>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:choose>
                    <xsl:when test="$partitionName = 'SPG' and not(contains(Guarantor/admGuarName,','))">
                      <XPN.1>
                        <xsl:value-of select="normalize-space(substring-before(PatientDemographics/admname, ','))" />
                      </XPN.1>
                      <XPN.2>
                        <xsl:value-of select="normalize-space(substring-after(PatientDemographics/admname, ','))" />
                      </XPN.2>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:choose>
                        <xsl:when test="($partitionName = 'PPA' or $partitionName = 'NGP') and not(contains(Guarantor/admGuarName,','))">
                          <XPN.1>
                            <xsl:value-of select="Guarantor/admGuarName" />
                          </XPN.1>
                          <XPN.2 />
                        </xsl:when>
                        <xsl:otherwise>
                          <XPN.1>
                            <xsl:value-of select="normalize-space(substring-before(Guarantor/admGuarName, ','))" />
                          </XPN.1>
                          <XPN.2>
                            <xsl:value-of select="normalize-space(substring-after(Guarantor/admGuarName, ','))" />
                          </XPN.2>
                        </xsl:otherwise>
                      </xsl:choose>
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:otherwise>
              </xsl:choose>
            </GT1.3>
            <GT1.4 />
            <GT1.5>
              <XAD.1>
                <xsl:value-of select="upper-case(normalize-space(translate(translate(translate(concat(normalize-space(Guarantor[1]/admGuarAddr1[1]),' ',normalize-space(Guarantor[1]/admGuarAddr2[1])), '.#', ' '),'-',' '),'/',' ')))" />
              </XAD.1>
              <XAD.2 />
              <XAD.3>
                <xsl:value-of select="Guarantor/admGuarCity" />
              </XAD.3>
              <XAD.4>
                <xsl:value-of select="Guarantor/admGuarState" />
              </XAD.4>
              <XAD.5>
                <xsl:value-of select="Guarantor/admGuarZip" />
              </XAD.5>
            </GT1.5>
            <GT1.6>
              <!--<xsl:value-of select="Guarantor/admGuarHomePhone" />-->
              <xsl:value-of select="PatientDemographics/admpatphone" />
            </GT1.6>
            <GT1.7>
              <xsl:value-of select="Guarantor/admGuarEmplPhone" />
            </GT1.7>
            <GT1.8>
              <xsl:value-of select="PatientDemographics/admbirthdate" />
            </GT1.8>
            <GT1.9 />
            <GT1.10 />
            <GT1.11>
              <xsl:choose>
                <xsl:when test="($partitionName = 'NGP' or $partitionName = 'SPG' or $partitionName = 'GLF' or ($partitionName = 'IRL' and $softwareID = ('517','514','515','516')) or ($partitionName = 'FPS' and $softwareID = ('314','315','316','317','318','319','320')) ) and string-length(Guarantor/admGuarRel) = 0">
                  <xsl:choose>
                    <xsl:when test="Guarantor/admGuarName = PatientDemographics/admname">
                      <xsl:value-of select="'SE'" />
                    </xsl:when>
                    <xsl:when test="Guarantor/admGuarName != PatientDemographics/admname and $PatientAge &lt; 18">
                      <xsl:value-of select="'CH'" />
                    </xsl:when>
                    <xsl:when test="Guarantor/admGuarName != PatientDemographics/admname and $PatientAge &gt;= 18">
                      <xsl:value-of select="'UN'" />
                    </xsl:when>
                  </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:choose>
                    <xsl:when test="$partitionName = 'PPA' and string-length(Guarantor/admGuarRel) = 0">
                      <xsl:value-of select="'15'" />
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="Guarantor/admGuarRel" />
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:otherwise>
              </xsl:choose>
            </GT1.11>
            <GT1.12>
              <xsl:value-of select="Guarantor/admGuarSSN" />
            </GT1.12>
            <GT1.13 />
            <GT1.14 />
            <GT1.15 />
            <GT1.16>
              <xsl:value-of select="Guarantor/admGuarEmployer" />
            </GT1.16>
            <GT1.17 />
            <GT1.18 />
            <GT1.19 />
            <GT1.20 />
            <GT1.21 />
            <GT1.22 />
            <GT1.23 />
            <GT1.24 />
            <GT1.25 />
            <GT1.26 />
            <GT1.27 />
            <GT1.28 />
            <GT1.29 />
            <GT1.30 />
            <GT1.31 />
            <GT1.32 />
            <GT1.33 />
            <GT1.34 />
            <GT1.35 />
            <GT1.36 />
            <GT1.37 />
            <GT1.38 />
            <GT1.39 />
            <GT1.40 />
            <GT1.41 />
            <GT1.42 />
            <GT1.43 />
            <GT1.44 />
            <GT1.45 />
            <GT1.46 />
            <GT1.47 />
            <GT1.48 />
            <GT1.49 />
            <GT1.50 />
            <GT1.51 />
            <GT1.52 />
            <GT1.53 />
            <GT1.54 />
            <GT1.55 />
            <GT1.56 />
          </GT1>
          <!--INSURANCE1-->
          <xsl:if test="Insurance1[string-length(adminsmne) &gt; 0 and adminsmne != 'BLANK']">
            <xsl:if test="not($partitionName = 'ARA' and Insurance1/adminsmne = 'SELFPAY')">
              <ADT_A01.INSURANCE>
                <!--IN1-->
                <IN1>
                  <IN1.1>
                    <xsl:text>0001</xsl:text>
                  </IN1.1>
                  <IN1.2>
                    <!--change on adminsmne, adminspolicy W.WPPA->CW.WPPA on C4, MF, HU, MU, DW-->
                    <xsl:choose>
                      <xsl:when test="Insurance1/adminsmne = 'W.WPPA' and (starts-with(Insurance1/adminspolicy,'C4') or starts-with(Insurance1/adminspolicy,'MF') or starts-with(Insurance1/adminspolicy,'HU') or starts-with(Insurance1/adminspolicy,'MU') or starts-with(Insurance1/adminspolicy,'DW'))">
                        <xsl:value-of select="'CW.WPPA'" />
                      </xsl:when>
                      <xsl:when test="$partitionName = 'FPS' and Insurance1/adminsmne = ('AE104', 'AETNA BET', 'CHAR PEND', 'FLAT RATE', 'HEALTH', 'HEALTH MCD', 'INTNL UINS', 'KAISER MCD', 'MA200', 'MAG CCC P', 'MCD FAM', 'MCD HMOOUT', 'MCD OUT', 'MCD PEND', 'MCD VA', 'MCD WVA', 'MCRMCDDUAL', 'MDVA', 'MDVADOC', 'MDVASC', 'MOL CCC P', 'OPTIMA MCD', 'OPTIMA VAP', 'PSY AET BE', 'PSY AETBEP', 'PSY ECO', 'PSY HEALTH', 'PSY KAIMCD', 'PSY MAG', 'PSY MAGCCP', 'PSY MAGMCD', 'PSY MOLCCP', 'PSY OPTCCP', 'PSY OPTI', 'PSY OPTVAP', 'PSY OPTMD', 'PSY PREMCD', 'PSY TDO', 'PSY UHC', 'PSY UHCMD', 'PSY VA PRE', 'REH AETBEP', 'REH MAGCCP', 'REH MCD', 'UHCMCDSNP', 'UHCMDVA', 'UNIN INT', 'UNINSURED', 'UNITED CCP', 'VA HEALTH', 'VA PRE MCD', 'VI016', 'VI026', 'ZCHA 0-200', 'ZCHA 201-', 'ZMAG RECLS', 'ZMCD ED VA', 'ZMCD KS', 'ZMCD KY', 'ZMCD MO', 'ZMCD NC', 'ZMCD NH', 'ZMCD PE', 'ZMCD RECLA', 'ZMCD WVA', 'ZMCDOOSFOL', 'ZRCPS MCD', 'ZREHABMCD', 'ZZCHAR 100', 'ZZCHAR 200', 'PSYSENMCD', 'SENMCD', 'SENKAIMCD','HEALTH MCD','MCDDISPND','MCDPEND','ZMCD ED VA','PSY MCDHMO','MCD PEND','UNINSUREDE','REH MOLCCP','MDWVIN','MDTN','MDVAOUT','SE179','HUMMCDOON','PSYSENTARA','UH022SC','UH022DOC','AETBMCD','AETBMCDBH','AETBMCRCCC','AETBPMCDBH','BCHK','BCHKMCD','CHARPEND','HEAKMCDBH','KAIHMO','KAIMCD','KAIOON','MCDHMOBH','MCDHMOOS','MCDOOS','MOLMCD','OPTMCDBH','SENHMO','SENKAMCD','SENMCDE','SENMCDI','SENMCDS','SUNINSURED','UHCMDOOS','KAIMCDBH','MCDVA','HUMMCD','FLATRATE','MOLMCDBH','SENMCDBH','MCDFAM','MCDVARH','HUMMCDBH','VAHN','SENHMOBH','HU069','AE119OUT','SE179','BCSILMCD','KAIBH','ZMCDEDVA','MCDPENDHIX','CHARCLIN','FLATINTL','UNIMCD','HU070','UH033')">
                        <xsl:value-of select="concat(Insurance1/adminsmne,PatientDemographics/admpatienttype)" />
                      </xsl:when>
                      <!--CLIENT BILL SCENARIO-->
                      <xsl:when test="$partitionName = 'ARA' and Insurance1/adminsmne = 'C'">
                        <xsl:value-of select="concat(Insurance1/adminsmne,translate(PatientDemographics/ClientID,'-',''))" />
                      </xsl:when>
                      <!--if the account has MISSINGDOC as primary external value code and a secondary external value code but they share the same policy #, only send the secondary as the primary.  do not send the primary MISSINGDOC entry.-->
                      <xsl:when test="$partitionName = 'ARA' and Insurance1/adminsmne = 'MISSINGDOC' and (Insurance1/adminspolicy = Insurance2/adminspolicy)">
                        <xsl:value-of select="Insurance2/adminsmne" />
                      </xsl:when>
                      <!--if the account has MISSINGDOC as primary without a secondary, send a “P” in front of MISSINGDOC - > PMISSINGDOC-->
                      <xsl:when test="$partitionName = 'ARA' and Insurance1/adminsmne = 'MISSINGDOC' and string-length(Insurance2/adminspolicy) = 0">
                        <xsl:value-of select="'PMISSINGDOC'" />
                      </xsl:when>
                      <xsl:when test="$partitionName = 'MID' and Insurance1/adminsmne = 'ORGAN DON'">
                        <xsl:value-of select="'MIDTRANS'" />
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="Insurance1/adminsmne" />
                      </xsl:otherwise>
                    </xsl:choose>
                  </IN1.2>
                  <IN1.3>
                    <xsl:choose>
                      <xsl:when test="Insurance1/adminsmne = 'W.WPPA' and (starts-with(Insurance1/adminspolicy,'C4') or starts-with(Insurance1/adminspolicy,'MF') or starts-with(Insurance1/adminspolicy,'HU') or starts-with(Insurance1/adminspolicy,'MU') or starts-with(Insurance1/adminspolicy,'DW'))">
                        <xsl:value-of select="'CW.WPPA'" />
                      </xsl:when>
                      <xsl:when test="$partitionName = 'FPS' and Insurance1/adminsmne = ('AE104', 'AETNA BET', 'CHAR PEND', 'FLAT RATE', 'HEALTH', 'HEALTH MCD', 'INTNL UINS', 'KAISER MCD', 'MA200', 'MAG CCC P', 'MCD FAM', 'MCD HMOOUT', 'MCD OUT', 'MCD PEND', 'MCD VA', 'MCD WVA', 'MCRMCDDUAL', 'MDVA', 'MDVADOC', 'MDVASC', 'MOL CCC P', 'OPTIMA MCD', 'OPTIMA VAP', 'PSY AET BE', 'PSY AETBEP', 'PSY ECO', 'PSY HEALTH', 'PSY KAIMCD', 'PSY MAG', 'PSY MAGCCP', 'PSY MAGMCD', 'PSY MOLCCP', 'PSY OPTCCP', 'PSY OPTI', 'PSY OPTVAP', 'PSY OPTMD', 'PSY PREMCD', 'PSY TDO', 'PSY UHC', 'PSY UHCMD', 'PSY VA PRE', 'REH AETBEP', 'REH MAGCCP', 'REH MCD', 'UHCMCDSNP', 'UHCMDVA', 'UNIN INT', 'UNINSURED', 'UNITED CCP', 'VA HEALTH', 'VA PRE MCD', 'VI016', 'VI026', 'ZCHA 0-200', 'ZCHA 201-', 'ZMAG RECLS', 'ZMCD ED VA', 'ZMCD KS', 'ZMCD KY', 'ZMCD MO', 'ZMCD NC', 'ZMCD NH', 'ZMCD PE', 'ZMCD RECLA', 'ZMCD WVA', 'ZMCDOOSFOL', 'ZRCPS MCD', 'ZREHABMCD', 'ZZCHAR 100', 'ZZCHAR 200', 'PSYSENMCD', 'SENMCD', 'SENKAIMCD','HEALTH MCD','MCDDISPND','MCDPEND','ZMCD ED VA','PSY MCDHMO','MCD PEND','UNINSUREDE','REH MOLCCP','MDWVIN','MDTN','MDVAOUT','SE179','HUMMCDOON','PSYSENTARA','UH022SC','UH022DOC','AETBMCD','AETBMCDBH','AETBMCRCCC','AETBPMCDBH','BCHK','BCHKMCD','CHARPEND','HEAKMCDBH','KAIHMO','KAIMCD','KAIOON','MCDHMOBH','MCDHMOOS','MCDOOS','MOLMCD','OPTMCDBH','SENHMO','SENKAMCD','SENMCDE','SENMCDI','SENMCDS','SUNINSURED','UHCMDOOS','KAIMCDBH','MCDVA','HUMMCD','FLATRATE','MOLMCDBH','SENMCDBH','MCDFAM','MCDVARH','HUMMCDBH','VAHN','SENHMOBH','HU069','AE119OUT','SE179','BCSILMCD','KAIBH','ZMCDEDVA','MCDPENDHIX','CHARCLIN','FLATINTL','UNIMCD','HU070','UH033')">
                        <xsl:value-of select="concat(Insurance1/adminsmne,PatientDemographics/admpatienttype)" />
                      </xsl:when>
                      <xsl:when test="$partitionName = 'ARA' and Insurance1/adminsmne = 'C'">
                        <xsl:value-of select="concat(Insurance1/adminsmne,translate(PatientDemographics/ClientID,'-',''))" />
                      </xsl:when>
                      <!--if the account has MISSINGDOC as primary external value code and a secondary external value code but they share the same policy #, only send the secondary as the primary.  do not send the primary MISSINGDOC entry.-->
                      <xsl:when test="$partitionName = 'ARA' and Insurance1/adminsmne = 'MISSINGDOC' and (Insurance1/adminspolicy = Insurance2/adminspolicy)">
                        <xsl:value-of select="Insurance2/adminsmne" />
                      </xsl:when>
                      <!--if the account has MISSINGDOC as primary without a secondary, send a “P” in front of MISSINGDOC - > PMISSINGDOC-->
                      <xsl:when test="$partitionName = 'ARA' and Insurance1/adminsmne = 'MISSINGDOC' and string-length(Insurance2/adminspolicy) = 0">
                        <xsl:value-of select="'PMISSINGDOC'" />
                      </xsl:when>
                      <xsl:when test="$partitionName = 'MID' and Insurance1/adminsmne = 'ORGAN DON'">
                        <xsl:value-of select="'MIDTRANS'" />
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="Insurance1/adminsmne" />
                      </xsl:otherwise>
                    </xsl:choose>
                  </IN1.3>
                  <IN1.4>
                    <xsl:value-of select="Insurance1/admInsName" />
                  </IN1.4>
                  <IN1.5>
                    <xsl:if test="$partitionName != 'ARA'">
                      <XAD.1>
                        <xsl:if test="string-length(normalize-space(Insurance1/adminsstreet)) != 0">
                          <xsl:value-of select="upper-case(normalize-space(Insurance1/adminsstreet))" />
                        </xsl:if>
                      </XAD.1>
                      <XAD.2 />
                      <XAD.3>
                        <xsl:value-of select="upper-case(Insurance1/adminscity)" />
                      </XAD.3>
                      <XAD.4>
                        <xsl:value-of select="upper-case(Insurance1/adminsstate)" />
                      </XAD.4>
                      <XAD.5>
                        <xsl:value-of select="Insurance1/adminszip" />
                      </XAD.5>
                    </xsl:if>
                  </IN1.5>
                  <IN1.6 />
                  <IN1.7>
                    <xsl:if test="$partitionName != 'ARA'">
                      <xsl:value-of select="Insurance1/admInsPhone" />
                    </xsl:if>
                  </IN1.7>
                  <IN1.8>
                    <xsl:choose>
                      <xsl:when test="$partitionName = 'FPS' and Insurance1/adminsgroup = ('0M145000','1KR7AM5YF65','1WJ5T08XC97','2462590','UNK','Unknown')">
                        <!--LEAVE BLANK IF FPS AND GROUP NUMBER IN THE LIST-->
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="Insurance1/adminsgroup" />
                      </xsl:otherwise>
                    </xsl:choose>
                  </IN1.8>
                  <IN1.9 />
                  <IN1.10 />
                  <IN1.11 />
                  <IN1.12 />
                  <IN1.13 />
                  <IN1.14>
                    <xsl:value-of select="Insurance1/authnumber" />
                  </IN1.14>
                  <IN1.15>
                    <xsl:text>P</xsl:text>
                  </IN1.15>
                  <IN1.16>
                    <xsl:choose>
                      <xsl:when test="$partitionName = 'NHL'">
                        <XCN.1>
                          <xsl:choose>
                            <xsl:when test="string-length(normalize-space(substring-before(Insurance1/subscribername, ','))) = 0">
                              <xsl:value-of select="normalize-space(substring-before(PatientDemographics/admname, ','))" />
                            </xsl:when>
                            <xsl:otherwise>
                              <xsl:value-of select="normalize-space(substring-before(Insurance1/subscribername, ','))" />
                            </xsl:otherwise>
                          </xsl:choose>
                        </XCN.1>
                        <XCN.2>
                          <xsl:choose>
                            <xsl:when test="string-length(normalize-space(substring-after(Insurance1/subscribername, ','))) = 0">
                              <xsl:value-of select="normalize-space(substring-after(PatientDemographics/admname, ','))" />
                            </xsl:when>
                            <xsl:otherwise>
                              <xsl:value-of select="normalize-space(substring-after(Insurance1/subscribername, ','))" />
                            </xsl:otherwise>
                          </xsl:choose>
                        </XCN.2>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:choose>
                          <xsl:when test="$partitionName = 'PPA' and not(contains(Insurance1/adminsinsuredname,','))">
                            <XPN.1>
                              <xsl:value-of select="Insurance1/adminsinsuredname" />
                            </XPN.1>
                            <XPN.2 />
                          </xsl:when>
                          <xsl:when test="$partitionName = ('SPG','ARA') and string-length(Insurance1/adminsinsuredname) = 0">
                            <XPN.1>
                              <xsl:value-of select="normalize-space(substring-before(PatientDemographics/admname, ','))" />
                            </XPN.1>
                            <XPN.2>
                              <xsl:value-of select="normalize-space(substring-after(PatientDemographics/admname, ','))" />
                            </XPN.2>
                          </xsl:when>
                          <xsl:otherwise>
                            <XCN.1>
                              <xsl:value-of select="normalize-space(substring-before(Insurance1/adminsinsuredname, ','))" />
                            </XCN.1>
                            <XCN.2>
                              <xsl:value-of select="normalize-space(substring-after(Insurance1/adminsinsuredname, ','))" />
                            </XCN.2>
                          </xsl:otherwise>
                        </xsl:choose>
                      </xsl:otherwise>
                    </xsl:choose>
                  </IN1.16>
                  <IN1.17>
                    <!--FOR MID ONLY  - IF IT'S SP USE JUST S INSTEAD (FOR JUST MEDICARE AND MEDIDCAID)-->
                    <xsl:choose>
                      <xsl:when test="$partitionName = 'MID'">
                        <xsl:choose>
                          <xsl:when test="Insurance1/adminsinsuredrel = 'SP' and (Insurance1/adminsmne = 'MC A B' or Insurance1/adminsmne = 'MCD MO')">
                            <xsl:value-of select="'S'" />
                          </xsl:when>
                          <xsl:otherwise>
                            <xsl:value-of select="Insurance1/adminsinsuredrel" />
                          </xsl:otherwise>
                        </xsl:choose>
                      </xsl:when>
                      <xsl:when test="($partitionName = 'SPG' or $partitionName = 'NGP' or $partitionName = 'HAL') and string-length(Insurance1/adminsinsuredrel) = 0">
                        <xsl:choose>
                          <xsl:when test="Guarantor/admGuarName = PatientDemographics/admname">
                            <xsl:value-of select="'SE'" />
                          </xsl:when>
                          <xsl:when test="Guarantor/admGuarName != PatientDemographics/admname and $PatientAge &lt; 18">
                            <xsl:value-of select="'CH'" />
                          </xsl:when>
                          <xsl:when test="Guarantor/admGuarName != PatientDemographics/admname and $PatientAge &gt;= 18">
                            <xsl:value-of select="'UN'" />
                          </xsl:when>
                        </xsl:choose>
                      </xsl:when>
                      <xsl:when test="$partitionName = 'IRL' and $softwareID = ('517','514','515','516') and string-length(Insurance1/adminsinsuredrel) = 0">
                        <xsl:choose>
                          <xsl:when test="Guarantor/admGuarName = PatientDemographics/admname">
                            <xsl:value-of select="'SE'" />
                          </xsl:when>
                          <xsl:when test="Guarantor/admGuarName != PatientDemographics/admname and $PatientAge &lt; 18">
                            <xsl:value-of select="'CH'" />
                          </xsl:when>
                          <xsl:when test="Guarantor/admGuarName != PatientDemographics/admname and $PatientAge &gt;= 18">
                            <xsl:value-of select="'UN'" />
                          </xsl:when>
                        </xsl:choose>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="Insurance1/adminsinsuredrel" />
                      </xsl:otherwise>
                    </xsl:choose>
                  </IN1.17>
                  <IN1.18>
                    <xsl:value-of select="PatientDemographics/admbirthdate" />
                  </IN1.18>
                  <IN1.19>
                    <!--<xsl:if test="$partitionName != 'ARA'">-->
                    <XAD.1>
                      <xsl:value-of select="upper-case(normalize-space(translate(translate(concat(normalize-space(Guarantor/admGuarAddr1),' ',normalize-space(Guarantor/admGuarAddr2)), '.#', ' '),'-',' ')))" />
                    </XAD.1>
                    <XAD.2 />
                    <XAD.3>
                      <xsl:value-of select="upper-case(Guarantor/admGuarCity)" />
                    </XAD.3>
                    <XAD.4>
                      <xsl:value-of select="upper-case(Guarantor/admGuarState)" />
                    </XAD.4>
                    <XAD.5>
                      <xsl:value-of select="Guarantor/admGuarZip" />
                    </XAD.5>
                    <!--</xsl:if>-->
                  </IN1.19>
                  <IN1.20>
                    <xsl:text>Y</xsl:text>
                  </IN1.20>
                  <IN1.21 />
                  <IN1.22 />
                  <IN1.23 />
                  <IN1.24 />
                  <IN1.25 />
                  <IN1.26 />
                  <IN1.27 />
                  <IN1.28 />
                  <IN1.29 />
                  <IN1.30 />
                  <IN1.31 />
                  <IN1.32 />
                  <IN1.33 />
                  <IN1.34 />
                  <IN1.35 />
                  <IN1.36>
                    <xsl:value-of select="Insurance1/adminspolicy" />
                  </IN1.36>
                  <IN1.37 />
                  <IN1.38 />
                  <IN1.39 />
                  <IN1.40 />
                  <IN1.41 />
                  <IN1.42 />
                  <IN1.43>
                    <xsl:value-of select="PatientDemographics/admpatsex" />
                  </IN1.43>
                  <IN1.44 />
                  <IN1.45 />
                  <IN1.46 />
                  <IN1.47 />
                  <IN1.48 />
                  <IN1.49 />
                  <IN1.50 />
                </IN1>
              </ADT_A01.INSURANCE>
            </xsl:if>
          </xsl:if>
          <!--INSURANCE1 - Stamford ONLY - blank insurances default to PPP-->
          <xsl:if test="($partitionName = 'SPG' or $partitionName = 'PPA' or $partitionName = 'NGP' or $partitionName = 'HAL') and Insurance1[(string-length(adminsmne) = 0 or adminsmne = 'BLANK') and string-length(admInsName) = 0] and Insurance2[string-length(adminsmne) = 0]">
            <ADT_A01.INSURANCE>
              <!--IN1-->
              <IN1>
                <IN1.1>
                  <xsl:text>0001</xsl:text>
                </IN1.1>
                <IN1.2>
                  <xsl:choose>
                    <xsl:when test="$partitionName = 'SPG' and contains(Guarantor/admGuarName,'EMPLOYEE HEALTH')">
                      <xsl:value-of select="'868'" />
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="'PPP'" />
                    </xsl:otherwise>
                  </xsl:choose>
                </IN1.2>
                <IN1.3>
                  <xsl:choose>
                    <xsl:when test="$partitionName = 'SPG' and contains(Guarantor/admGuarName,'EMPLOYEE HEALTH')">
                      <xsl:value-of select="'868'" />
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="'PPP'" />
                    </xsl:otherwise>
                  </xsl:choose>
                </IN1.3>
                <IN1.15>
                  <xsl:text>P</xsl:text>
                </IN1.15>
                <IN1.16>
                  <XCN.1>
                    <xsl:value-of select="normalize-space(substring-before(PatientDemographics/admname, ','))" />
                  </XCN.1>
                  <XCN.2>
                    <xsl:value-of select="normalize-space(substring-after(PatientDemographics/admname, ','))" />
                  </XCN.2>
                </IN1.16>
                <IN1.17>
                  <xsl:choose>
                    <xsl:when test="($partitionName = 'SPG' or $partitionName = 'NGP' or $partitionName = 'HAL') and string-length(Insurance1/adminsinsuredrel) = 0">
                      <xsl:choose>
                        <xsl:when test="Guarantor/admGuarName = PatientDemographics/admname">
                          <xsl:value-of select="'SE'" />
                        </xsl:when>
                        <xsl:when test="Guarantor/admGuarName != PatientDemographics/admname and $PatientAge &lt; 18">
                          <xsl:value-of select="'CH'" />
                        </xsl:when>
                        <xsl:when test="Guarantor/admGuarName != PatientDemographics/admname and $PatientAge &gt;= 18">
                          <xsl:value-of select="'UN'" />
                        </xsl:when>
                      </xsl:choose>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:choose>
                        <xsl:when test="string-length(Insurance1/adminsinsuredrel) = 0">
                          <xsl:value-of select="'1'" />
                        </xsl:when>
                        <xsl:otherwise>
                          <xsl:value-of select="Insurance1/adminsinsuredrel" />
                        </xsl:otherwise>
                      </xsl:choose>
                    </xsl:otherwise>
                  </xsl:choose>
                </IN1.17>
                <IN1.18>
                  <xsl:value-of select="PatientDemographics/admbirthdate" />
                </IN1.18>
                <IN1.19>
                  <!--<xsl:if test="$partitionName != 'ARA'">-->
                  <XAD.1>
                    <xsl:value-of select="upper-case(normalize-space(translate(translate(concat(normalize-space(Guarantor/admGuarAddr1),' ',normalize-space(Guarantor/admGuarAddr2)), '.#', ' '),'-',' ')))" />
                  </XAD.1>
                  <XAD.2 />
                  <XAD.3>
                    <xsl:value-of select="upper-case(Guarantor/admGuarCity)" />
                  </XAD.3>
                  <XAD.4>
                    <xsl:value-of select="upper-case(Guarantor/admGuarState)" />
                  </XAD.4>
                  <XAD.5>
                    <xsl:value-of select="Guarantor/admGuarZip" />
                  </XAD.5>
                  <!--</xsl:if>-->
                </IN1.19>
                <IN1.20>
                  <xsl:text>Y</xsl:text>
                </IN1.20>
                <IN1.21 />
                <IN1.22 />
                <IN1.23 />
                <IN1.24 />
                <IN1.25 />
                <IN1.26 />
                <IN1.27 />
                <IN1.28 />
                <IN1.29 />
                <IN1.30 />
                <IN1.31 />
                <IN1.32 />
                <IN1.33 />
                <IN1.34 />
                <IN1.35 />
                <IN1.36>
                  <xsl:value-of select="Insurance1/adminspolicy" />
                </IN1.36>
                <IN1.37 />
                <IN1.38 />
                <IN1.39 />
                <IN1.40 />
                <IN1.41 />
                <IN1.42 />
                <IN1.43>
                  <xsl:value-of select="PatientDemographics/admpatsex" />
                </IN1.43>
                <IN1.44 />
                <IN1.45 />
                <IN1.46 />
                <IN1.47 />
                <IN1.48 />
                <IN1.49 />
                <IN1.50 />
              </IN1>
            </ADT_A01.INSURANCE>
          </xsl:if>
          <!--INSURANCE2-->
          <xsl:if test="Insurance2[string-length(adminsmne) &gt; 0] or ($partitionName = 'HAL' and Insurance2[string-length(admInsName) &gt; 0]) or ($partitionName = 'ARA' and Insurance1/adminsmne = 'SELFPAY')">
            <ADT_A01.INSURANCE>
              <!--IN1-->
              <IN1>
                <IN1.1>
                  <xsl:choose>
                    <xsl:when test="$partitionName = 'SPG' and string-length(Insurance1/adminsmne) = 0">
                      <!--WE HAVE A BLANK INS1 SO MAKE SECONDARY THE PRIMARY INS-->
                      <xsl:text>0001</xsl:text>
                    </xsl:when>
                    <xsl:when test="$partitionName = 'ARA' and Insurance1/adminsmne = 'SELFPAY'">
                      <xsl:text>0001</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:text>0002</xsl:text>
                    </xsl:otherwise>
                  </xsl:choose>
                </IN1.1>
                <IN1.2>
                  <xsl:choose>
                    <xsl:when test="$partitionName = 'NHL' and (Insurance2/admInsName = 'UNINSURED' or Insurance2/admInsName = 'MISCOM1' or Insurance2/admInsName = 'MISCOM2')">
                      <xsl:value-of select="concat('S',Insurance2/admInsName)" />
                    </xsl:when>
                    <xsl:when test="$partitionName = 'FPS' and Insurance2/adminsmne = ('AE104', 'AETNA BET', 'CHAR PEND', 'FLAT RATE', 'HEALTH', 'HEALTH MCD', 'INTNL UINS', 'KAISER MCD', 'MA200', 'MAG CCC P', 'MCD FAM', 'MCD HMOOUT', 'MCD OUT', 'MCD PEND', 'MCD VA', 'MCD WVA', 'MCRMCDDUAL', 'MDVA', 'MDVADOC', 'MDVASC', 'MOL CCC P', 'OPTIMA MCD', 'OPTIMA VAP', 'PSY AET BE', 'PSY AETBEP', 'PSY ECO', 'PSY HEALTH', 'PSY KAIMCD', 'PSY MAG', 'PSY MAGCCP', 'PSY MAGMCD', 'PSY MOLCCP', 'PSY OPTCCP', 'PSY OPTI', 'PSY OPTVAP', 'PSY OPTMD', 'PSY PREMCD', 'PSY TDO', 'PSY UHC', 'PSY UHCMD', 'PSY VA PRE', 'REH AETBEP', 'REH MAGCCP', 'REH MCD', 'UHCMCDSNP', 'UHCMDVA', 'UNIN INT', 'UNINSURED', 'UNITED CCP', 'VA HEALTH', 'VA PRE MCD', 'VI016', 'VI026', 'ZCHA 0-200', 'ZCHA 201-', 'ZMAG RECLS', 'ZMCD ED VA', 'ZMCD KS', 'ZMCD KY', 'ZMCD MO', 'ZMCD NC', 'ZMCD NH', 'ZMCD PE', 'ZMCD RECLA', 'ZMCD WVA', 'ZMCDOOSFOL', 'ZRCPS MCD', 'ZREHABMCD', 'ZZCHAR 100', 'ZZCHAR 200', 'PSYSENMCD', 'SENMCD', 'SENKAIMCD','HEALTH MCD','MCDDISPND','MCDPEND','ZMCD ED VA','PSY MCDHMO','MCD PEND','UNINSUREDE','REH MOLCCP','MDWVIN','MDTN','MDVAOUT','SE179','HUMMCDOON','AETBMCD','AETBMCDBH','AETBMCRCCC','AETBPMCDBH','BCHK','BCHKMCD','CHARPEND','HEAKMCDBH','KAIHMO','KAIMCD','KAIOON','MCDHMOBH','MCDHMOOS','MCDOOS','MOLMCD','OPTMCDBH','SENHMO','SENKAMCD','SENMCDE','SENMCDI','SENMCDS','SUNINSURED','UHCMDOOS','KAIMCDBH','MCDVA','HUMMCD','FLATRATE','MOLMCDBH','SENMCDBH','MCDFAM','MCDVARH','HUMMCDBH','VAHN','SENHMOBH','HU069','AE119OUT','SE179','BCSILMCD','KAIBH','ZMCDEDVA','ZMCDEDVA','MCDPENDHIX','CHARCLIN','FLATINTL','UNIMCD','HU070','UH033')">
                      <xsl:choose>
                        <xsl:when test="Insurance2/adminsmne = 'UNINSURED'">
                          <xsl:value-of select="concat('S',Insurance2/adminsmne,PatientDemographics/admpatienttype)" />
                        </xsl:when>
                        <xsl:otherwise>
                          <xsl:value-of select="concat(Insurance2/adminsmne,PatientDemographics/admpatienttype)" />
                        </xsl:otherwise>
                      </xsl:choose>
                    </xsl:when>
                    <xsl:when test="$partitionName = 'PPA' and Insurance2/adminsmne = ('25022201','5030601','25062401','25064401','21020199','21010199','21040299')">
                      <xsl:value-of select="concat('S',Insurance2/adminsmne)" />
                    </xsl:when>
                    <xsl:when test="$partitionName = 'HAL' and Insurance2/adminsmne = ('10999901','35999901','45999901','50999901','70999901','75999901')">
                      <xsl:value-of select="concat('S',Insurance2/adminsmne)" />
                    </xsl:when>
                    <xsl:when test="$partitionName = 'SPG' and Insurance2/adminsmne = ('10999904')">
                      <xsl:value-of select="concat('S',Insurance2/adminsmne)" />
                    </xsl:when>
                    <xsl:when test="$partitionName = 'NTX' and Insurance2/adminsmne = ('UNINSURED','UNINS.N','UNINS.I','UNINS.E')">
                      <xsl:value-of select="concat('S',Insurance2/adminsmne)" />
                    </xsl:when>
                    <xsl:when test="$partitionName = 'IRL' and $facilityName = ('NOA','LAM','PUX','MAX','NFX','OCX','DEX','MIX','NXX','OMC','OXX','SUN','JFX','LWX','PWX','COX') and Insurance2/adminsmne = ('UNINSURED')">
                      <xsl:value-of select="concat('S',Insurance2/adminsmne)" />
                    </xsl:when>
                    <xsl:when test="$partitionName = 'MID' and Insurance2/adminsmne = 'ORGAN DON'">
                      <xsl:value-of select="'MIDTRANS'" />
                    </xsl:when>
                    <xsl:when test="$partitionName = 'ARA' and Insurance1/adminsmne = 'SELFPAY' and string-length(Insurance2/adminsmne) = 0">
                      <xsl:value-of select="'SELFPAY'" />
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="Insurance2/adminsmne" />
                    </xsl:otherwise>
                  </xsl:choose>
                </IN1.2>
                <IN1.3>
                  <xsl:choose>
                    <xsl:when test="$partitionName = 'NHL' and (Insurance2/admInsName = 'UNINSURED' or Insurance2/admInsName = 'MISCOM1' or Insurance2/admInsName = 'MISCOM2')">
                      <xsl:value-of select="concat('S',Insurance2/admInsName)" />
                    </xsl:when>
                    <xsl:when test="$partitionName = 'FPS' and Insurance2/adminsmne = ('AE104', 'AETNA BET', 'CHAR PEND', 'FLAT RATE', 'HEALTH', 'HEALTH MCD', 'INTNL UINS', 'KAISER MCD', 'MA200', 'MAG CCC P', 'MCD FAM', 'MCD HMOOUT', 'MCD OUT', 'MCD PEND', 'MCD VA', 'MCD WVA', 'MCRMCDDUAL', 'MDVA', 'MDVADOC', 'MDVASC', 'MOL CCC P', 'OPTIMA MCD', 'OPTIMA VAP', 'PSY AET BE', 'PSY AETBEP', 'PSY ECO', 'PSY HEALTH', 'PSY KAIMCD', 'PSY MAG', 'PSY MAGCCP', 'PSY MAGMCD', 'PSY MOLCCP', 'PSY OPTCCP', 'PSY OPTI', 'PSY OPTVAP', 'PSY OPTMD', 'PSY PREMCD', 'PSY TDO', 'PSY UHC', 'PSY UHCMD', 'PSY VA PRE', 'REH AETBEP', 'REH MAGCCP', 'REH MCD', 'UHCMCDSNP', 'UHCMDVA', 'UNIN INT', 'UNINSURED', 'UNITED CCP', 'VA HEALTH', 'VA PRE MCD', 'VI016', 'VI026', 'ZCHA 0-200', 'ZCHA 201-', 'ZMAG RECLS', 'ZMCD ED VA', 'ZMCD KS', 'ZMCD KY', 'ZMCD MO', 'ZMCD NC', 'ZMCD NH', 'ZMCD PE', 'ZMCD RECLA', 'ZMCD WVA', 'ZMCDOOSFOL', 'ZRCPS MCD', 'ZREHABMCD', 'ZZCHAR 100', 'ZZCHAR 200', 'PSYSENMCD', 'SENMCD', 'SENKAIMCD','HEALTH MCD','MCDDISPND','MCDPEND','ZMCD ED VA','PSY MCDHMO','MCD PEND','UNINSUREDE','REH MOLCCP','MDWVIN','MDTN','MDVAOUT','SE179','HUMMCDOON','AETBMCD','AETBMCDBH','AETBMCRCCC','AETBPMCDBH','BCHK','BCHKMCD','CHARPEND','HEAKMCDBH','KAIHMO','KAIMCD','KAIOON','MCDHMOBH','MCDHMOOS','MCDOOS','MOLMCD','OPTMCDBH','SENHMO','SENKAMCD','SENMCDE','SENMCDI','SENMCDS','SUNINSURED','UHCMDOOS','KAIMCDBH','MCDVA','HUMMCD','FLATRATE','MOLMCDBH','SENMCDBH','MCDFAM','MCDVARH','HUMMCDBH','VAHN','SENHMOBH','HU069','AE119OUT','SE179','BCSILMCD','KAIBH','ZMCDEDVA','ZMCDEDVA','MCDPENDHIX','CHARCLIN','FLATINTL','UNIMCD','HU070','UH033')">
                      <xsl:value-of select="concat(Insurance2/adminsmne,PatientDemographics/admpatienttype)" />
                    </xsl:when>
                    <xsl:when test="$partitionName = 'NTX' and Insurance2/adminsmne = ('UNINSURED','UNINS.N','UNINS.I','UNINS.E')">
                      <xsl:value-of select="concat('S',Insurance2/adminsmne)" />
                    </xsl:when>
                    <xsl:when test="$partitionName = 'IRL' and $facilityName = ('NOA','LAM','PUX','MAX','NFX','OCX','DEX','MIX','NXX','OMC','OXX','SUN','JFX','LWX','PWX','COX') and Insurance2/adminsmne = ('UNINSURED')">
                      <xsl:value-of select="concat('S',Insurance2/adminsmne)" />
                    </xsl:when>
                    <xsl:when test="$partitionName = 'MID' and Insurance2/adminsmne = 'ORGAN DON'">
                      <xsl:value-of select="'MIDTRANS'" />
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="Insurance2/adminsmne" />
                    </xsl:otherwise>
                  </xsl:choose>
                </IN1.3>
                <IN1.4>
                  <xsl:choose>
                    <xsl:when test="$partitionName = 'NHL' and (Insurance2/admInsName = 'UNINSURED' or Insurance2/admInsName = 'MISCOM1' or Insurance2/admInsName = 'MISCOM2')">
                      <xsl:value-of select="concat('S',Insurance2/admInsName)" />
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="Insurance2/admInsName" />
                    </xsl:otherwise>
                  </xsl:choose>
                </IN1.4>
                <IN1.5>
                  <xsl:if test="$partitionName != 'ARA'">
                    <XAD.1>
                      <xsl:value-of select="upper-case(Insurance2/adminsstreet)" />
                    </XAD.1>
                    <XAD.2 />
                    <XAD.3>
                      <xsl:value-of select="upper-case(Insurance2/adminscity)" />
                    </XAD.3>
                    <XAD.4>
                      <xsl:value-of select="upper-case(Insurance2/adminsstate)" />
                    </XAD.4>
                    <XAD.5>
                      <xsl:value-of select="Insurance2/adminszip" />
                    </XAD.5>
                  </xsl:if>
                </IN1.5>
                <IN1.6 />
                <IN1.7>
                  <xsl:if test="$partitionName != 'ARA'">
                    <xsl:value-of select="Insurance2/admInsPhone" />
                  </xsl:if>
                </IN1.7>
                <IN1.8>
                  <xsl:value-of select="Insurance2/adminsgroup" />
                </IN1.8>
                <IN1.9 />
                <IN1.10 />
                <IN1.11 />
                <IN1.12 />
                <IN1.13 />
                <IN1.14 />
                <IN1.15>
                  <xsl:text>S</xsl:text>
                </IN1.15>
                <IN1.16>
                  <xsl:choose>
                    <xsl:when test="$partitionName = 'NHL'">
                      <XCN.1>
                        <xsl:value-of select="normalize-space(substring-before(Insurance2/subscribername, ','))" />
                      </XCN.1>
                      <XCN.2>
                        <xsl:value-of select="normalize-space(substring-after(Insurance2/subscribername, ','))" />
                      </XCN.2>
                    </xsl:when>
                    <xsl:when test="$partitionName = 'SPG' and string-length(Insurance1/adminsinsuredname) = 0">
                      <XPN.1>
                        <xsl:value-of select="normalize-space(substring-before(PatientDemographics/admname, ','))" />
                      </XPN.1>
                      <XPN.2>
                        <xsl:value-of select="normalize-space(substring-after(PatientDemographics/admname, ','))" />
                      </XPN.2>
                    </xsl:when>
                    <xsl:when test="$partitionName = 'NGP' and string-length(Insurance2/adminsinsuredname) = 0">
                      <XPN.1>
                        <xsl:value-of select="normalize-space(substring-before(PatientDemographics/admname, ','))" />
                      </XPN.1>
                      <XPN.2>
                        <xsl:value-of select="normalize-space(substring-after(PatientDemographics/admname, ','))" />
                      </XPN.2>
                    </xsl:when>
                    <xsl:when test="$partitionName = 'HAL' and string-length(Insurance2/adminsinsuredname) = 0">
                      <XPN.1>
                        <xsl:value-of select="normalize-space(substring-before(Guarantor/admGuarName, ','))" />
                      </XPN.1>
                      <XPN.2>
                        <xsl:value-of select="normalize-space(substring-after(Guarantor/admGuarName, ','))" />
                      </XPN.2>
                    </xsl:when>
                    <xsl:otherwise>
                      <XCN.1>
                        <xsl:value-of select="normalize-space(substring-before(Insurance2/adminsinsuredname, ','))" />
                      </XCN.1>
                      <XCN.2>
                        <xsl:value-of select="normalize-space(substring-after(Insurance2/adminsinsuredname, ','))" />
                      </XCN.2>
                    </xsl:otherwise>
                  </xsl:choose>
                </IN1.16>
                <IN1.17>
                  <xsl:choose>
                    <xsl:when test="$partitionName = 'SPG' and string-length(Insurance2/adminsinsuredrel) = 0">
                      <xsl:choose>
                        <xsl:when test="Guarantor/admGuarName = PatientDemographics/admname">
                          <xsl:value-of select="'SE'" />
                        </xsl:when>
                        <xsl:when test="Guarantor/admGuarName != PatientDemographics/admname and $PatientAge &lt; 18">
                          <xsl:value-of select="'CH'" />
                        </xsl:when>
                        <xsl:when test="Guarantor/admGuarName != PatientDemographics/admname and $PatientAge &gt;= 18">
                          <xsl:value-of select="'UN'" />
                        </xsl:when>
                      </xsl:choose>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="Insurance2/adminsinsuredrel" />
                    </xsl:otherwise>
                  </xsl:choose>
                </IN1.17>
                <IN1.18>
                  <xsl:value-of select="PatientDemographics/admbirthdate" />
                </IN1.18>
                <IN1.19>
                  <!--<xsl:if test="$partitionName != 'ARA'">-->
                  <XAD.1>
                    <xsl:value-of select="upper-case(normalize-space(translate(translate(concat(normalize-space(Guarantor/admGuarAddr1),' ',normalize-space(Guarantor/admGuarAddr2)), '.#', ' '),'-',' ')))" />
                  </XAD.1>
                  <XAD.2 />
                  <XAD.3>
                    <xsl:value-of select="upper-case(Guarantor/admGuarCity)" />
                  </XAD.3>
                  <XAD.4>
                    <xsl:value-of select="upper-case(Guarantor/admGuarState)" />
                  </XAD.4>
                  <XAD.5>
                    <xsl:value-of select="Guarantor/admGuarZip" />
                  </XAD.5>
                  <!--</xsl:if>-->
                </IN1.19>
                <IN1.20>
                  <xsl:text>Y</xsl:text>
                </IN1.20>
                <IN1.21 />
                <IN1.22 />
                <IN1.23 />
                <IN1.24 />
                <IN1.25 />
                <IN1.26 />
                <IN1.27 />
                <IN1.28 />
                <IN1.29 />
                <IN1.30 />
                <IN1.31 />
                <IN1.32 />
                <IN1.33 />
                <IN1.34 />
                <IN1.35 />
                <IN1.36>
                  <xsl:value-of select="Insurance2/adminspolicy" />
                </IN1.36>
                <IN1.37 />
                <IN1.38 />
                <IN1.39 />
                <IN1.40 />
                <IN1.41 />
                <IN1.42 />
                <IN1.43>
                  <xsl:value-of select="PatientDemographics/admpatsex" />
                </IN1.43>
                <IN1.44 />
                <IN1.45 />
                <IN1.46 />
                <IN1.47 />
                <IN1.48 />
                <IN1.49 />
                <IN1.50 />
              </IN1>
            </ADT_A01.INSURANCE>
          </xsl:if>
          <xsl:if test="position() = count($dataset)">
            <BTS>
              <BTS.1>
                <xsl:value-of select="count($dataset)" />
              </BTS.1>
              <BTS.2 />
              <BTS.3>
                <xsl:value-of select="count($dataset)" />
              </BTS.3>
              <BTS.4 />
            </BTS>
          </xsl:if>
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
  <!-- Function to map facility codes to partition codes using choose statement -->
  <xsl:function as="xs:string" name="mr:getPartitionForARA">
    <xsl:param as="xs:string" name="facility" />
    <xsl:choose>
      <!-- APP Partition -->
      <xsl:when test="$facility = 'PAL' or $facility = 'ADT'">
        <xsl:value-of select="'APP'" />
      </xsl:when>
      <!-- PBP Partition -->
      <xsl:when test="$facility = 'PLB' or $facility = 'ARI' or $facility = 'ECP'">
        <xsl:value-of select="'PBP'" />
      </xsl:when>
      <!-- ASL Partition -->
      <xsl:when test="$facility = 'ADS' or $facility = 'EAS' or $facility = 'PBE'">
        <xsl:value-of select="'ASL'" />
      </xsl:when>
      <!-- ECA Partition -->
      <xsl:when test="$facility = 'AND' or $facility = 'EAC'">
        <xsl:value-of select="'ECA'" />
      </xsl:when>
      <!-- PAI Partition -->
      <xsl:when test="$facility = 'ARG' or $facility = 'EAT' or $facility = 'PPT'">
        <xsl:value-of select="'PAI'" />
      </xsl:when>
      <!-- ARD Partition -->
      <xsl:when test="$facility = 'ANG'">
        <xsl:value-of select="'ARD'" />
      </xsl:when>
      <!-- ALI Partition -->
      <xsl:when test="$facility = 'ALI'">
        <xsl:value-of select="'AHS'" />
      </xsl:when>
      <!-- AHS Partition -->
      <xsl:when test="$facility = 'AHS'">
        <xsl:value-of select="'COP'" />
      </xsl:when>
      <!-- Default case - return empty string or error message -->
      <xsl:otherwise>
        <xsl:value-of select="''" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  <!-- Template to calculate age -->
  <xsl:template name="calculateAge">
    <xsl:param as="xs:date" name="birthDate" />
    <xsl:param as="xs:date" name="currentDate" />
    <!-- Calculate years between dates -->
    <xsl:variable name="years" select="year-from-date($currentDate) - year-from-date($birthDate)" />
    <!-- Adjust age if birthday hasn't occurred this year -->
    <xsl:choose>
      <xsl:when test="month-from-date($currentDate) &lt; month-from-date($birthDate) or (month-from-date($currentDate) = month-from-date($birthDate) and day-from-date($currentDate) &lt; day-from-date($birthDate))">
        <xsl:value-of select="$years - 1" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$years" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>

