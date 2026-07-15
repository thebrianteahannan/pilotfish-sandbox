<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
	<xsl:template match="@*|node()">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()" />
		</xsl:copy>
	</xsl:template>
	<xsl:template match="/XCSData/Import/Group">
		<xsl:copy>
			<xsl:copy-of select="@*" />
			<xsl:copy-of select="*[local-name() != 'DiagnosisCodes']" />
			<xsl:variable name="DiagnosisCodes" select="DiagnosisCodes/Diag2 | DiagnosisCodes/Diag3 | DiagnosisCodes/Diag4 | DiagnosisCodes/Diag5 | DiagnosisCodes/Diag6 | DiagnosisCodes/Diag7 | DiagnosisCodes/Diag8 | DiagnosisCodes/Diag9 | DiagnosisCodes/Diag10 | DiagnosisCodes/Diag11 | DiagnosisCodes/Diag12" />
			<DiagnosisCodes>
				<xsl:variable name="set0" select="DiagnosisCodes/Diag0" />
				<xsl:variable name="set1" select="DiagnosisCodes/Diag1" />
				<xsl:variable name="set2" select="$DiagnosisCodes[matches(., '[^BVWYZ].*')]" />
				<xsl:variable name="set3" select="$DiagnosisCodes[not(matches(., '[^BVWYZ].*')) and matches(., 'Z[^6][^8].*')]" />
				<xsl:variable name="set4" select="$DiagnosisCodes[not(matches(., '[^BVWYZ].*')) and not(matches(., 'Z[^6][^8].*')) and matches(., 'Z68.*')]" />
				<xsl:variable name="set5" select="$DiagnosisCodes[not(matches(., '[^BVWYZ].*')) and not(matches(., 'Z[^6][^8].*')) and not(matches(., 'Z68.*')) and matches(., '(B|V|W|Y).*')]" />
				<xsl:for-each select="$set0">
					<xsl:sort select="." />
					<Diag1>
						<xsl:value-of select="." />
					</Diag1>
				</xsl:for-each>
				<xsl:for-each select="$set1">
					<xsl:sort select="." />
					<Diag1>
						<xsl:value-of select="." />
					</Diag1>
				</xsl:for-each>
				<xsl:for-each select="$set2">
					<xsl:sort select="." />
					<Diag1>
						<xsl:value-of select="." />
					</Diag1>
				</xsl:for-each>
				<xsl:for-each select="$set3">
					<xsl:sort select="." />
					<Diag1>
						<xsl:value-of select="." />
					</Diag1>
				</xsl:for-each>
				<xsl:for-each select="$set4">
					<xsl:sort select="." />
					<Diag1>
						<xsl:value-of select="." />
					</Diag1>
				</xsl:for-each>
				<xsl:for-each select="$set5">
					<xsl:sort select="." />
					<Diag1>
						<xsl:value-of select="." />
					</Diag1>
				</xsl:for-each>
			</DiagnosisCodes>
		</xsl:copy>
	</xsl:template>
</xsl:stylesheet>

