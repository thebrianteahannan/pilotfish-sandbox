<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:query="xalan://com.pilotfish.custom.DBCachedQuery" exclude-result-prefixes="query" version="3.1">
	<xsl:param name="eiPlatformTransactionData"/>
	<xsl:param name="db_username"/>
	<xsl:param name="db_password"/>
	<xsl:param name="db_driver"/>
	<xsl:param name="db_url"/>
	<xsl:variable name="query" select="query:new('sa', '', 'org.h2.Driver', 'jdbc:h2:~/medreceivables')" />
	<xsl:template match="@*|node()">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()"/>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="Group">
		<Group>
			<xsl:copy-of select="@*" />
			<xsl:variable name="diagnosisCodeRoot" select="DiagnosisCodes"/>
			<xsl:copy-of select="PatientDemographics"/>
			<xsl:copy-of select="Insurance1"/>
			<xsl:copy-of select="Insurance2"/>
			<xsl:copy-of select="Insurance3"/>
			<xsl:copy-of select="Guarantor"/>
			<xsl:copy-of select="$diagnosisCodeRoot"/>
			<xsl:for-each select="Charge">
				<xsl:variable name="diagnosisCodeSet" select="$diagnosisCodeRoot"/>
				<xsl:variable name="charge" select="."/>
				<xsl:copy>
					<xsl:copy-of select="*"/>
					<Field19>
						<xsl:variable name="diagnosisCodes" select="$diagnosisCodeSet/Diag1 | $diagnosisCodeSet/Diag2 | $diagnosisCodeSet/Diag3 | $diagnosisCodeSet/Diag4 | $diagnosisCodeSet/Diag5 | $diagnosisCodeSet/Diag6 | $diagnosisCodeSet/Diag7 | $diagnosisCodeSet/Diag8 | $diagnosisCodeSet/Diag9 | $diagnosisCodeSet/Diag10 | $diagnosisCodeSet/Diag11 | $diagnosisCodeSet/Diag12"/>
						<xsl:variable name="matches">
							<xsl:for-each select="$diagnosisCodes[string-length(.) != 0]">

								<xsl:variable name="diag" select="."/>
								<!--<xsl:variable name="results" select="db:executeQuery($dbLookup, 'SELECT * FROM WEBSITEMEDICARECPTTABLE WHERE CPTCODE = ? AND (? = FROMRANGE OR ? = TORANGE)', [$charge/radExamCPT, $diag, $diag])" />-->
								<xsl:if test="string(query:queryCacheExists($query, 'icd9', [$charge/radExamCPT, $diag, $diag])) = 'true'">
								<xsl:text>,</xsl:text>
									<xsl:value-of select="$diag"/>
								</xsl:if>
							</xsl:for-each>
						</xsl:variable>
						<xsl:value-of select="(tokenize($matches, ',')[string-length(.) != 0])[1]"/>
					</Field19>
				</xsl:copy>
			</xsl:for-each>
		</Group>
	</xsl:template>
	<!--<xsl:template name="context_lookup_f_3">
		<xsl:param name="domain"/>
		<xsl:param name="failOnNull"/>
		<xsl:param name="defaultValue"/>
		<xsl:param name="key1"/>
		<xsl:param name="key2"/>
		<xsl:param name="key3"/>
		<xsl:variable name="lookupInstance" select="java:new($eiPlatformTransactionData, $domain, $failOnNull, $defaultValue)"/>
		<xsl:variable name="lookupKey1" select="java:addKey($lookupInstance, $key1)"/>
		<xsl:variable name="lookupKey2" select="java:addKey($lookupInstance, $key2)"/>
		<xsl:variable name="lookupKey3" select="java:addKey($lookupInstance, $key3)"/>
		<xsl:variable name="lookupResult" select="java:lookup($lookupInstance)"/>
		<xsl:choose>
			<xsl:when test="(string-length($lookupResult) = 0) or (string($lookupResult) = 'null')">
				<xsl:if test="$failOnNull">
					<xsl:message>
						<xsl:value-of select="concat('No value found in domain ', $domain, ' for given key(s) ', $key1, ', ', $key2, ', ', $key3)"/>
					</xsl:message>
				</xsl:if>
				<xsl:value-of select="$defaultValue"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$lookupResult"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>-->
</xsl:stylesheet>
