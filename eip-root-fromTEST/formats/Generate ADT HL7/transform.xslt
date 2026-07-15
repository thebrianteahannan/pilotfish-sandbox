<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
              	xmlns:datetime="http://exslt.org/dates-and-times"
              	xmlns:mr="mr"
              	exclude-result-prefixes="datetime"
              	version="3.1">
	<xsl:param name="txtFacilityCode"
         		select="'NM'"/>
	<xsl:param name="txtAccountNumAlpha"
         		select="'NM'"/>
	<xsl:param name="file_name"
         		select="''"/>
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
			<xsl:variable name="datetime"
            				select="substring(translate(datetime:dateTime(), '-T:', ''), 1, 12)"/>
			<xsl:variable name="dataset"
            				select="Import/Group[string-length((Guarantor/admGuarName)[1]) != 0][@stripped = 'false']"/>
			<xsl:for-each select="$dataset">
				<!--ADT_A04-->
				<ADT_A01>
					<xsl:if test="position() = 1">
						<BHS>
							<BHS.1>
								<xsl:text>|</xsl:text>
							</BHS.1>
							<BHS.2>
								<xsl:text>^~\&amp;</xsl:text>
							</BHS.2>
							<BHS.3>
								<xsl:text>VWE</xsl:text>
							</BHS.3>
							<BHS.4>
							</BHS.4>
							<BHS.5>
								<xsl:text>WAL</xsl:text>
							</BHS.5>
							<BHS.6>
								<xsl:text>IRL</xsl:text>
							</BHS.6>
							<BHS.7>
								<xsl:value-of select="$datetime"/>
							</BHS.7>
							<BHS.8/>
							<BHS.9>
								<MSG.1>
									<xsl:text>ADT</xsl:text>
								</MSG.1>
							</BHS.9>
							<BHS.10/>
							<BHS.11>
								<xsl:value-of select="substring(translate(datetime:dateTime(), '-T:', ''), 1, 14)"/>
							</BHS.11>
							<BHS.12>
								<xsl:value-of select="$file_name"/>
							</BHS.12>
							<BHS.13/>
						</BHS>
					</xsl:if>
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
								<xsl:text>ADT</xsl:text>
							</MSG.1>
							<MSG.2>
								<xsl:text>A04</xsl:text>
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
							<CX.5>
								<xsl:text>PT</xsl:text>
							</CX.5>
						</PID.3>
						<PID.3>
							<CX.1>
								<xsl:value-of select="PatientDemographics/absPatientUnit"/>
							</CX.1>
							<CX.5>
								<xsl:text>MR</xsl:text>
							</CX.5>
						</PID.3>
						<PID.4>
							<xsl:value-of select="PatientDemographics/absAdmitdate"/>
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
							<XAD.1>
								<xsl:value-of select="PatientDemographics/admstreet"/>
								<xsl:if test="string-length(PatientDemographics/admstreet2) != 0">
									<xsl:value-of select="concat(' ', PatientDemographics/admstreet2)"/>
								</xsl:if>
							</XAD.1>
							<XAD.2/>
							<XAD.3>
								<xsl:value-of select="PatientDemographics/admpatcity"/>
							</XAD.3>
							<XAD.4>
								<xsl:value-of select="PatientDemographics/admpatstate"/>
							</XAD.4>
							<XAD.5>
								<xsl:value-of select="PatientDemographics/admzipcode"/>
							</XAD.5>
						</PID.11>
						<PID.12/>
						<PID.13>
							<xsl:value-of select="PatientDemographics/admpatphone"/>
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
					<!--NK1-->
					<NK1>
						<NK1.1>
							<xsl:text>0001</xsl:text>
						</NK1.1>
						<NK1.2/>
						<NK1.3>
							<xsl:text>E</xsl:text>
						</NK1.3>
						<NK1.4>
							<XAD.1>
								<xsl:value-of select="translate(Guarantor/admGuarEmplAddr1, '.', '')"/>
								<xsl:if test="string-length(Guarantor/admGuarEmplAddr2) != 0">
											<xsl:value-of select="concat(' ', Guarantor/admGuarEmplAddr2)"/>
										</xsl:if>
							</XAD.1>
							<XAD.2>
								
							</XAD.2>
							<XAD.3>
								<xsl:value-of select="Guarantor/admGuarEmplCity"/>
							</XAD.3>
							<XAD.4>
								<xsl:value-of select="Guarantor/admGuarEmplState"/>
							</XAD.4>
							<XAD.5>
								<xsl:value-of select="Guarantor/admGuarEmplZip"/>
							</XAD.5>
							<XAD.6/>
						</NK1.4>
						<NK1.5/>
						<NK1.6>
							<xsl:value-of select="Guarantor/admGuarEmplPhone"/>
						</NK1.6>
						<NK1.7/>
						<NK1.8/>
						<NK1.9/>
						<NK1.10/>
						<NK1.11/>
						<NK1.12/>
						<NK1.13>
							<xsl:value-of select="Guarantor/admGuarEmployer"/>
						</NK1.13>
						<NK1.14/>
						<NK1.15/>
						<NK1.16/>
						<NK1.17/>
						<NK1.18/>
						<NK1.19/>
						<NK1.20/>
						<NK1.21/>
						<NK1.22/>
						<NK1.23/>
						<NK1.24/>
						<NK1.25/>
						<NK1.26/>
						<NK1.27/>
						<NK1.28/>
						<NK1.29/>
						<NK1.30/>
						<NK1.31/>
						<NK1.32/>
						<NK1.33/>
						<NK1.34/>
						<NK1.35/>
						<NK1.36/>
						<NK1.37/>
						<NK1.38/>
					</NK1>
					<!--PV1-->
					<PV1>
						<PV1.1/>
						<PV1.2>
							<xsl:variable name="ins"
            								select="Insurance1/adminsmne"/>
							<xsl:choose>
								<xsl:when test="PatientDemographics/admpatienttype = 'E' and count(/XCSData/query_results/MEDICAID2223_CODES/MEDICAID2223_CODES[INS_PLANS = $ins]) != 0">
									<xsl:text>E22</xsl:text>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="PatientDemographics/admpatienttype"/>
								</xsl:otherwise>
							</xsl:choose>
						</PV1.2>
						<PV1.3>
							<PL.1/>
							<PL.2/>
							<PL.3/>
							<PL.4>
								<xsl:value-of select="$txtFacilityCode"/>
							</PL.4>
							<PL.5/>
						</PV1.3>
						<PV1.4/>
						<PV1.5/>
						<PV1.6/>
						<PV1.7/>
						<PV1.8>
							<XCN.1>
								<xsl:value-of select="PatientDemographics/absattendingdocmnem"/>
							</XCN.1>
							<XCN.2>
								<xsl:value-of select="normalize-space(substring-before(PatientDemographics/absattendingdocname, ','))"/>
							</XCN.2>
							<XCN.3>
								<xsl:value-of select="normalize-space(substring-after(PatientDemographics/absattendingdocname, ','))"/>
							</XCN.3>
						</PV1.8>
						<PV1.9/>
						<PV1.10/>
						<PV1.11/>
						<PV1.12/>
						<PV1.13/>
						<PV1.14/>
						<PV1.15/>
						<PV1.16/>
						<PV1.17/>
						<PV1.18/>
						<PV1.19/>
						<PV1.20/>
						<PV1.21/>
						<PV1.22/>
						<PV1.23/>
						<PV1.24/>
						<PV1.25/>
						<PV1.26/>
						<PV1.27/>
						<PV1.28/>
						<PV1.29/>
						<PV1.30/>
						<PV1.31/>
						<PV1.32/>
						<PV1.33/>
						<PV1.34/>
						<PV1.35/>
						<PV1.36/>
						<PV1.37/>
						<PV1.38/>
						<PV1.39/>
						<PV1.40/>
						<PV1.41/>
						<PV1.42/>
						<PV1.43/>
						<PV1.44>
							<!--<xsl:value-of select="format-number(min(PatientDemographics/absAdmitdate[string(number(.)) != 'NaN'] | Charge/radExamServDate[string(number(.)) != 'NaN']), '#')"/>-->
							<xsl:value-of select="PatientDemographics/absAdmitdate"/>
						</PV1.44>
						<PV1.45>
							<xsl:value-of select="PatientDemographics/absdischargedate"/>
						</PV1.45>
						<PV1.46/>
						<PV1.47/>
						<PV1.48/>
						<PV1.49/>
						<PV1.50/>
						<PV1.51/>
						<PV1.52/>
						<PV1.53/>
					</PV1>
					<!--PV2-->
					<PV2>
						<PV2.1/>
						<PV2.2/>
						<PV2.3/>
						<PV2.4/>
						<PV2.5/>
						<PV2.6/>
						<PV2.7/>
						<PV2.8/>
						<PV2.9/>
						<PV2.10/>
						<PV2.11/>
						<PV2.12/>
						<PV2.13/>
						<PV2.14/>
						<PV2.15/>
						<PV2.16/>
						<PV2.17/>
						<PV2.18/>
						<PV2.19/>
						<PV2.20/>
						<PV2.21/>
						<PV2.22/>
						<PV2.23/>
						<PV2.24/>
						<PV2.25/>
						<PV2.26/>
						<PV2.27/>
						<PV2.28>
							<!--<xsl:value-of select="format-number(min(PatientDemographics/absAdmitdate[string(number(.)) != 'NaN'] | Charge/radExamServDate[string(number(.)) != 'NaN']), '#')"/>-->
							<xsl:value-of select="PatientDemographics/absAdmitdate"/>
						</PV2.28>
						<PV2.29/>
						<PV2.30/>
					</PV2>
					<!--PV9-->
					<PV9>
						<PV9.1>A</PV9.1>
						<PV9.2/>
						<PV9.3/>
						<PV9.4/>
						<PV9.5/>
						<PV9.6/>
						<PV9.7/>
						<PV9.8/>
						<PV9.9/>
						<PV9.10/>
						<PV9.11/>
						<PV9.12/>
						<PV9.13/>
						<PV9.14/>
						<PV9.15/>
						<PV9.16/>
						<PV9.17/>
						<PV9.18/>
						<PV9.19/>
						<PV9.20/>
						<PV9.21/>
						<xsl:variable name="value"
            							select="Insurance1/adminsmne"/>
						<xsl:choose>
							<xsl:when test="count(/XCSData/query_results/MEDIPASS_CERT_CODES/MEDIPASS_CERT_CODES[INS_PLANS = $value]) != 0">
								<PV9.22>
									<xsl:value-of select="Insurance1/adminstreatmentauth"/>
								</PV9.22>
								<PV9.23>
									<xsl:value-of select="Insurance1/adminstreatmentauth"/>
								</PV9.23>
							</xsl:when>
							<xsl:otherwise>
								<PV9.22/>
								<PV9.23/>
							</xsl:otherwise>
						</xsl:choose>
						<PV9.24/>
						<PV9.25/>
						<PV9.26/>
						<PV9.27/>
						<PV9.28/>
						<PV9.29/>
						<PV9.30/>
						<PV9.31/>
						<PV9.32/>
						<PV9.33/>
						<PV9.34/>
						<PV9.35/>
						<PV9.36/>
						<PV9.37/>
						<PV9.38/>
						<PV9.39>
							<xsl:value-of select="PatientDemographics/ChiefComplaint"/>
						</PV9.39>
						<PV9.40>
							<!--<xsl:value-of select="PatientDemographics/ChiefComplaint" />-->
						</PV9.40>
					</PV9>
					<!--DG1-->
					<xsl:for-each select="DiagnosisCodes/Diag1 | DiagnosisCodes/Diag2 | DiagnosisCodes/Diag3 | DiagnosisCodes/Diag4 | DiagnosisCodes/Diag5 | DiagnosisCodes/Diag6 | DiagnosisCodes/Diag7 | DiagnosisCodes/Diag8 | DiagnosisCodes/Diag9 | DiagnosisCodes/Diag10 | DiagnosisCodes/Diag11 | DiagnosisCodes/Diag12">
						<DG1>
							<DG1.1/>
							<DG1.2/>
							<DG1.3>
								<xsl:value-of select="."/>
							</DG1.3>
							<DG1.4/>
							<DG1.5/>
							<DG1.6/>
							<DG1.7/>
							<DG1.8/>
							<DG1.9/>
							<DG1.10/>
							<DG1.11/>
							<DG1.12/>
							<DG1.13/>
							<DG1.14/>
							<DG1.15/>
							<DG1.16/>
							<DG1.17/>
							<DG1.18/>
							<DG1.19/>
						</DG1>
					</xsl:for-each>
					<!--GT1-->
					<GT1>
						<GT1.1>
							<xsl:text>0001</xsl:text>
						</GT1.1>
						<GT1.2>
							<xsl:value-of select="substring(concat($txtFacilityCode, substring(Guarantor/admAcctNum, string-length(Guarantor/admAcctNum) - 10)), 1, 8)"/>
						</GT1.2>
						<GT1.3>
							<XPN.1>
								<xsl:value-of select="normalize-space(substring-before(Guarantor/admGuarName, ','))"/>
							</XPN.1>
							<XPN.2>
								<xsl:value-of select="normalize-space(substring-after(Guarantor/admGuarName, ','))"/>
							</XPN.2>
						</GT1.3>
						<GT1.4/>
						<GT1.5>
							<XAD.1>
								<xsl:value-of select="Guarantor/admGuarAddr1"/>
								<xsl:if test="string-length(Guarantor/admGuarAddr2) != 0">
									<xsl:value-of select="concat(' ', Guarantor/admGuarAddr2)"/>
								</xsl:if>
							</XAD.1>
							<XAD.2>
							</XAD.2>
							<XAD.3>
								<xsl:value-of select="Guarantor/admGuarCity"/>
							</XAD.3>
							<XAD.4>
								<xsl:value-of select="Guarantor/admGuarState"/>
							</XAD.4>
							<XAD.5>
								<xsl:value-of select="Guarantor/admGuarZip"/>
							</XAD.5>
						</GT1.5>
						<GT1.6>
							<xsl:value-of select="Guarantor/admGuarHomePhone"/>
						</GT1.6>
						<GT1.7>
							<xsl:value-of select="Guarantor/admGuarEmplPhone"/>
						</GT1.7>
						<GT1.8>
							<xsl:value-of select="PatientDemographics/admbirthdate"/>
						</GT1.8>
						<GT1.9/>
						<GT1.10/>
						<GT1.11>
							<xsl:value-of select="Guarantor/admGuarRel"/>
						</GT1.11>
						<GT1.12>
							<xsl:value-of select="Guarantor/admGuarSSN"/>
						</GT1.12>
						<GT1.13/>
						<GT1.14/>
						<GT1.15/>
						<GT1.16>
							<xsl:value-of select="Guarantor/admGuarEmployer"/>
						</GT1.16>
						<GT1.17>
						</GT1.17>
						<GT1.18/>
						<GT1.19/>
						<GT1.20/>
						<GT1.21/>
						<GT1.22/>
						<GT1.23/>
						<GT1.24/>
						<GT1.25/>
						<GT1.26/>
						<GT1.27/>
						<GT1.28/>
						<GT1.29/>
						<GT1.30/>
						<GT1.31/>
						<GT1.32/>
						<GT1.33/>
						<GT1.34/>
						<GT1.35/>
						<GT1.36/>
						<GT1.37/>
						<GT1.38/>
						<GT1.39/>
						<GT1.40/>
						<GT1.41/>
						<GT1.42/>
						<GT1.43/>
						<GT1.44/>
						<GT1.45/>
						<GT1.46/>
						<GT1.47/>
						<GT1.48/>
						<GT1.49/>
						<GT1.50/>
						<GT1.51/>
						<GT1.52/>
						<GT1.53/>
						<GT1.54/>
						<GT1.55/>
						<GT1.56/>
					</GT1>
					<!--Insurance-->
					<xsl:for-each select="(Insurance1 | Insurance2 | Insurance3)[string-length(adminsmne) &gt; 0]">
						<ADT_A01.INSURANCE>
							<!--IN1-->
							<IN1>
								<IN1.1>
									<xsl:text>0001</xsl:text>
								</IN1.1>
								<IN1.2>
									<xsl:value-of select="adminsmne"/>
								</IN1.2>
								<IN1.3>
									<xsl:value-of select="adminsmne"/>
								</IN1.3>
								<IN1.4>
									<xsl:value-of select="admInsName"/>
								</IN1.4>
								<IN1.5>
									<XAD.1>
										<xsl:value-of select="adminsstreet"/>
									</XAD.1>
									<XAD.2/>
									<XAD.3>
										<xsl:value-of select="adminscity"/>
									</XAD.3>
									<XAD.4>
										<xsl:value-of select="adminsstate"/>
									</XAD.4>
									<XAD.5>
										<xsl:value-of select="adminszip"/>
									</XAD.5>
								</IN1.5>
								<IN1.6/>
								<IN1.7>
									<xsl:value-of select="admInsPhone"/>
								</IN1.7>
								<IN1.8>
									<xsl:if test="not(matches(adminsgroup, '999.*'))">
										<xsl:value-of select="adminsgroup"/>
									</xsl:if>
								</IN1.8>
								<IN1.9>
								</IN1.9>
								<IN1.10/>
								<IN1.11/>
								<IN1.12/>
								<IN1.13/>
								<IN1.14>
								</IN1.14>
								<IN1.15>
									<xsl:text>P</xsl:text>
								</IN1.15>
								<IN1.16>
									<XCN.1>
										<xsl:value-of select="normalize-space(substring-before(adminsinsuredname, ','))"/>
									</XCN.1>
									<XCN.2>
										<xsl:value-of select="normalize-space(substring-after(adminsinsuredname, ','))"/>
									</XCN.2>
								</IN1.16>
								<IN1.17>
									<xsl:value-of select="adminsinsuredrel"/>
								</IN1.17>
								<IN1.18>
									<xsl:value-of select="../PatientDemographics/admbirthdate"/>
								</IN1.18>
								<IN1.19>
									<XAD.1>
										<xsl:value-of select="../Guarantor/admGuarAddr1"/>
										<xsl:if test="string-length(../Guarantor/admGuarAddr2) != 0">
											<xsl:value-of select="concat(' ', ../Guarantor/admGuarAddr2)"/>
										</xsl:if>
									</XAD.1>
									<XAD.2>
									</XAD.2>
									<XAD.3>
										<xsl:value-of select="../Guarantor/admGuarCity"/>
									</XAD.3>
									<XAD.4>
										<xsl:value-of select="../Guarantor/admGuarState"/>
									</XAD.4>
									<XAD.5>
										<xsl:value-of select="../Guarantor/admGuarZip"/>
									</XAD.5>
								</IN1.19>
								<IN1.20>
									<xsl:text>Y</xsl:text>
								</IN1.20>
								<IN1.21/>
								<IN1.22/>
								<IN1.23/>
								<IN1.24/>
								<IN1.25/>
								<IN1.26/>
								<IN1.27/>
								<IN1.28/>
								<IN1.29/>
								<IN1.30/>
								<IN1.31/>
								<IN1.32/>
								<IN1.33/>
								<IN1.34/>
								<IN1.35>
								</IN1.35>
								<IN1.36>
									<xsl:value-of select="adminspolicy"/>
								</IN1.36>
								<IN1.37/>
								<IN1.38/>
								<IN1.39/>
								<IN1.40/>
								<IN1.41/>
								<IN1.42/>
								<IN1.43>
									<xsl:value-of select="../PatientDemographics/admpatsex"/>
								</IN1.43>
								<IN1.44/>
								<IN1.45/>
								<IN1.46/>
								<IN1.47/>
								<IN1.48/>
								<IN1.49/>
								<IN1.50/>
							</IN1>
						</ADT_A01.INSURANCE>
					</xsl:for-each>
					<xsl:if test="position() = count($dataset)">
						<BTS>
							<BTS.1>
								<xsl:value-of select="count($dataset)"/>
							</BTS.1>
							<BTS.2/>
							<BTS.3>
								<xsl:value-of select="count($dataset)"/>
							</BTS.3>
							<BTS.4/>
						</BTS>
					</xsl:if>
				</ADT_A01>
			</xsl:for-each>
		</XCSData>
	</xsl:template>
</xsl:stylesheet>
