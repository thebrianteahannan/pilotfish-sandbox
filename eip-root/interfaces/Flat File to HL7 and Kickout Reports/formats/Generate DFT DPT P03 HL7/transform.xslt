<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:datetime="http://exslt.org/dates-and-times" xmlns:mr="mr" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="datetime" version="3.1">
  <xsl:param name="partitionName" />
  <xsl:param name="clientName" />
  <xsl:param name="facilityName" />
  <xsl:param name="facilityCode" />
  <xsl:param name="defaultPerfDr" />
  <xsl:param name="softwareID" />
  <xsl:param name="accountNumAlpha" />
  <xsl:template match="/XCSData">
    <XCSData>
      <xsl:variable name="datetime" select="substring(translate(datetime:dateTime(), '-T:', ''), 1, 12)" />
      <xsl:for-each select="Import/Group[not(@stripped = 'true') and ./PatientDemographics[not(@stripped = 'true')]]">
        <xsl:sort select="PatientDemographics/admAcctNum" />
        <xsl:variable name="accountNumber" select="PatientDemographics/admAcctNum" />
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
                    <xsl:when test="$softwareID = ('114','126','112','111','109','110','122','113','118','123','120','800','801','514','515','516','517','652','760','761')">
                      <xsl:choose>
                        <xsl:when test="$softwareID = '801' and (PatientDemographics/admLocation = 'ATNACU' or PatientDemographics/admLocation = 'PBPACU')">
                          <xsl:value-of select="'PAI'" />
                        </xsl:when>
                        <xsl:otherwise>
                          <xsl:value-of select="$accountNumAlpha" />
                        </xsl:otherwise>
                      </xsl:choose>
                    </xsl:when>
                    <xsl:when test="$partitionName = 'NGP' and $clientName = 'AP'">
                      <xsl:choose>
                        <xsl:when test="starts-with(PatientDemographics/admLocation,'OH SEBASTIAN RIVER HOSPITAL')">
                          <xsl:value-of select="'NG'" />
                        </xsl:when>
                        <xsl:when test="starts-with(PatientDemographics/admLocation,'OH MELBOURNE HOSPITAL')">
                          <xsl:value-of select="'NB'" />
                        </xsl:when>
                        <xsl:otherwise>
                          <xsl:value-of select="'NB'" />
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
                    <!--Add the Facility Code and '00' to the front of the Patient Account Number + last 9 digits of the Patient Account Number.  Example: HH1234567890-->
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
                    <xsl:value-of select="concat($facilityCode2,PatientDemographics/admAcctNum)" />
                  </xsl:when>
                  <xsl:otherwise>
                    <!--Add the Facility Code to the front of the Patient Account Number + last 9 digits of the Patient Account Number.  Example: HH123456789-->
                    <xsl:value-of select="concat($facilityCode2, substring(PatientDemographics/admAcctNum, string-length(PatientDemographics/admAcctNum) - 8))" />
                  </xsl:otherwise>
                </xsl:choose>
              </CX.1>
            </PID.3>
            <PID.4 />
            <PID.5>
              <XPN.1>
                <xsl:value-of select="normalize-space(substring-before(PatientDemographics/admname, ','))" />
              </XPN.1>
              <XPN.2>
                <xsl:value-of select="normalize-space(substring-after(PatientDemographics/admname, ','))" />
              </XPN.2>
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
            <PID.11 />
            <PID.12 />
            <PID.13 />
            <!--This field isn't mentioned in the mapping spreadsheet, should remove it or still map it?-->
            <PID.14>
              <xsl:value-of select="PatientDemographics/admemplphone" />
            </PID.14>
            <PID.15 />
            <PID.16 />
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
          <!--<xsl:for-each-group group-by="concat(radExamServDate,radExamPerformingPhyMne,radExamCPT,radExamBillingCode,radExamBillingCodeOrig,radAcctNum)" select="Charge">-->
          <xsl:for-each-group group-by="concat(radExamServDate,radExamPerformingPhyMne,radExamCPT,radExamBillingCode,radAcctNum)" select="Charge">
            <xsl:sort order="ascending" select="radExamServDate" />
            <xsl:sort order="ascending" select="radExamCPT" />
            <xsl:variable name="CPT" select="radExamCPT" />
            <xsl:variable name="CDM">
              <xsl:choose>
                <xsl:when test="string-length(radExamBillingCode) &gt; 0">
                  <xsl:choose>
                    <xsl:when test="$partitionName = 'NHL'">
                      <xsl:value-of select="radExamBillingCodeOrig" />
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="radExamBillingCode" />
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="radExamBillingCodeOrig" />
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            <xsl:choose>
              <!--NORMAL NON-MUE EDIT FT1's-->
              <xsl:when test="$softwareID != '120' and $partitionName != 'NHL' and count(//MUE_EDITS[SOFTWARE_ID = $softwareID and CPT = $CPT]) = 0">
                <xsl:variable name="sumNum" select="sum(current-group()/radNumOfTimes)" />
                <xsl:if test="number($sumNum) &gt; 0">
                  <xsl:for-each select="(current-group())[1]">
                    <xsl:sort order="ascending" select="radExamServDate" />
                    <xsl:sort order="ascending" select="radExamCPT" />
                    <xsl:call-template name="FT1Loop">
                      <xsl:with-param name="i" select="number(1)" />
                      <!--Only need to loop once for non-MUE Edits because there is no max value per line when doing non-MUE Edits-->
                      <xsl:with-param name="numTimesToLoop" select="1" />
                      <xsl:with-param name="chargeValue" select="$sumNum" />
                      <xsl:with-param name="sumNum" select="$sumNum" />
                      <xsl:with-param name="isMUE" select="'no'" />
                      <xsl:with-param name="cdm" select="$CDM" />
                      <xsl:with-param name="cpt" select="//MUE_EDITS[SOFTWARE_ID = $softwareID and CDM = $CDM]/CPT" />
                    </xsl:call-template>
                  </xsl:for-each>
                </xsl:if>
              </xsl:when>
              <xsl:when test="$softwareID != '120' and $partitionName = 'NHL' and count(//MUE_EDITS[SOFTWARE_ID = $softwareID and CDM = $CDM]) = 0">
                <xsl:variable name="sumNum" select="sum(current-group()/radNumOfTimes)" />
                <xsl:if test="number($sumNum) &gt; 0">
                  <xsl:for-each select="(current-group())[1]">
                    <xsl:sort order="ascending" select="radExamServDate" />
                    <xsl:sort order="ascending" select="radExamCPT" />
                    <xsl:call-template name="FT1Loop">
                      <xsl:with-param name="i" select="number(1)" />
                      <!--Only need to loop once for non-MUE Edits because there is no max value per line when doing non-MUE Edits-->
                      <xsl:with-param name="numTimesToLoop" select="1" />
                      <xsl:with-param name="chargeValue" select="$sumNum" />
                      <xsl:with-param name="sumNum" select="$sumNum" />
                      <xsl:with-param name="isMUE" select="'no'" />
                      <xsl:with-param name="cdm" select="$CDM" />
                      <xsl:with-param name="cpt" select="//MUE_EDITS[SOFTWARE_ID = $softwareID and CDM = $CDM]/CPT" />
                    </xsl:call-template>
                  </xsl:for-each>
                </xsl:if>
              </xsl:when>
              <!--NORMAL NON-MUE EDIT FT1's FOR SOFTWARE ID 120 ONLY-->
              <xsl:when test="$softwareID = '120' and count(//MUE_EDITS[SOFTWARE_ID = 120 and CDM = $CDM]) = 0">
                <xsl:variable name="sumNum" select="sum(current-group()/radNumOfTimes)" />
                <xsl:if test="number($sumNum) &gt; 0">
                  <xsl:for-each select="(current-group())[1]">
                    <xsl:sort order="ascending" select="radExamServDate" />
                    <xsl:sort order="ascending" select="radExamCPT" />
                    <!--<xsl:variable name="CDM" select="radExamBillingCode" />-->
                    <xsl:call-template name="FT1Loop">
                      <xsl:with-param name="i" select="number(1)" />
                      <!--Only need to loop once for non-MUE Edits because there is no max value per line when doing non-MUE Edits-->
                      <xsl:with-param name="numTimesToLoop" select="1" />
                      <xsl:with-param name="chargeValue" select="$sumNum" />
                      <xsl:with-param name="sumNum" select="$sumNum" />
                      <xsl:with-param name="isMUE" select="'no'" />
                      <xsl:with-param name="cdm" select="$CDM" />
                      <xsl:with-param name="cpt" select="//MUE_EDITS[SOFTWARE_ID = $softwareID and CDM = $CDM]/CPT" />
                    </xsl:call-template>
                  </xsl:for-each>
                </xsl:if>
              </xsl:when>
              <!--MUE EDIT FT1's - split up charges so there is only ever the max value per line-->
              <xsl:otherwise>
                <xsl:variable name="sumNum" select="sum(current-group()/radNumOfTimes)" />
                <xsl:variable name="CDM_ORIG" select="radExamBillingCodeOrig" />
                <xsl:variable name="maxValuePerLine" select="//MUE_EDITS[SOFTWARE_ID = $softwareID and CDM = $CDM_ORIG]/MAX_VALUE_PER_LINE" />
                <xsl:choose>
                  <xsl:when test="$softwareID = '700' and string-length($maxValuePerLine) = 0">
                    <!--PPA ONLY - DO NORMAL CHARGE IF NO MAX VALUE PER LINE DETERMINED TO FIX BUG-->
                    <xsl:if test="number($sumNum) &gt; 0">
                      <xsl:for-each select="(current-group())[1]">
                        <xsl:sort order="ascending" select="radExamServDate" />
                        <xsl:sort order="ascending" select="radExamCPT" />
                        <!--<xsl:variable name="CDM" select="radExamBillingCode" />-->
                        <xsl:call-template name="FT1Loop">
                          <xsl:with-param name="i" select="number(1)" />
                          <!--Only need to loop once for non-MUE Edits because there is no max value per line when doing non-MUE Edits-->
                          <xsl:with-param name="numTimesToLoop" select="1" />
                          <xsl:with-param name="chargeValue" select="$sumNum" />
                          <xsl:with-param name="sumNum" select="$sumNum" />
                          <xsl:with-param name="isMUE" select="'no'" />
                          <xsl:with-param name="cdm" select="$CDM" />
                          <xsl:with-param name="cpt" select="//MUE_EDITS[SOFTWARE_ID = $softwareID and CDM = $CDM]/CPT" />
                        </xsl:call-template>
                      </xsl:for-each>
                    </xsl:if>
                  </xsl:when>
                  <xsl:when test="number($sumNum) &gt; 0">
                    <xsl:for-each select="(current-group())[1]">
                      <xsl:sort order="ascending" select="radExamServDate" />
                      <xsl:sort order="ascending" select="radExamCPT" />
                      <!--<xsl:variable name="CDM" select="radExamBillingCode" />-->
                      <xsl:variable name="numTimesToLoop" select="ceiling($sumNum div $maxValuePerLine)" />
                      <!--ADD AN ELEMENT HERE TO SHOW THAT WE'VE DONE AN MUE EDIT AND HOW IT WAS BROKEN DOWN-->
                      <MUE_EDIT_LOG>
                        <xsl:attribute name="sum_num" select="$sumNum" />
                        <xsl:attribute name="max_value_per_line" select="$maxValuePerLine" />
                        <xsl:attribute name="num_broken_down_charges" select="$numTimesToLoop" />
                        <AccountNumber>
                          <xsl:value-of select="radAcctNum" />
                        </AccountNumber>
                        <InsuranceName>
                          <xsl:value-of select="../Insurance1/admInsName" />
                        </InsuranceName>
                        <InsurancePlan>
                          <xsl:value-of select="../Insurance1/adminsgroup" />
                        </InsurancePlan>
                        <PatientName>
                          <xsl:value-of select="../PatientDemographics/admname" />
                        </PatientName>
                        <ServiceDate>
                          <xsl:value-of select="radExamServDate" />
                        </ServiceDate>
                        <CDM>
                          <xsl:value-of select="$CDM" />
                        </CDM>
                        <CDMS_FROM_TABLE>
                          <xsl:for-each select="//MUE_EDITS[SOFTWARE_ID = $softwareID and CDM = $CDM]/CDM">
                            <xsl:value-of select="." />
                          </xsl:for-each>
                        </CDMS_FROM_TABLE>
                        <CDM_ORIG>
                          <xsl:value-of select="$CDM_ORIG" />
                        </CDM_ORIG>
                        <CPT>
                          <!--<xsl:value-of select="radExamCPT" />-->
                          <xsl:value-of select="//MUE_EDITS[SOFTWARE_ID = $softwareID and CDM = $CDM]/CPT" />
                        </CPT>
                      </MUE_EDIT_LOG>
                      <xsl:call-template name="FT1Loop">
                        <xsl:with-param name="i" select="number(1)" />
                        <!--Loop for the number of times we need to based on the total number for the charge value and the max value allowed per line-->
                        <xsl:with-param name="numTimesToLoop" select="$numTimesToLoop" />
                        <xsl:with-param name="chargeValue" select="$maxValuePerLine" />
                        <xsl:with-param name="sumNum" select="$sumNum" />
                        <xsl:with-param name="isMUE" select="'yes'" />
                        <xsl:with-param name="cdm" select="$CDM" />
                        <xsl:with-param name="cpt" select="//MUE_EDITS[SOFTWARE_ID = $softwareID and CDM = $CDM]/CPT" />
                      </xsl:call-template>
                      <MUE_EDIT_LOG>END EDIT</MUE_EDIT_LOG>
                    </xsl:for-each>
                  </xsl:when>
                </xsl:choose>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:for-each-group>
        </ADT_A01>
      </xsl:for-each>
    </XCSData>
  </xsl:template>
  <!--FT1 Template-->
  <xsl:template name="FT1Loop">
    <xsl:param name="i" />
    <xsl:param name="numTimesToLoop" />
    <xsl:param name="chargeValue" />
    <xsl:param name="sumNum" />
    <xsl:param name="isMUE" />
    <xsl:param name="cdm" />
    <xsl:param name="cpt" />
    <xsl:variable name="remainderChargeValue" select="$sumNum mod $chargeValue" />
    <xsl:if test="($isMUE = 'yes' and ( ($i != $numTimesToLoop) or ($i = $numTimesToLoop and $remainderChargeValue &gt;= 0) or ($i = 1 and $numTimesToLoop = 1)) ) or ($isMUE = 'no')">
      <FT1>
        <xsl:if test="$partitionName = 'SPG'">
          <xsl:attribute name="patient-type" select="../PatientDemographics/admpatienttype" />
        </xsl:if>
        <FT1.1 />
        <FT1.2 />
        <FT1.3 />
        <FT1.4>
          <xsl:value-of select="radExamServDate" />
        </FT1.4>
        <FT1.5 />
        <FT1.6 />
        <xsl:variable name="theCPT">
          <xsl:choose>
            <xsl:when test="$partitionName = 'NHL' and $isMUE = 'yes'">
              <xsl:value-of select="$cpt" />
            </xsl:when>
            <xsl:when test="string-length(radExamCPT) &gt; 0">
              <xsl:value-of select="radExamCPT" />
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$cpt" />
              <!--<xsl:value-of select="radExamCPT" />-->
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <FT1.7>
          <xsl:choose>
            <!--non-MUE Edit-->
            <xsl:when test="$isMUE = 'no'">
              <xsl:value-of select="$theCPT" />
            </xsl:when>
            <!--MUE Edit-->
            <xsl:otherwise>
              <!--First one will not have 2659 appended but all other MUE Edits after the first will have it appended-->
              <xsl:choose>
                <xsl:when test="$i = 1">
                  <xsl:value-of select="$theCPT" />
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="concat($theCPT,'2659')" />
                </xsl:otherwise>
              </xsl:choose>
            </xsl:otherwise>
          </xsl:choose>
        </FT1.7>
        <FT1.8 />
        <FT1.9 />
        <!--FT1.10 - Charge Value-->
        <FT1.10>
          <xsl:choose>
            <!--non-MUE Edit-->
            <xsl:when test="$isMUE = 'no'">
              <xsl:value-of select="$sumNum" />
            </xsl:when>
            <!--MUE Edit-->
            <xsl:otherwise>
              <xsl:choose>
                <xsl:when test="$i = $numTimesToLoop and $i != 1">
                  <!--REMAINDER CHARGE VALUE FOR LAST ONE-->
                  <xsl:choose>
                    <xsl:when test="$remainderChargeValue != 0">
                      <xsl:value-of select="$remainderChargeValue" />
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="$chargeValue" />
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:choose>
                    <!--<xsl:when test="$sumNum = 1">-->
                    <!--<xsl:value-of select="$sumNum" />-->
                    <!--</xsl:when>-->
                    <xsl:when test="$sumNum &lt; $chargeValue">
                      <xsl:value-of select="$sumNum" />
                    </xsl:when>
                    <xsl:otherwise>
                      <!--MAX CHARGE VALUE-->
                      <xsl:value-of select="$chargeValue" />
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:otherwise>
          </xsl:choose>
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
              <xsl:when test="$partitionName = 'PPA' and $clientName = 'NEO'">
                <xsl:choose>
                  <xsl:when test="misOrderingPhyName = 'CCH CLINICAL LABORATORY'">
                    <xsl:value-of select="'PE'" />
                  </xsl:when>
                  <xsl:when test="misOrderingPhyName = 'GCMC CLINICAL LABORATORY'">
                    <xsl:value-of select="'PC'" />
                  </xsl:when>
                  <xsl:when test="misOrderingPhyName = 'HPMC CLINICAL LABORATORY'">
                    <xsl:value-of select="'PD'" />
                  </xsl:when>
                  <xsl:when test="misOrderingPhyName = 'LHCP CLINICAL LABORATORY'">
                    <xsl:value-of select="'PB'" />
                  </xsl:when>
                  <xsl:when test="misOrderingPhyName = 'LMH CLINICAL LABORATORY'">
                    <xsl:value-of select="'PA'" />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="'PA'" />
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:when>
              <xsl:when test="$partitionName = 'NGP' and $clientName = 'AP'">
                <!--USE THE LAB NAME FOR THE READING LOCATION-->
                <xsl:choose>
                  <xsl:when test="starts-with(../PatientDemographics/LabName,'SRH')">
                    <xsl:value-of select="'NG'" />
                  </xsl:when>
                  <xsl:when test="starts-with(../PatientDemographics/LabName,'MBH')">
                    <xsl:value-of select="'NB'" />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="'NB'" />
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="$facilityCode" />
              </xsl:otherwise>
            </xsl:choose>
          </CX.4>
          <CX.5 />
          <CX.6>
            <!--WE DON'T WANT TO APPLY THE E22 CHANGE TO FT1'S SO REVERSE IT IF IT'S E22-->
            <xsl:variable name="patientType" select="../PatientDemographics/admpatienttype" />
            <xsl:choose>
              <xsl:when test="$patientType = 'E22'">
                <xsl:value-of select="'E'" />
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="$patientType" />
              </xsl:otherwise>
            </xsl:choose>
          </CX.6>
        </FT1.16>
        <FT1.17 />
        <FT1.18 />
        <FT1.19 />
        <FT1.20>
          <CX.1>
            <!--FOR FT WALTON (both splits and SoftwareID=279) ONLY AND CDM CODES (816021 AND 806762) WE DON'T WANT TO USE THE DEFAULT BUT USE NC24 INSTEAD-->
            <xsl:choose>
              <xsl:when test="$softwareID = '279' and ($cdm = '816021' or $cdm = '806762')">
                <xsl:value-of select="'NC24'" />
              </xsl:when>
              <xsl:when test="$softwareID = ('652') and $cdm = ('84165','84166','85060','85097','86077','86078','86079','88104','88106','88108','88112','88120','88121','88125','88141','88160','88161','88162','88172','88173','88177','88182','88187','88188','88189','88291','88300','88302','88304','88305','88307','88309','88311','88312','88313','88314','88319','88321','88323','88325','88329','88331','88332','88333','88334','88341','88342','88344','88346','88348','88350','88355','88356','88358','88360','88361','88362','88363','88364','88365','88366','88367','88368','88369','88371','88372','88373','88374','88377','88380','88381','88387','G0416')">
                <xsl:value-of select="radOrderingPhyLic" />
              </xsl:when>
              <xsl:when test="$softwareID = ('760','761') and radExamCPT = ('84165','84166','85060','85097','86077','86078','86079','88104','88106','88108','88112','88120','88121','88125','88141','88160','88161','88162','88172','88173','88177','88182','88187','88188','88189','88291','88300','88302','88304','88305','88307','88309','88311','88312','88313','88314','88319','88321','88323','88325','88329','88331','88332','88333','88334','88341','88342','88344','88346','88348','88350','88355','88356','88358','88360','88361','88362','88363','88364','88365','88366','88367','88368','88369','88371','88372','88373','88374','88377','88380','88381','88387','G0416')">
                <xsl:choose>
                  <xsl:when test="string-length(orderingDrNPI) != 0">
                    <xsl:value-of select="orderingDrNPI" />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:choose>
                      <xsl:when test="string-length(misOrderingPhyName) = 0">
                        <xsl:value-of select="'SU'" />
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="translate(translate(misOrderingPhyName,'abcdefghijklmnopqrstuvwxyz','ABCDEFGHIJKLMNOPQRSTUVWXYZ'),' ','')" />
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:when>
              <xsl:when test="$softwareID = ('801','800')">
                <xsl:value-of select="translate(translate(RenderingPhysicianNPI,'abcdefghijklmnopqrstuvwxyz','ABCDEFGHIJKLMNOPQRSTUVWXYZ'),' ','')" />
              </xsl:when>
              <xsl:when test="$softwareID = ('701','651','751')">
                <xsl:value-of select="orderingDrNPI" />
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="$defaultPerfDr" />
              </xsl:otherwise>
            </xsl:choose>
          </CX.1>
          <CX.2>
            <xsl:choose>
              <xsl:when test="$softwareID = '751' or ($softwareID = '652' and $cdm = ('84165','84166','85060','85097','86077','86078','86079','88104','88106','88108','88112','88120','88121','88125','88141','88160','88161','88162','88172','88173','88177','88182','88187','88188','88189','88291','88300','88302','88304','88305','88307','88309','88311','88312','88313','88314','88319','88321','88323','88325','88329','88331','88332','88333','88334','88341','88342','88344','88346','88348','88350','88355','88356','88358','88360','88361','88362','88363','88364','88365','88366','88367','88368','88369','88371','88372','88373','88374','88377','88380','88381','88387','G0416'))">
                <xsl:value-of select="translate(radOrderingPhyMne,' ','')" />
              </xsl:when>
              <xsl:when test="$softwareID = ('760','761') and radExamCPT = ('84165','84166','85060','85097','86077','86078','86079','88104','88106','88108','88112','88120','88121','88125','88141','88160','88161','88162','88172','88173','88177','88182','88187','88188','88189','88291','88300','88302','88304','88305','88307','88309','88311','88312','88313','88314','88319','88321','88323','88325','88329','88331','88332','88333','88334','88341','88342','88344','88346','88348','88350','88355','88356','88358','88360','88361','88362','88363','88364','88365','88366','88367','88368','88369','88371','88372','88373','88374','88377','88380','88381','88387','G0416')">
                <xsl:choose>
                  <xsl:when test="string-length(orderingDrNPI) != 0 and string-length(misOrderingPhyName) != 0">
                    <xsl:value-of select="translate(translate(misOrderingPhyName,'abcdefghijklmnopqrstuvwxyz','ABCDEFGHIJKLMNOPQRSTUVWXYZ'),' ','')" />
                  </xsl:when>
                  <xsl:otherwise>
                    <!--LEAVE BLANK-->
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:when>
            </xsl:choose>
          </CX.2>
        </FT1.20>
        <FT1.21 />
        <FT1.22 />
        <FT1.23 />
        <FT1.24 />
        <FT1.25>
          <xsl:attribute name="alternate-account-numbers" select="../AlternateAccountNumber" />
          <xsl:choose>
            <xsl:when test="$isMUE = 'yes'">
              <!--If it's an MUE Edit then we need to use the CPT code instead of the CDM code-->
              <!--First one will not have 2659 appended but all other MUE Edits after the first will have it appended-->
              <xsl:choose>
                <xsl:when test="$softwareID != '120'">
                  <xsl:choose>
                    <xsl:when test="$i = 1">
                      <xsl:value-of select="$theCPT" />
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="concat($theCPT,'2659')" />
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                  <!--SOFTWAREID = 120, WHERE WE DON'T HAVE CPT CODES COMING IN SO WE NEED TO TAKE THE VALUE FROM THE MUE_EDITS TABLE IN DB-->
                  <xsl:choose>
                    <xsl:when test="$i = 1">
                      <xsl:value-of select="$theCPT" />
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="concat($theCPT,'2659')" />
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
              <xsl:variable name="billingCode">
                <xsl:choose>
                  <xsl:when test="string-length(radExamBillingCode) &gt; 0">
                    <xsl:value-of select="radExamBillingCode" />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="radExamBillingCodeOrig" />
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:variable>
              <xsl:choose>
                <xsl:when test="contains('prof.fee', $billingCode)">
                  <xsl:choose>
                    <xsl:when test="string-length($billingCode) &gt; 0">
                      <xsl:value-of select="upper-case($billingCode)" />
                    </xsl:when>
                    <xsl:otherwise>BLANK</xsl:otherwise>
                  </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:choose>
                    <xsl:when test="string-length($billingCode) &gt; 0">
                      <xsl:choose>
                        <!--IF ZERO CDM CODE THEN WE DON'T WANT 0 BUT INSTEAD WE WANT A BLANK STRING-->
                        <xsl:when test="$billingCode = '0' or $billingCode = '00' or $billingCode = '000' or $billingCode = '0000' or $billingCode = '00000' or $billingCode = '000000'">BLANK</xsl:when>
                        <xsl:otherwise>
                          <xsl:value-of select="$billingCode" />
                        </xsl:otherwise>
                      </xsl:choose>
                    </xsl:when>
                    <xsl:otherwise>BLANK</xsl:otherwise>
                  </xsl:choose>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:otherwise>
          </xsl:choose>
        </FT1.25>
        <!--Mapping spreadsheet mentions NO DATA but we have 26 here so what should we do?-->
        <FT1.26>
          <xsl:variable name="ins" select="Insurance1/admInsMne" />
          <xsl:if test="count(/XCSData/query_results/PMA_MOD26_ACCTS/PMA_MOD26_ACCTS[INS_CODES = $ins]) != 0">
            <xsl:text>26</xsl:text>
          </xsl:if>
        </FT1.26>
        <FT1.27 />
      </FT1>
    </xsl:if>
    <xsl:if test="$i &lt; $numTimesToLoop">
      <xsl:call-template name="FT1Loop">
        <xsl:with-param name="i" select="$i + 1" />
        <xsl:with-param name="numTimesToLoop" select="$numTimesToLoop" />
        <xsl:with-param name="chargeValue" select="$chargeValue" />
        <xsl:with-param name="sumNum" select="$sumNum" />
        <xsl:with-param name="isMUE" select="$isMUE" />
        <xsl:with-param name="cdm" select="$cdm" />
        <xsl:with-param name="cpt" select="$cpt" />
      </xsl:call-template>
    </xsl:if>
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
        <xsl:value-of select="'ARA'" />
      </xsl:when>
      <!-- AHS Partition -->
      <xsl:when test="$facility = 'AHS'">
        <xsl:value-of select="'ARA'" />
      </xsl:when>
      <!-- Default case - return empty string or error message -->
      <xsl:otherwise>
        <xsl:value-of select="''" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
</xsl:stylesheet>

