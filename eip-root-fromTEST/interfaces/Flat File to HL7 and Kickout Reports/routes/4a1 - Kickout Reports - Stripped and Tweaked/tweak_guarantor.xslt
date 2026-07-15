<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
	<xsl:template match="@*|node()">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()"/>
		</xsl:copy>
	</xsl:template>
	<!--Add absadmitdiag if present-->
	<xsl:template match="PatientDemographics[string-length(absadmitdiag) &gt; 0]">
		<xsl:copy-of select="."/>
		<DiagnosisCodes>
			<RecordType>DX</RecordType>
			<radAcctNum>
				<xsl:value-of select="00730248502"/>
			</radAcctNum>
			<Diag0>
				<xsl:value-of select="absadmitdiag"/>
			</Diag0>
		</DiagnosisCodes>
	</xsl:template>
		
	<!--Find guarantors without an admGuarName value-->
	<xsl:template match="Guarantor[string-length(admGuarName) = 0]">
		<Guarantor>
			<!--Copy existing elements-->
			<xsl:copy-of select="*[local-name() != ('admGuarName', 'admGuarAddr1', 'admGuarAddr2', 'admGuarCity', 'admGuarState', 'admGuarZip', 'admGuarHomePhone', 'admGuarRel')]"/>
			<!--Find matching patient-->
			<xsl:variable name="admAcctNum" select="admAcctNum"/>
			<xsl:variable name="patient" select="../PatientDemographics"/>
			<!--Copy values from patient-->
			<admGuarName>
				<xsl:value-of select="$patient/admname"/>
			</admGuarName>
			<admGuarAddr1>
				<xsl:value-of select="$patient/admstreet"/>
			</admGuarAddr1>
			<admGuarAddr2>
				<xsl:value-of select="$patient/admstreet2"/>
			</admGuarAddr2>
			<admGuarCity>
				<xsl:value-of select="$patient/admpatcity"/>
			</admGuarCity>
			<admGuarState>
				<xsl:value-of select="$patient/admpatstate"/>
			</admGuarState>
			<admGuarZip>
				<xsl:value-of select="$patient/admzipcode"/>
			</admGuarZip>
			<admGuarHomePhone>
				<xsl:value-of select="$patient/admpatphone"/>
			</admGuarHomePhone>
			<admGuarRel>
				<xsl:text>SA</xsl:text>
			</admGuarRel>
		</Guarantor>
	</xsl:template>
</xsl:stylesheet>
