<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:datetime="http://exslt.org/dates-and-times" xmlns:mr="mr" exclude-result-prefixes="datetime" version="3.1">
  <xsl:param name="partitionName" />
  <xsl:param name="clientName" />
  <xsl:param name="facilityName" />
  <xsl:param name="facilityCode" />
  <xsl:param name="defaultPerfDr" />
  <xsl:param name="softwareID" />
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
                <xsl:choose>
                  <xsl:when test="$partitionName = 'MID'">
                    <!--Add the Facility Code to the front of the Patient Account Number + last 11 digits of the Patient Account Number.  Example: HH12345678901-->
                    <xsl:value-of select="concat($facilityCode, substring(PatientDemographics/admAcctNum, string-length(PatientDemographics/admAcctNum) - 10))" />
                  </xsl:when>
                  <xsl:otherwise>
                    <!--Add the Facility Code to the front of the Patient Account Number + last 9 digits of the Patient Account Number.  Example: HH123456789-->
                    <xsl:value-of select="concat($facilityCode, substring(PatientDemographics/admAcctNum, string-length(PatientDemographics/admAcctNum) - 8))" />
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
          <xsl:for-each-group group-by="concat(radExamServDate,radExamPerformingPhyMne,radExamCPT,radExamBillingCode,radAcctNum)" select="Charge">
            <xsl:sort order="ascending" select="radExamServDate" />
            <xsl:sort order="ascending" select="radExamCPT" />
            <xsl:variable name="CPT" select="radExamCPT" />
            <xsl:variable name="CDM" select="radExamBillingCode" />
            <xsl:choose>
              <!--NORMAL NON-MUE EDIT FT1's-->
              <xsl:when test="count(//MUE_EDITS[SOFTWARE_ID = $softwareID and CPT = $CPT]) = 0">
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
                    </xsl:call-template>
                  </xsl:for-each>
                </xsl:if>
              </xsl:when>
              <!--MUE EDIT FT1's - split up charges so there is only ever the max value per line-->
              <xsl:otherwise>
                <xsl:variable name="sumNum" select="sum(current-group()/radNumOfTimes)" />
                <xsl:variable name="CDM_ORIG" select="radExamBillingCodeOrig" />
                <xsl:variable name="maxValuePerLine" select="//MUE_EDITS[SOFTWARE_ID = $softwareID and CDM = $CDM_ORIG]/MAX_VALUE_PER_LINE" />
                <xsl:if test="number($sumNum) &gt; 0">
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
                      <CDM_ORIG>
                        <xsl:value-of select="$CDM_ORIG" />
                      </CDM_ORIG>
                      <CPT>
                        <xsl:value-of select="radExamCPT" />
                      </CPT>
                    </MUE_EDIT_LOG>
                    <xsl:call-template name="FT1Loop">
                      <xsl:with-param name="i" select="number(1)" />
                      <!--Loop for the number of times we need to based on the total number for the charge value and the max value allowed per line-->
                      <xsl:with-param name="numTimesToLoop" select="$numTimesToLoop" />
                      <xsl:with-param name="chargeValue" select="$maxValuePerLine" />
                      <xsl:with-param name="sumNum" select="$sumNum" />
                      <xsl:with-param name="isMUE" select="'yes'" />
                    </xsl:call-template>
                    <MUE_EDIT_LOG>END EDIT</MUE_EDIT_LOG>
                  </xsl:for-each>
                </xsl:if>
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
    <xsl:variable name="remainderChargeValue" select="$sumNum mod $chargeValue" />
    -----
		i=
    <xsl:value-of select="$i" />
    ;
		ismue=
    <xsl:value-of select="$isMUE" />
    ;
		numTimesToLoop
    <xsl:value-of select="$numTimesToLoop" />
    ;
		remainderChargeValue
    <xsl:value-of select="$remainderChargeValue" />
    ;
		-----
    <xsl:if test="($isMUE = 'yes' and ($i != $numTimesToLoop) or ($i = $numTimesToLoop and $remainderChargeValue &gt; 0) or ($i = 1 and $numTimesToLoop = 1)) or ($isMUE = 'no')">
      <FT1>
        <FT1.1 />
        <FT1.2 />
        <FT1.3 />
        <FT1.4>
          <xsl:value-of select="radExamServDate" />
        </FT1.4>
        <FT1.5 />
        <FT1.6 />
        <FT1.7>
          <xsl:choose>
            <!--non-MUE Edit-->
            <xsl:when test="$isMUE = 'no'">
              <xsl:value-of select="radExamCPT" />
            </xsl:when>
            <!--MUE Edit-->
            <xsl:otherwise>
              <!--First one will not have 2659 appended but all other MUE Edits after the first will have it appended-->
              <xsl:choose>
                <xsl:when test="$i = 1">
                  <xsl:value-of select="radExamCPT" />
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="concat(radExamCPT,'2659')" />
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
                  <xsl:value-of select="$remainderChargeValue" />
                </xsl:when>
                <xsl:otherwise>
                  <xsl:choose>
                    <xsl:when test="$sumNum = 1">1</xsl:when>
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
            <xsl:value-of select="$facilityCode" />
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
            <!--ALWAYS USE THE DEFAULT PERFORMING DOCTOR-->
            <!--<xsl:choose>-->
            <!--<xsl:when test="string-length(radExamPerformingPhyMne) != 0">-->
            <!--<xsl:value-of select="radExamPerformingPhyMne" />-->
            <!--</xsl:when>-->
            <!--<xsl:otherwise>-->
            <xsl:value-of select="$defaultPerfDr" />
            <!--</xsl:otherwise>-->
            <!--</xsl:choose>-->
          </CX.1>
          <CX.2 />
        </FT1.20>
        <FT1.21 />
        <FT1.22 />
        <FT1.23 />
        <FT1.24 />
        <FT1.25>
          <xsl:choose>
            <xsl:when test="$isMUE = 'yes'">
              <!--If it's an MUE Edit then we need to use the CPT code instead of the CDM code-->
              <!--First one will not have 2659 appended but all other MUE Edits after the first will have it appended-->
              <xsl:choose>
                <xsl:when test="$i = 1">
                  <xsl:value-of select="radExamCPT" />
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="concat(radExamCPT,'2659')" />
                </xsl:otherwise>
              </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
              <xsl:choose>
                <xsl:when test="contains('prof.fee', radExamBillingCode)">
                  <xsl:choose>
                    <xsl:when test="string-length(radExamBillingCode) &gt; 0">
                      <xsl:value-of select="upper-case(radExamBillingCode)" />
                    </xsl:when>
                    <xsl:otherwise>BLANK</xsl:otherwise>
                  </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:choose>
                    <xsl:when test="string-length(radExamBillingCode) &gt; 0">
                      <xsl:choose>
                        <!--IF ZERO CDM CODE THEN WE DON'T WANT 0 BUT INSTEAD WE WANT A BLANK STRING-->
                        <xsl:when test="radExamBillingCode = '0' or radExamBillingCode = '00' or radExamBillingCode = '000' or radExamBillingCode = '0000' or radExamBillingCode = '00000' or radExamBillingCode = '000000'">BLANK</xsl:when>
                        <xsl:otherwise>
                          <xsl:value-of select="radExamBillingCode" />
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
</xsl:stylesheet>

