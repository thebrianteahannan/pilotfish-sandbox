<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:pf="http://pilotfishtechnology.com" version="3.1">
  <xsl:param name="Partition" />
  <xsl:param name="Client" />
  <xsl:param name="SoftwareID" />
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>
  <!--Find guarantors without an admGuarName value-->
  <xsl:template match="Guarantor[string-length(admGuarName) = 0]">
    <Guarantor>
      <!--Copy existing elements-->
      <xsl:attribute name="tweaked">true</xsl:attribute>
      <xsl:attribute name="tweaked_reason" select="'Tweak Guarantor: Update guarantor name and address with patient name if guarantor name not present.'" />
      <!--<xsl:copy-of select="*[local-name() != ('admGuarName', 'admGuarAddr1', 'admGuarAddr2', 'admGuarCity', 'admGuarState', 'admGuarZip', 'admGuarHomePhone', 'admGuarRel')]" />-->
      <!--Find matching patient-->
      <xsl:variable name="admAcctNum" select="admAcctNum" />
      <xsl:variable name="patient" select="../PatientDemographics" />
      <!--Copy values from patient-->
      <admGuarName>
        <xsl:value-of select="$patient/admname" />
      </admGuarName>
      <admGuarAddr1>
        <xsl:value-of select="$patient/admstreet" />
      </admGuarAddr1>
      <admGuarAddr2>
        <xsl:value-of select="$patient/admstreet2" />
      </admGuarAddr2>
      <admGuarCity>
        <xsl:value-of select="$patient/admpatcity" />
      </admGuarCity>
      <admGuarState>
        <xsl:value-of select="$patient/admpatstate" />
      </admGuarState>
      <admGuarZip>
        <xsl:value-of select="$patient/admzipcode" />
      </admGuarZip>
      <admGuarHomePhone>
        <xsl:value-of select="$patient/admpatphone" />
      </admGuarHomePhone>
      <admGuarRel>
        <xsl:text>SA</xsl:text>
      </admGuarRel>
    </Guarantor>
  </xsl:template>
  <!--Tweak CDMs to change to CPTs instead for MUE Edits-->
  <xsl:template match="Charge/radExamBillingCode">
    <xsl:variable name="CDM" select="." />
    <xsl:variable name="CPT" select="../radExamCPT" />
    <xsl:variable name="isMUE" select="count(//MUE_EDITS[CDM = $CDM and SOFTWARE_ID = $SoftwareID])" />
    <radExamBillingCode>
      <xsl:choose>
        <xsl:when test="$isMUE &gt; 0">
          <xsl:value-of select="$CPT" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$CDM" />
        </xsl:otherwise>
      </xsl:choose>
    </radExamBillingCode>
    <!--NEED TO SAVE THIS FOR LATER SO WE CAN USE IT FOR LOOKUPS LATER-->
    <radExamBillingCodeOrig>
      <xsl:value-of select="$CDM" />
    </radExamBillingCodeOrig>
  </xsl:template>
  <!--Tweak charge radNumOfTimes to invert value to -1 if radCRDBIndicator is set to 1-->
  <xsl:template match="Charge[radCRDBIndicator = '1']">
    <xsl:variable name="doTweak" select="count(/XCSData/query_results/TWEAKING_RULES/TWEAKING_RULES[PARTITION = $Partition and CLIENT = $Client and RULE_NAME = 'Update RadNumTimes If RadCRDBIndicator'])" />
    <xsl:choose>
      <xsl:when test="$doTweak &gt; 0">
        <Charge>
          <xsl:attribute name="tweaked">true</xsl:attribute>
          <xsl:attribute name="tweaked_reason" select="'Tweaked Charge: radNumOfTimes inverted to -1 because radCRDBIndicator is set to 1.'" />
          <xsl:apply-templates select="*[name(  ) != 'radNumOfTimes']" />
          <radNumOfTimes>
            <xsl:variable name="radNumTimes" select="radNumOfTimes" />
            <xsl:value-of select="$radNumTimes * -1" />
          </radNumOfTimes>
        </Charge>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy select=".">
          <xsl:apply-templates select="@*|node()" />
        </xsl:copy>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <!--RANK FOR SORTING USING BVWYZ METHOD AND ADD ABSADMITDIAG TO LIST OF DIAGS-->
  <xsl:template match="DiagnosisCodes[not(@ranked = 'true')]">
    <DiagnosisCodes>
      <xsl:attribute name="ranked">true</xsl:attribute>
      <xsl:if test="string-length(../PatientDemographics/absadmitdiag) != 0">
        <xsl:attribute name="tweaked">true</xsl:attribute>
        <xsl:attribute name="tweaked_reason" select="'Tweaked Diagnosis Codes: Added absadmitdiag as another diagnosis code from patient demographics.'" />
      </xsl:if>
      <xsl:variable name="set0" select="../PatientDemographics/absadmitdiag" />
      <xsl:variable name="set1" select="./Diag1" />
      <xsl:variable name="set2" select="./Diag2" />
      <xsl:variable name="set3" select="./Diag3" />
      <xsl:variable name="set4" select="./Diag4" />
      <xsl:variable name="set5" select="./Diag5" />
      <xsl:variable name="set6" select="./Diag6" />
      <xsl:variable name="set7" select="./Diag7" />
      <xsl:variable name="set8" select="./Diag8" />
      <xsl:variable name="set9" select="./Diag9" />
      <xsl:variable name="set10" select="./Diag10" />
      <xsl:variable name="set11" select="./Diag11" />
      <xsl:variable name="set12" select="./Diag12" />
      <xsl:for-each select="$set0">
        <xsl:sort select="." />
        <Diag>
          <xsl:attribute name="sort_rank" select="pf:getSortRank(.)" />
          <xsl:value-of select="." />
        </Diag>
        <RecordType>DX</RecordType>
        <radAcctNum>
          <xsl:value-of select="00730248502" />
        </radAcctNum>
      </xsl:for-each>
      <xsl:for-each select="$set1">
        <xsl:sort select="." />
        <Diag>
          <xsl:attribute name="sort_rank" select="pf:getSortRank(.)" />
          <xsl:value-of select="." />
        </Diag>
      </xsl:for-each>
      <xsl:for-each select="$set2">
        <xsl:sort select="." />
        <Diag>
          <xsl:attribute name="sort_rank" select="pf:getSortRank(.)" />
          <xsl:value-of select="." />
        </Diag>
      </xsl:for-each>
      <xsl:for-each select="$set3">
        <xsl:sort select="." />
        <Diag>
          <xsl:attribute name="sort_rank" select="pf:getSortRank(.)" />
          <xsl:value-of select="." />
        </Diag>
      </xsl:for-each>
      <xsl:for-each select="$set4">
        <xsl:sort select="." />
        <Diag>
          <xsl:attribute name="sort_rank" select="pf:getSortRank(.)" />
          <xsl:value-of select="." />
        </Diag>
      </xsl:for-each>
      <xsl:for-each select="$set5">
        <xsl:sort select="." />
        <Diag>
          <xsl:attribute name="sort_rank" select="pf:getSortRank(.)" />
          <xsl:value-of select="." />
        </Diag>
      </xsl:for-each>
      <xsl:for-each select="$set6">
        <xsl:sort select="." />
        <Diag>
          <xsl:attribute name="sort_rank" select="pf:getSortRank(.)" />
          <xsl:value-of select="." />
        </Diag>
      </xsl:for-each>
      <xsl:for-each select="$set7">
        <xsl:sort select="." />
        <Diag>
          <xsl:attribute name="sort_rank" select="pf:getSortRank(.)" />
          <xsl:value-of select="." />
        </Diag>
      </xsl:for-each>
      <xsl:for-each select="$set8">
        <xsl:sort select="." />
        <Diag>
          <xsl:attribute name="sort_rank" select="pf:getSortRank(.)" />
          <xsl:value-of select="." />
        </Diag>
      </xsl:for-each>
      <xsl:for-each select="$set9">
        <xsl:sort select="." />
        <Diag>
          <xsl:attribute name="sort_rank" select="pf:getSortRank(.)" />
          <xsl:value-of select="." />
        </Diag>
      </xsl:for-each>
      <xsl:for-each select="$set10">
        <xsl:sort select="." />
        <Diag>
          <xsl:attribute name="sort_rank" select="pf:getSortRank(.)" />
          <xsl:value-of select="." />
        </Diag>
      </xsl:for-each>
      <xsl:for-each select="$set11">
        <xsl:sort select="." />
        <Diag>
          <xsl:attribute name="sort_rank" select="pf:getSortRank(.)" />
          <xsl:value-of select="." />
        </Diag>
      </xsl:for-each>
      <xsl:for-each select="$set12">
        <xsl:sort select="." />
        <Diag>
          <xsl:attribute name="sort_rank" select="pf:getSortRank(.)" />
          <xsl:value-of select="." />
        </Diag>
      </xsl:for-each>
    </DiagnosisCodes>
  </xsl:template>
  <!--REPLACE E WITH E22 IF THE INSURANCE PLAN EXISTS IN A TABLE IN THE DATABASE-->
  <xsl:template match="PatientDemographics[admpatienttype = 'E']">
    <PatientDemographics>
      <xsl:variable name="ins1" select="../Insurance1/adminsmne" />
      <xsl:variable name="isE22" select="count(//MEDICAID2223_CODES/INS_PLANS[text() = $ins1])" />
      <xsl:variable name="patientType" select="./admpatienttype" />
      <xsl:choose>
        <xsl:when test="$isE22 &gt; 0">
          <xsl:attribute name="tweaked">true</xsl:attribute>
          <xsl:attribute name="tweaked_reason" select="'Tweaked Patient Demographics: For insurance planchange E to E22 because Insurance1 matches a Medicaid2223 code in the database.'" />
          <admpatienttype>E22</admpatienttype>
        </xsl:when>
        <xsl:otherwise>
          <admpatienttype>
            <xsl:value-of select="$patientType" />
          </admpatienttype>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*[local-name() != 'admpatienttype']" />
    </PatientDemographics>
  </xsl:template>
  <!--ADD S TO BEGINNING OF SPECIFIC SECONDARY INSURANCE COMPANY NUMBERS / CODES-->
  <xsl:template match="Insurance2/adminsmne">
    <xsl:variable name="companyCode" select="." />
    <xsl:variable name="isSpecificCompanyCode" select="count(//SECONDARY_INSURANCE_COMPANY_CODES/COMPANY_CODE[text() = $companyCode])" />
    <xsl:choose>
      <xsl:when test="$isSpecificCompanyCode = 1">
        <adminsmne>
          <xsl:attribute name="tweaked">true</xsl:attribute>
          <xsl:attribute name="tweaked_reason" select="'Tweaked Insurance2 Company Code/Number: Added S in front of plan name for specific secondary plan'" />
          <xsl:value-of select="concat('S',$companyCode)" />
        </adminsmne>
      </xsl:when>
      <xsl:otherwise>
        <adminsmne>
          <xsl:value-of select="$companyCode" />
        </adminsmne>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <!--HELPER FUNCTIONS-->
  <xsl:function name="pf:getSortRank">
    <xsl:param name="code" />
    <xsl:variable name="startsWith" select="substring($code,1,1)" />
    <xsl:variable name="firstThree" select="substring($code,1,3)" />
    <!--<xsl:choose>-->
    <!--<xsl:when test="$Partition = 'MID'">-->
    <!--START PATHOLOGY DECISION MAKING-->
    <xsl:choose>
      <xsl:when test="$firstThree = ('A41','A87','B20','C00','C01','C02','C03','C04','C05','C06','C07','C08','C09','C10','C11','C12','C13','C14')">
        <xsl:value-of select="1" />
      </xsl:when>
      <xsl:when test="$firstThree = ('C15','C16','C17','C18','C19','C20','C21','C22','C23','C24','C25','C26','C30','C31','C32','C33','C34','C35','C36','C37','C38','C39','C40','C41','C42','C43','C44','C45','C46','C47','C48','C49','C50','C51','C52','C53','C54','C55','C56','C58','C60','C61','C62','C63','C64','C65','C66','C68','C69','C70','C71','C72','C73','C74','C75','C76','C77','C78','C79','C80','C81','C82','C83','C84','C85','C86','C87','C88','C89','C90','C91','C92','C93','C94','C95','C96','D00','D01','D02','D03','D04','D05','D06','D07','D08','D09','D10','D11','D12','D13','D14','D15','D16','D17','D18','D19','D20','D21','D22','D23','D24','D25','D26','D27','D28','D29','D30','D31','D32','D33','D34','D35','D36','D37','D38','D39','D40','D41','D42','D43','D44','D45','D46','D47','D48')">
        <xsl:value-of select="2" />
      </xsl:when>
      <xsl:when test="$firstThree = ('D49','D50','D51','D52','D53','D54','D55','D56','D57','D58','D59','D60','D61','D62','D63','D64','D65','D66','D67','D68','D69','D70','D71','D72','D73','D74','D75','D76','D77','D78','D79','D80','D81','D82','D83','D84','D85','D86','D87','D88','D89')">
        <xsl:value-of select="3" />
      </xsl:when>
      <xsl:when test="$firstThree = ('I26','I27','I28','I30','I31','I32','I33','I34','I35','I36','I37','I38','I39','I40','I41','I42','I43','I44','I45','I46','I47','I48','I49','I50','I51','I52')">
        <xsl:value-of select="4" />
      </xsl:when>
      <xsl:when test="$firstThree = ('J12','J13','J14','J15','J16','J80','J81','J82','J83','J84')">
        <xsl:value-of select="5" />
      </xsl:when>
      <xsl:when test="$firstThree = ('K20','K21','K22','K23','K24','K25','K26','K27','K28','K29','K30','K31','K35','K36','K37','K38','K40','K41','K42','K43','K44','K45','K46','K50','K51','K55','K56','K57','K58','K59','K60','K61','K62','K63','K64','K65','K66','K67','K68','K80','K81','K82','K83','K84','K85','K86','K87')">
        <xsl:value-of select="6" />
      </xsl:when>
      <xsl:when test="$firstThree = ('L02','L05','L80','L81','L82','L83','L84','L85','L86','L87','L88','L89','L90','L90','L91','L92','L93','L94','L95','L96','L97','L98','L99','M16','M17','M18','M19','M60','M86','M87')">
        <xsl:value-of select="7" />
      </xsl:when>
      <xsl:when test="$firstThree = ('N20','N21','N22','N40','N41','N42','N43','N44','N45','N46','N47','N48','N49','N50','N51','N52','N53','N60','N61','N62','N63','N64','N65','N70','N71','N72','N73','N74','N75','N76','N77','N81','N82','N83','N84','N85','N86','N87','O00','O01','O02','O03')">
        <xsl:value-of select="8" />
      </xsl:when>
      <xsl:when test="$firstThree = ('R03','R04','R05','R06','R10','R11','R12','R18','R19','R20','R21','R22','R23','R30','R31','R32','R33','R34','R35','R36','R37','R38','R39','R50','R51','R52','R53','R59','R60','R87','R92','R97','S72')">
        <xsl:value-of select="9" />
      </xsl:when>
      <xsl:when test="$firstThree = ('T86')">
        <xsl:value-of select="10" />
      </xsl:when>
      <!--END PATHOLOGY DECISION MAKING-->
      <!--CONTINUE WITH ORIG DIAG ORDERING-->
      <xsl:when test="not($startsWith = ('B','V','W','Y','Z'))">
        <xsl:value-of select="11" />
      </xsl:when>
      <xsl:when test="$startsWith = 'Z' and not($firstThree = 'Z68')">
        <xsl:value-of select="12" />
      </xsl:when>
      <xsl:when test="$firstThree = 'Z68'">
        <xsl:value-of select="13" />
      </xsl:when>
      <xsl:when test="$startsWith = ('B','V','W','Y')">
        <xsl:value-of select="14" />
      </xsl:when>
      <!--END ORIG DIAG ORDERING-->
    </xsl:choose>
    <!--</xsl:when>-->
    <!--<xsl:otherwise>-->
    <!--ALL OTHER PARTITIONS FOLLOW THE ORIG DIAG ORDERING UNTIL WE TEST THEN ALL WILL USE ABOVE ORDERING-->
    <!--<xsl:if test="not($startsWith = ('B','V','W','Y','Z'))">-->
    <!--<xsl:value-of select="1" />-->
    <!--</xsl:if>-->
    <!--<xsl:if test="$startsWith = 'Z' and not($firstThree = 'Z68')">-->
    <!--<xsl:value-of select="2" />-->
    <!--</xsl:if>-->
    <!--<xsl:if test="$firstThree = 'Z68'">-->
    <!--<xsl:value-of select="3" />-->
    <!--</xsl:if>-->
    <!--<xsl:if test="$startsWith = ('B','V','W','Y')">-->
    <!--<xsl:value-of select="4" />-->
    <!--</xsl:if>-->
    <!--</xsl:otherwise>-->
    <!--</xsl:choose>-->
  </xsl:function>
</xsl:stylesheet>

