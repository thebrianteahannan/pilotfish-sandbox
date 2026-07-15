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
				<!-- <xsl:variable name="set2" select="DiagnosisCodes/Diag2[matches(., '[^BVWYZ].*')] | DiagnosisCodes/Diag2[not(matches(., '[^BVWYZ].*')) and matches(., 'Z[^6][^8].*')] | DiagnosisCodes/Diag2[not(matches(., '[^BVWYZ].*')) and not(matches(., 'Z[^6][^8].*')) and matches(., 'Z68.*')] | DiagnosisCodes/Diag2[not(matches(., '[^BVWYZ].*')) and not(matches(., 'Z[^6][^8].*')) and not(matches(., 'Z68.*')) and matches(., '(B|V|W|Y).*')]" /> -->
				<!-- <xsl:variable name="set3" select="DiagnosisCodes/Diag3[matches(., '[^BVWYZ].*')] | DiagnosisCodes/Diag3[not(matches(., '[^BVWYZ].*')) and matches(., 'Z[^6][^8].*')] | DiagnosisCodes/Diag3[not(matches(., '[^BVWYZ].*')) and not(matches(., 'Z[^6][^8].*')) and matches(., 'Z68.*')] | DiagnosisCodes/Diag3[not(matches(., '[^BVWYZ].*')) and not(matches(., 'Z[^6][^8].*')) and not(matches(., 'Z68.*')) and matches(., '(B|V|W|Y).*')]" /> -->
				<!-- <xsl:variable name="set4" select="DiagnosisCodes/Diag4[matches(., '[^BVWYZ].*')] | DiagnosisCodes/Diag4[not(matches(., '[^BVWYZ].*')) and matches(., 'Z[^6][^8].*')] | DiagnosisCodes/Diag4[not(matches(., '[^BVWYZ].*')) and not(matches(., 'Z[^6][^8].*')) and matches(., 'Z68.*')] | DiagnosisCodes/Diag4[not(matches(., '[^BVWYZ].*')) and not(matches(., 'Z[^6][^8].*')) and not(matches(., 'Z68.*')) and matches(., '(B|V|W|Y).*')]" /> -->
				<!-- <xsl:variable name="set5" select="DiagnosisCodes/Diag5[matches(., '[^BVWYZ].*')] | DiagnosisCodes/Diag5[not(matches(., '[^BVWYZ].*')) and matches(., 'Z[^6][^8].*')] | DiagnosisCodes/Diag5[not(matches(., '[^BVWYZ].*')) and not(matches(., 'Z[^6][^8].*')) and matches(., 'Z68.*')] | DiagnosisCodes/Diag5[not(matches(., '[^BVWYZ].*')) and not(matches(., 'Z[^6][^8].*')) and not(matches(., 'Z68.*')) and matches(., '(B|V|W|Y).*')]" /> -->
				<!-- <xsl:variable name="set6" select="DiagnosisCodes/Diag6[matches(., '[^BVWYZ].*')] | DiagnosisCodes/Diag6[not(matches(., '[^BVWYZ].*')) and matches(., 'Z[^6][^8].*')] | DiagnosisCodes/Diag6[not(matches(., '[^BVWYZ].*')) and not(matches(., 'Z[^6][^8].*')) and matches(., 'Z68.*')] | DiagnosisCodes/Diag6[not(matches(., '[^BVWYZ].*')) and not(matches(., 'Z[^6][^8].*')) and not(matches(., 'Z68.*')) and matches(., '(B|V|W|Y).*')]" /> -->
				<!-- <xsl:variable name="set7" select="DiagnosisCodes/Diag7[matches(., '[^BVWYZ].*')] | DiagnosisCodes/Diag7[not(matches(., '[^BVWYZ].*')) and matches(., 'Z[^6][^8].*')] | DiagnosisCodes/Diag7[not(matches(., '[^BVWYZ].*')) and not(matches(., 'Z[^6][^8].*')) and matches(., 'Z68.*')] | DiagnosisCodes/Diag7[not(matches(., '[^BVWYZ].*')) and not(matches(., 'Z[^6][^8].*')) and not(matches(., 'Z68.*')) and matches(., '(B|V|W|Y).*')]" /> -->
				<!-- <xsl:variable name="set8" select="DiagnosisCodes/Diag8[matches(., '[^BVWYZ].*')] | DiagnosisCodes/Diag8[not(matches(., '[^BVWYZ].*')) and matches(., 'Z[^6][^8].*')] | DiagnosisCodes/Diag8[not(matches(., '[^BVWYZ].*')) and not(matches(., 'Z[^6][^8].*')) and matches(., 'Z68.*')] | DiagnosisCodes/Diag8[not(matches(., '[^BVWYZ].*')) and not(matches(., 'Z[^6][^8].*')) and not(matches(., 'Z68.*')) and matches(., '(B|V|W|Y).*')]" /> -->
				<!-- <xsl:variable name="set9" select="DiagnosisCodes/Diag9[matches(., '[^BVWYZ].*')] | DiagnosisCodes/Diag9[not(matches(., '[^BVWYZ].*')) and matches(., 'Z[^6][^8].*')] | DiagnosisCodes/Diag9[not(matches(., '[^BVWYZ].*')) and not(matches(., 'Z[^6][^8].*')) and matches(., 'Z68.*')] | DiagnosisCodes/Diag9[not(matches(., '[^BVWYZ].*')) and not(matches(., 'Z[^6][^8].*')) and not(matches(., 'Z68.*')) and matches(., '(B|V|W|Y).*')]" /> -->
				<!-- <xsl:variable name="set10" select="DiagnosisCodes/Diag10[matches(., '[^BVWYZ].*')] | DiagnosisCodes/Diag10[not(matches(., '[^BVWYZ].*')) and matches(., 'Z[^6][^8].*')] | DiagnosisCodes/Diag10[not(matches(., '[^BVWYZ].*')) and not(matches(., 'Z[^6][^8].*')) and matches(., 'Z68.*')] | DiagnosisCodes/Diag10[not(matches(., '[^BVWYZ].*')) and not(matches(., 'Z[^6][^8].*')) and not(matches(., 'Z68.*')) and matches(., '(B|V|W|Y).*')]" /> -->
				<!-- <xsl:variable name="set11" select="DiagnosisCodes/Diag11[matches(., '[^BVWYZ].*')] | DiagnosisCodes/Diag11[not(matches(., '[^BVWYZ].*')) and matches(., 'Z[^6][^8].*')] | DiagnosisCodes/Diag11[not(matches(., '[^BVWYZ].*')) and not(matches(., 'Z[^6][^8].*')) and matches(., 'Z68.*')] | DiagnosisCodes/Diag11[not(matches(., '[^BVWYZ].*')) and not(matches(., 'Z[^6][^8].*')) and not(matches(., 'Z68.*')) and matches(., '(B|V|W|Y).*')]" /> -->
				<!-- <xsl:variable name="set12" select="DiagnosisCodes/Diag12[matches(., '[^BVWYZ].*')] | DiagnosisCodes/Diag12[not(matches(., '[^BVWYZ].*')) and matches(., 'Z[^6][^8].*')] | DiagnosisCodes/Diag12[not(matches(., '[^BVWYZ].*')) and not(matches(., 'Z[^6][^8].*')) and matches(., 'Z68.*')] | DiagnosisCodes/Diag12[not(matches(., '[^BVWYZ].*')) and not(matches(., 'Z[^6][^8].*')) and not(matches(., 'Z68.*')) and matches(., '(B|V|W|Y).*')]" /> -->
				<xsl:variable name="set2" select="DiagnosisCodes/Diag2" />
				<xsl:variable name="set3" select="DiagnosisCodes/Diag3" />
				<xsl:variable name="set4" select="DiagnosisCodes/Diag4" />
				<xsl:variable name="set5" select="DiagnosisCodes/Diag5" />
				<xsl:variable name="set6" select="DiagnosisCodes/Diag6" />
				<xsl:variable name="set7" select="DiagnosisCodes/Diag7" />
				<xsl:variable name="set8" select="DiagnosisCodes/Diag8" />
				<xsl:variable name="set9" select="DiagnosisCodes/Diag9" />
				<xsl:variable name="set10" select="DiagnosisCodes/Diag10" />
				<xsl:variable name="set11" select="DiagnosisCodes/Diag11" />
				<xsl:variable name="set12" select="DiagnosisCodes/Diag12" />
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
					<Diag2>
						<xsl:value-of select="." />
					</Diag2>
				</xsl:for-each>
				<xsl:for-each select="$set3">
					<xsl:sort select="." />
					<Diag3>
						<xsl:value-of select="." />
					</Diag3>
				</xsl:for-each>
				<xsl:for-each select="$set4">
					<xsl:sort select="." />
					<Diag4>
						<xsl:value-of select="." />
					</Diag4>
				</xsl:for-each>
				<xsl:for-each select="$set5">
					<xsl:sort select="." />
					<Diag5>
						<xsl:value-of select="." />
					</Diag5>
				</xsl:for-each>
				<xsl:for-each select="$set6">
					<xsl:sort select="." />
					<Diag6>
						<xsl:value-of select="." />
					</Diag6>
				</xsl:for-each>
				<xsl:for-each select="$set7">
					<xsl:sort select="." />
					<Diag7>
						<xsl:value-of select="." />
					</Diag7>
				</xsl:for-each>
				<xsl:for-each select="$set8">
					<xsl:sort select="." />
					<Diag8>
						<xsl:value-of select="." />
					</Diag8>
				</xsl:for-each>
				<xsl:for-each select="$set9">
					<xsl:sort select="." />
					<Diag9>
						<xsl:value-of select="." />
					</Diag9>
				</xsl:for-each>
				<xsl:for-each select="$set10">
					<xsl:sort select="." />
					<Diag10>
						<xsl:value-of select="." />
					</Diag10>
				</xsl:for-each>
				<xsl:for-each select="$set11">
					<xsl:sort select="." />
					<Diag11>
						<xsl:value-of select="." />
					</Diag11>
				</xsl:for-each>
				<xsl:for-each select="$set12">
					<xsl:sort select="." />
					<Diag12>
						<xsl:value-of select="." />
					</Diag12>
				</xsl:for-each>
			</DiagnosisCodes>
		</xsl:copy>
	</xsl:template>
</xsl:stylesheet>

