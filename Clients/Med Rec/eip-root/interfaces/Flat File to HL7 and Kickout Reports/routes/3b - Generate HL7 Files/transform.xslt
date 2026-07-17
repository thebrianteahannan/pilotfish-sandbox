<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:datetime="http://exslt.org/dates-and-times" xmlns:mr="mr" exclude-result-prefixes="datetime" version="3.1">
  <xsl:template match="/XCSData">
    <XCSData>
      <!--<xsl:for-each select="Import/Group[@stripped = 'false']">-->
      <!--<xsl:for-each-group group-by="concat(radExamServDate,radExamPerformingPhyMne,radExamCPT,radExamBillingCode,radAcctNum)" select="Charge">-->
      <!--<xsl:variable name="CDM" select="radExamBillingCode" />-->
      <!--<xsl:if test="count(/XCSData/query_results/CDMLIST/CDMLIST[lower-case(CDM) = lower-case($CDM)]) = 0">-->
      <!--<xsl:variable name="AccountNumber" select="../PatientDemographics/admAcctNum" />-->
      <!--<xsl:variable name="NumChargesWithoutNegOneRadTimes" select="count(.[radAcctNum = $AccountNumber and number(radNumOfTimes) &gt; 0])" />-->
      <!--<xsl:if test="$NumChargesWithoutNegOneRadTimes = 0">-->
      <!--<InvalidPatientAccount>-->
      <!--<AccountNumber>-->
      <!--<xsl:value-of select="$AccountNumber" />-->
      <!--</AccountNumber>-->
      <!--<PatientName>-->
      <!--<xsl:value-of select="../PatientDemographics/admname" />-->
      <!--</PatientName>-->
      <!--<NumChargesWithNegOneRadTimes>-->
      <!--<xsl:value-of select="$NumChargesWithoutNegOneRadTimes" />-->
      <!--</NumChargesWithNegOneRadTimes>-->
      <!--</InvalidPatientAccount>-->
      <!--</xsl:if>-->
      <!--</xsl:if>-->
      <!--</xsl:for-each-group>-->
      <!--</xsl:for-each>-->
    </XCSData>
  </xsl:template>
</xsl:stylesheet>

