<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:param name="SoftwareID" />
  <xsl:param name="Partition" />
  <xsl:param name="Client" />
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>
  <!--REMOVE BAD GROUP NUMBER FOR INSURANCE1-->
  <xsl:template match="Insurance1/adminsgroup">
    <xsl:variable name="groupNum">
      <xsl:if test="$Client = 'NFL'">
        <xsl:value-of select="substring(substring(., 2, string-length(.)),1,12)" />
      </xsl:if>
      <xsl:if test="$Client = 'WAL'">
        <xsl:value-of select="substring(.,1,12)" />
      </xsl:if>
    </xsl:variable>
    <xsl:variable name="isBadGroupNum" select="count(//BAD_GROUP_NUMS/GROUPNUM[text() = $groupNum])" />
    <xsl:choose>
      <xsl:when test="$isBadGroupNum = 1">
        <adminsgroup>
          <xsl:attribute name="stripped">true</xsl:attribute>
          <xsl:attribute name="stripped_reason" select="'Stripped Insurance1 Group Number: Bad group number'" />
        </adminsgroup>
      </xsl:when>
      <xsl:otherwise>
        <adminsgroup>
          <xsl:value-of select="$groupNum" />
        </adminsgroup>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <!--REMOVE BAD GROUP NUMBER FOR INSURANCE2-->
  <xsl:template match="Insurance2/adminsgroup">
    <xsl:variable name="groupNum" select="substring(substring(., 2, string-length(.)),1,12)" />
    <xsl:variable name="isBadGroupNum" select="count(//BAD_GROUP_NUMS/GROUPNUM[text() = $groupNum])" />
    <xsl:choose>
      <xsl:when test="$isBadGroupNum = 1">
        <adminsgroup>
          <xsl:attribute name="stripped">true</xsl:attribute>
          <xsl:attribute name="stripped_reason" select="'Stripped Insurance2 Group Number: Bad group number'" />
        </adminsgroup>
      </xsl:when>
      <xsl:otherwise>
        <adminsgroup>
          <xsl:value-of select="$groupNum" />
        </adminsgroup>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <!--Filter flagged, flab, and frlab charges-->
  <xsl:template match="Charge">
    <xsl:variable name="radAcctNum" select="radAcctNum" />
    <xsl:variable name="admLocation" select="../PatientDemographics/admLocation" />
    <xsl:variable name="flaggedCount" select="count(/XCSData/query_results/FLAGGED_ACCOUNT/FLAGGED_ACCOUNT[CODE = $admLocation and SOFTWARE_ID = $SoftwareID])" />
    <xsl:variable name="stripLocationsCount" select="count(/XCSData/query_results/LOCATION/LOCATION[LOC_MNEMONIC = $admLocation and SOFTWARE_ID = $SoftwareID])" />
    <xsl:variable name="flabCount" select="count(/XCSData/query_results/FLAB_ACCOUNTS/FLAB_ACCOUNT[admAcctNum = $radAcctNum])" />
    <xsl:variable name="frlabCount" select="count(/XCSData/query_results/FRLAB_ACCOUNTS/FRLAB_ACCOUNT[admAcctNum = $radAcctNum])" />
    <xsl:choose>
      <xsl:when test="$flaggedCount = 0 and $stripLocationsCount = 0 and $flabCount = 0 and $frlabCount = 0">
        <xsl:copy>
          <xsl:apply-templates select="@*|node()" />
        </xsl:copy>
      </xsl:when>
      <xsl:otherwise>
        <Charge>
          <xsl:attribute name="stripped">true</xsl:attribute>
          <xsl:if test="$flaggedCount != 0 or $stripLocationsCount != 0 or $flabCount != 0 or $frlabCount != 0">
            <xsl:attribute name="stripped_reason" select="'Strip Charge: Strip flagged accounts, flagged locations, F.LAB accounts, F.RLAB accounts'" />
          </xsl:if>
          <xsl:if test="$flaggedCount != 0">
            <xsl:attribute name="stripped_flagged_accounts" select="'true'" />
          </xsl:if>
          <xsl:if test="$stripLocationsCount != 0">
            <xsl:attribute name="stripped_flagged_locations" select="'true'" />
          </xsl:if>
          <xsl:if test="$flabCount != 0">
            <xsl:attribute name="stripped_flab_accounts" select="'true'" />
          </xsl:if>
          <xsl:if test="$frlabCount != 0">
            <xsl:attribute name="stripped_flab_accounts" select="'true'" />
          </xsl:if>
          <xsl:copy-of select="../PatientDemographics" />
          <xsl:copy-of select="." />
        </Charge>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <!--NEW:Filter flagged, flab, and frlab patient demographics and flagged ins2 names-->
  <xsl:template match="PatientDemographics">
    <xsl:variable name="admAcctNum" select="admAcctNum" />
    <xsl:variable name="admLocation" select="admLocation" />
    <xsl:variable name="flaggedCount" select="count(/XCSData/query_results/FLAGGED_ACCOUNT/FLAGGED_ACCOUNT[CODE = $admLocation and SOFTWARE_ID = $SoftwareID])" />
    <xsl:variable name="stripLocationsCount" select="count(/XCSData/query_results/LOCATION/LOCATION[LOC_MNEMONIC = $admLocation and SOFTWARE_ID = $SoftwareID])" />
    <xsl:variable name="flabCount" select="count(/XCSData/query_results/FLAB_ACCOUNTS/FLAB_ACCOUNT[admAcctNum = $admAcctNum])" />
    <xsl:variable name="frlabCount" select="count(/XCSData/query_results/FRLAB_ACCOUNTS/FRLAB_ACCOUNT[admAcctNum = $admAcctNum])" />
    <xsl:variable name="Ins2Name" select="../Insurance2/adminsmne" />
    <xsl:variable name="flaggedIns2NameCount" select="count(/XCSData/query_results/BAD_SECONDARY_INSURANCES[EXTERNAL = $Ins2Name])" />
    <xsl:choose>
      <xsl:when test="$flaggedCount = 0 and $stripLocationsCount = 0 and $flabCount = 0 and $frlabCount = 0 and $flaggedIns2NameCount = 0">
        <xsl:copy>
          <xsl:apply-templates select="@*|node()" />
        </xsl:copy>
      </xsl:when>
      <xsl:otherwise>
        <PatientDemographics>
          <xsl:attribute name="stripped">true</xsl:attribute>
          <xsl:if test="$flaggedCount != 0 or $stripLocationsCount != 0 or $flabCount != 0 or $frlabCount != 0">
            <xsl:attribute name="stripped_reason" select="'Strip Demographics: Strip flagged accounts, flagged locations, F.LAB accounts, F.RLAB accounts'" />
          </xsl:if>
          <xsl:if test="$flaggedIns2NameCount != 0">
            <xsl:attribute name="stripped_reason" select="'Strip Demographics: Strip flagged ins2 name'" />
          </xsl:if>
          <xsl:if test="$flaggedCount != 0">
            <xsl:attribute name="stripped_flagged_accounts" select="'true'" />
          </xsl:if>
          <xsl:if test="$stripLocationsCount != 0">
            <xsl:attribute name="stripped_flagged_locations" select="'true'" />
          </xsl:if>
          <xsl:if test="$flabCount != 0">
            <xsl:attribute name="stripped_flab_accounts" select="'true'" />
          </xsl:if>
          <xsl:if test="$frlabCount != 0">
            <xsl:attribute name="stripped_flab_accounts" select="'true'" />
          </xsl:if>
          <xsl:if test="$flaggedIns2NameCount != 0">
            <xsl:attribute name="stripped_flagged_ins2" select="'true'" />
          </xsl:if>
          <xsl:copy-of select="." />
          <xsl:copy-of select="../Charge" />
        </PatientDemographics>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <!--Filter FLAB and FRLAB PATIENT DEMOGRAPHIC DATA-->
  <xsl:template match="Group[not(./PatientDemographics/admLocation = 'F.LAB' or ./PatientDemographics/admLocation = 'F.RLAB')]">
    <xsl:copy>
      <xsl:attribute name="stripped">false</xsl:attribute>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>
  <xsl:template match="Group[string-length(./PatientDemographics[admLocation != 'F.RLAB']/admLocation) &gt; 0 and string-length(./PatientDemographics/Filler2) &gt; 0]/PatientDemographics">
    <xsl:variable name="location1" select="admLocation" />
    <xsl:variable name="location2" select="Filler2" />
    <xsl:variable name="count" select="count(/XCSData/query_results/STRIP_LOCATIONS/STRIP_LOCATIONS[(string-length($location1) != 0 and string-length($location2) != 0 and LOCATION = $location1 and LOCATION2 = $location2) and SOFTWARE_ID = $SoftwareID])" />
    <xsl:copy>
      <xsl:choose>
        <xsl:when test="$count &gt; 0">
          <xsl:attribute name="stripped">true</xsl:attribute>
          <xsl:attribute name="stripped_reason" select="'Strip Demographics: Filter primary and secondary locations for patient demographic data'" />
          <xsl:attribute name="stripped_both_accounts" select="'true'" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:attribute name="stripped">false</xsl:attribute>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>
  <!--FILTER FLAB AND FRLAB PATIENT DEMOGRAPHIC DATA BASED ON A SECOND LOCATION-->
  <xsl:template match="Group[./PatientDemographics/admLocation = 'H.EHOP' or ./PatientDemographics/admLocation = 'H.EMPLTH']/PatientDemographics">
    <xsl:variable name="location1" select="admLocation" />
    <xsl:variable name="location2" select="Filler2" />
    <xsl:variable name="count" select="count(/XCSData/query_results/STRIP_LOCATIONS/STRIP_LOCATIONS[($location1 = 'H.EHOP' and string-length($location1) != 0 and string-length($location2) != 0 and LOCATION = $location1 and LOCATION2 = $location2) or ($location1 = 'H.EHOP' and string-length($location1) != 0 and string-length($location2) != 0 and LOCATION = $location1) and SOFTWARE_ID = $SoftwareID])" />
    <xsl:copy>
      <xsl:choose>
        <xsl:when test="$count &gt; 0">
          <xsl:attribute name="stripped">true</xsl:attribute>
          <xsl:attribute name="stripped_reason" select="'Strip Demographics: Filter HEHOP and HEMPLTH patient demographic data based on second location code'" />
          <xsl:attribute name="stripped_both_accounts" select="'true'" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:choose>
            <xsl:when test="($location1 = 'H.EHOP' or $location1 = 'H.EMPLTH') and string-length($location2) != 0">
              <xsl:attribute name="stripped">false</xsl:attribute>
              <xsl:attribute name="add_code_to_table">true</xsl:attribute>
            </xsl:when>
            <xsl:otherwise>
              <xsl:attribute name="stripped">false</xsl:attribute>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>
  <xsl:template match="//Group[count(./PatientDemographics) = 0]">
    <!--Strip if no patient demographics data-->
    <xsl:copy select=".">
      <xsl:attribute name="stripped">true</xsl:attribute>
      <xsl:attribute name="stripped_reason" select="'Strip Group: No patient demographics data.'" />
      <xsl:attribute name="key" select="@key" />
    </xsl:copy>
  </xsl:template>
  <xsl:template match="//Group[sum(./Charge/radNumOfTimes) &lt;= 0]">
    <xsl:variable name="doStrip" select="count(/XCSData/query_results/STRIPPING_RULES/STRIPPING_RULES[PARTITION = $Partition and CLIENT = $Client and RULE_NAME = 'Sum Of Charges Less Than 1'])" />
    <xsl:choose>
      <xsl:when test="$doStrip &gt; 0">
        <xsl:copy select=".">
          <xsl:attribute name="stripped">true</xsl:attribute>
          <xsl:attribute name="stripped_reason" select="'Strip Group: Sum of radNumOfTimes is negative.'" />
          <xsl:attribute name="key" select="@key" />
        </xsl:copy>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy select=".">
          <xsl:attribute name="stripped">false</xsl:attribute>
          <xsl:apply-templates select="@*|node()" />
        </xsl:copy>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template match="//Group[count(./Charge) = 0 or count(./Charge[@stripped = 'true']) = count(./Charge)]">
    <xsl:choose>
      <xsl:when test="$SoftwareID != '700' and $SoftwareID != '701' and $SoftwareID != '650'">
        <xsl:value-of select="$SoftwareID" />
        <!--Strip if no charge data-->
        <xsl:copy select=".">
          <xsl:attribute name="stripped">true</xsl:attribute>
          <xsl:attribute name="stripped_reason" select="'Strip Group: No charge data.'" />
          <xsl:attribute name="key" select="@key" />
          <xsl:attribute name="software_id" select="$SoftwareID" />
        </xsl:copy>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy>
          <xsl:attribute name="no-charges-warning">true</xsl:attribute>
          <xsl:copy-of select="@*|node()" />
        </xsl:copy>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <!--Filter any group that doesn't have a key associated with it or that has a blank admAcctNum-->
  <xsl:template match="Group[string-length(./@key) = 0 or string-length(./PatientDemographics/admAcctNum) = 0]">
    <!--<xsl:copy select=".">-->
    <!--<xsl:attribute name="stripped">true</xsl:attribute>-->
    <!--<xsl:attribute name="stripped_reason" select="'Strip Group: No admAcctNum value.'" />-->
    <!--</xsl:copy>-->
  </xsl:template>
</xsl:stylesheet>

