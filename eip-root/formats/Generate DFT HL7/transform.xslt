<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:datetime="http://exslt.org/dates-and-times" xmlns:mr="mr" exclude-result-prefixes="datetime" version="3.1">
	<xsl:param name="txtFacilityCode" select="'NM'"/>
	<xsl:param name="txtAccountNumAlpha" select="'NM'"/>
	<xsl:param name="txtDefaultPerfDr" select="'NC14'"/>
	<!--Function to pad control ID-->
	<xsl:function name="mr:pad">
		<xsl:param name="value"/>
		<xsl:param name="length"/>
		<xsl:choose>
			<xsl:when test="string-length(string($value)) &lt; number($length)">
				<xsl:value-of select="mr:pad(concat('0', $value), $length)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$value"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	<!--Main template-->
	<xsl:template match="/XCSData">
		<XCSData>
			<xsl:variable name="datetime" select="substring(translate(datetime:dateTime(), '-T:', ''), 1, 12)"/>
			<xsl:for-each select="Import/Group[@stripped = 'false']">
				<xsl:sort select="PatientDemographics/admAcctNum"/>
				<!--ADT_A04-->
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
							<xsl:value-of select="$txtFacilityCode"/>
						</MSH.4>
						<MSH.5>
							<xsl:text>WAL</xsl:text>
						</MSH.5>
						<MSH.6>
							<xsl:text>IRL</xsl:text>
						</MSH.6>
						<MSH.7>
							<xsl:value-of select="$datetime"/>
						</MSH.7>
						<MSH.8/>
						<MSH.9>
							<MSG.1>
								<xsl:text>DPT</xsl:text>
							</MSG.1>
							<MSG.2>
								<xsl:text>P03</xsl:text>
							</MSG.2>
						</MSH.9>
						<MSH.10>
							<xsl:value-of select="concat($datetime, mr:pad(position(), 4))"/>
						</MSH.10>
						<MSH.11>
							<xsl:text>P</xsl:text>
						</MSH.11>
						<MSH.12>
							<xsl:text>2.4</xsl:text>
						</MSH.12>
						<MSH.13/>
						<MSH.14/>
						<MSH.15>
							<xsl:text>AL</xsl:text>
						</MSH.15>
						<MSH.16/>
						<MSH.17/>
						<MSH.18/>
						<MSH.19/>
						<MSH.20/>
					</MSH>
					<!--PID-->
					<PID>
						<PID.1>
							<xsl:text>0001</xsl:text>
						</PID.1>
						<PID.2/>
						<PID.3>
							<CX.1>
								<xsl:value-of select="concat($txtAccountNumAlpha, substring(PatientDemographics/admAcctNum, string-length(PatientDemographics/admAcctNum) - 8))"/>
							</CX.1>
						</PID.3>
						<PID.4>
						</PID.4>
						<PID.5>
							<XPN.1>
								<xsl:value-of select="normalize-space(substring-before(PatientDemographics/admname, ','))"/>
							</XPN.1>
							<XPN.2>
								<xsl:value-of select="normalize-space(substring-after(PatientDemographics/admname, ','))"/>
							</XPN.2>
						</PID.5>
						<PID.6/>
						<PID.7>
							<xsl:value-of select="PatientDemographics/admbirthdate"/>
						</PID.7>
						<PID.8>
							<xsl:value-of select="PatientDemographics/admpatsex"/>
						</PID.8>
						<PID.9/>
						<PID.10/>
						<PID.11>
						</PID.11>
						<PID.12/>
						<PID.13>
						</PID.13>
						<PID.14>
							<xsl:value-of select="PatientDemographics/admemplphone"/>
						</PID.14>
						<PID.15/>
						<PID.16/>
						<PID.17/>
						<PID.18>
							<!--<xsl:value-of select="PatientDemographics/admAcctNum" />-->
						</PID.18>
						<PID.19>
							<xsl:value-of select="PatientDemographics/admssn"/>
						</PID.19>
						<PID.20/>
						<PID.21/>
						<PID.22/>
						<PID.23/>
						<PID.24/>
						<PID.25/>
						<PID.26/>
						<PID.27/>
						<PID.28/>
						<PID.29/>
						<PID.30/>
						<PID.31/>
					</PID>
					<xsl:for-each-group select="Charge" group-by="concat(radExamServDate,radExamPerformingPhyMne,radExamCPT,radExamBillingCode,radAcctNum)">
					<xsl:sort select="radExamBillingCode"/>
						<xsl:variable name="sumNum" select="sum(current-group()/radNumOfTimes)"/>
						<xsl:if test="number($sumNum) &gt; 0">
							<xsl:for-each select="(current-group())[1]">
								<xsl:sort select="radExamBillingCode"/>
								<xsl:variable name="CDM" select="radExamBillingCode"/>
								<xsl:if test="count(/XCSData/query_results/CDMLIST/CDMLIST[lower-case(CDM) = lower-case($CDM)]) = 0">
									<FT1>
										<FT1.1/>
										<FT1.2/>
										<FT1.3/>
										<FT1.4>
											<xsl:value-of select="radExamServDate"/>
										</FT1.4>
										<FT1.5/>
										<FT1.6/>
										<FT1.7>
											<xsl:value-of select="radExamCPT"/>
										</FT1.7>
										<FT1.8/>
										<FT1.9/>
										<FT1.10>
											<xsl:value-of select="$sumNum"/>
										</FT1.10>
										<FT1.11/>
										<FT1.12/>
										<FT1.13/>
										<FT1.14/>
										<FT1.15/>
										<FT1.16>
											<CX.1/>
											<CX.2/>
											<CX.3/>
											<CX.4>
												<xsl:value-of select="$txtFacilityCode"/>
											</CX.4>
											<CX.5/>
											<CX.6>
												<xsl:value-of select="../PatientDemographics/admpatienttype"/>
											</CX.6>
										</FT1.16>
										<FT1.17/>
										<FT1.18/>
										<FT1.19>
										</FT1.19>
										<FT1.20>
											<CX.1>
												<xsl:choose>
													<xsl:when test="string-length(radExamPerformingPhyMne) != 0">
														<xsl:value-of select="radExamPerformingPhyMne"/>
													</xsl:when>
													<xsl:otherwise>
														<xsl:value-of select="$txtDefaultPerfDr"/>
													</xsl:otherwise>
												</xsl:choose>
											</CX.1>
											<CX.2/>
										</FT1.20>
										<FT1.21/>
										<FT1.22/>
										<FT1.23/>
										<FT1.24/>
										<FT1.25>
											<xsl:choose>
												<xsl:when test="contains('prof.fee', radExamBillingCode)">
													<xsl:value-of select="upper-case(radExamBillingCode)"/>
												</xsl:when>
												<xsl:otherwise>
													<xsl:value-of select="radExamBillingCode"/>
												</xsl:otherwise>
											</xsl:choose>
										</FT1.25>
										<FT1.26>
											<xsl:variable name="ins" select="Insurance1/admInsMne"/>
											<xsl:if test="count(/XCSData/query_results/PMA_MOD26_ACCTS/PMA_MOD26_ACCTS[INS_CODES = $ins]) != 0">
												<xsl:text>26</xsl:text>
											</xsl:if>
										</FT1.26>
										<FT1.27/>
									</FT1>
								</xsl:if>
							</xsl:for-each>
						</xsl:if>
					</xsl:for-each-group>
				</ADT_A01>
			</xsl:for-each>
		</XCSData>
	</xsl:template>
</xsl:stylesheet>
