<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:pf="http://pilotfishtechnology.com" xmlns:xs="http://www.w3.org/2001/XMLSchema" version="3.1">
  <xsl:output encoding="UTF-8" indent="yes" method="xml" version="1.0" />
  <xsl:template match="/">
    <XCSData>
      <Group key="">
        <Unknown />
        <Header>
          <FacilityName>HCA AP Logs</FacilityName>
        </Header>
      </Group>
      <!-- Process each real data row from the AP Log CSV.
			     Skip blank rows, the "Key to Doctor Mnemonics" appendix,
			     and the trailing "Facility:" summary row. -->
      <xsl:for-each select="//XCSRecord[string-length(normalize-space(SPEC_DATE)) != 0 and string-length(normalize-space(PT_ACCT_)) != 0 and string-length(normalize-space(PATIENT_NAME)) != 0 and string-length(normalize-space(CNT)) != 0]">
        <Group>
          <xsl:attribute name="key" select="PT_ACCT_" />
          <!-- Patient Demographics -->
          <PatientDemographics>
            <absadmitdiag />
            <admpatstate />
            <absAdmitdate>
              <xsl:value-of select="pf:convertDate(SPEC_DATE)" />
            </absAdmitdate>
            <absattendingdocupin />
            <absdischargedate />
            <admemplname />
            <admzipcode />
            <absattendingdocmnem>
              <xsl:value-of select="SIGNER" />
            </absattendingdocmnem>
            <absattendingdocname>
              <xsl:value-of select="pf:lookupDoctor(SIGNER)" />
            </absattendingdocname>
            <admemplstreet />
            <admAcctNum>
              <xsl:value-of select="PT_ACCT_" />
            </admAcctNum>
            <admbirthdate />
            <admLocation>
              <xsl:value-of select="FACILITY" />
            </admLocation>
            <admpatsex />
            <admpatphone />
            <admssn />
            <admname>
              <xsl:value-of select="PATIENT_NAME" />
            </admname>
            <admemplcity />
            <admpatcity />
            <admFinClass />
            <AttendDrNPI />
            <absPatientUnit />
            <admpatienttype>NA</admpatienttype>
            <admstreet />
            <admstreet2 />
            <admemplzip />
            <ChiefComplaint />
            <admaccidentdate />
            <Filler2 />
            <admmaritalstatus>U</admmaritalstatus>
          </PatientDemographics>
          <!-- Charge record (one per row in the AP Log) -->
          <Charge>
            <radNumOfTimes>
              <xsl:value-of select="CNT" />
            </radNumOfTimes>
            <!--<radCRDBIndicator>1</radCRDBIndicator>-->
            <radExamServDate>
              <xsl:value-of select="pf:convertDate(SPEC_DATE)" />
            </radExamServDate>
            <radPatientName>
              <xsl:value-of select="PATIENT_NAME" />
            </radPatientName>
            <radAcctNum>
              <xsl:value-of select="PT_ACCT_" />
            </radAcctNum>
            <radExamBillingCode>
              <xsl:value-of select="PROCEDURE" />
            </radExamBillingCode>
            <radExamCPT>
              <xsl:value-of select="PROCEDURE" />
            </radExamCPT>
            <examdesc />
            <radOrderingPhyLic />
            <absPatientUnit />
            <radOrderingPhyMne>
              <xsl:value-of select="pf:lookupDoctor(SIGNER)" />
            </radOrderingPhyMne>
            <ExamHCPCCode />
            <orderingDrNPI />
            <misOrderingPhyCity />
            <radOrderingPhyUPIN />
            <misOrderingPhyName>
              <xsl:value-of select="pf:lookupDoctor(SIGNER)" />
            </misOrderingPhyName>
            <misOrderingPhyAddr />
          </Charge>
          <!-- Guarantor (minimal data available in the AP Log) -->
          <Guarantor>
            <admGuarCity />
            <admGuarEmployer />
            <admGuarAddr1 />
            <admGuarHomePhone />
            <admGuarZip />
            <admPatientUnit />
            <admGuarEmplCity />
            <admGuarEmplState />
            <admGuarEmplZip />
            <admGuarRel>15</admGuarRel>
            <admGuarName>
              <xsl:value-of select="PATIENT_NAME" />
            </admGuarName>
            <npr1 />
            <admGuarState />
            <admAcctNum />
            <admGuarEmplAddr1 />
            <admGuarSSN />
            <admGuarEmplPhone />
          </Guarantor>
          <!-- No diagnosis or insurance data in the AP Log; emit empty
					     blocks so the canonical structure is preserved. -->
          <DiagnosisCodes />
          <Insurance1>
            <adminsstate />
            <adminspolicy />
            <subscribername />
            <adminszip />
            <adminsPaCode />
            <absPatientUnit />
            <admInsName />
            <admAcctNum />
            <adminsinsuredrel />
            <adminsstreet />
            <adminsgroup />
            <adminscity />
            <adminsmne />
            <adminsinsuredname />
            <admInsPhone />
            <authnumber />
          </Insurance1>
          <Insurance2>
            <adminsstate />
            <adminspolicy />
            <subscribername />
            <adminszip />
            <adminsPaCode />
            <absPatientUnit />
            <admInsName />
            <admAcctNum />
            <adminsinsuredrel />
            <adminsstreet />
            <adminsgroup />
            <adminscity />
            <adminsmne />
            <adminsinsuredname />
            <admInsPhone />
          </Insurance2>
          <Insurance3>
            <admAcctNum />
            <absPatientUnit />
          </Insurance3>
        </Group>
      </xsl:for-each>
    </XCSData>
  </xsl:template>
  <!-- Convert MM/DD/YY (or MM/DD/YYYY) to YYYYMMDD. Returns '' on empty input. -->
  <xsl:function as="xs:string" name="pf:convertDate">
    <xsl:param as="xs:string?" name="date" />
    <xsl:choose>
      <xsl:when test="string-length(normalize-space($date)) = 0">
        <xsl:value-of select="''" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="parts" select="tokenize(normalize-space($date), '/')" />
        <xsl:variable name="yyyy">
          <xsl:choose>
            <xsl:when test="string-length($parts[3]) = 2">
              <xsl:value-of select="concat('20', $parts[3])" />
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$parts[3]" />
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="concat($yyyy, format-number(number($parts[1]), '00'), format-number(number($parts[2]), '00'))" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  <!-- Resolve a SIGNER mnemonic (from the "Key to Doctor Mnemonics" appendix)
	     to the pathologist's name. Returns the raw code when unknown. -->
  <xsl:function as="xs:string" name="pf:lookupDoctor">
    <xsl:param as="xs:string?" name="mne" />
    <xsl:choose>
      <xsl:when test="$mne = 'BAZ2433'">
        <xsl:value-of select="'Lindsey Serkes, MD'" />
      </xsl:when>
      <xsl:when test="$mne = 'BXI3478'">
        <xsl:value-of select="'Vijay Kumar, MD'" />
      </xsl:when>
      <xsl:when test="$mne = 'CGI8852'">
        <xsl:value-of select="'Emerald D O''Sullivan-Mejia, MD'" />
      </xsl:when>
      <xsl:when test="$mne = 'CQA3271'">
        <xsl:value-of select="'Qian Dai, MD'" />
      </xsl:when>
      <xsl:when test="$mne = 'EWR5233'">
        <xsl:value-of select="'Robert W Jarrett, JR, MD'" />
      </xsl:when>
      <xsl:when test="$mne = 'HBO3432'">
        <xsl:value-of select="'Basma Elhaddad, MD'" />
      </xsl:when>
      <xsl:when test="$mne = 'KMU3178'">
        <xsl:value-of select="'Duyet C Vo, MD'" />
      </xsl:when>
      <xsl:when test="$mne = 'LFE6775'">
        <xsl:value-of select="'Lena C Young, DO'" />
      </xsl:when>
      <xsl:when test="$mne = 'LTO9407'">
        <xsl:value-of select="'Daniel A Schaffer, MD'" />
      </xsl:when>
      <xsl:when test="$mne = 'NOZ6163'">
        <xsl:value-of select="'Amanda L Gohlke, MD'" />
      </xsl:when>
      <xsl:when test="$mne = 'OYD4603'">
        <xsl:value-of select="'Simran S Mashiana, MD'" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="string($mne)" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
</xsl:stylesheet>

