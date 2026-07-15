<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:dtFormatter="xalan://com.pilotfish.eip.gui.mapper.util.DateTimeFormatter" xmlns:str="http://exslt.org/strings" exclude-result-prefixes="str dtFormatter" expand-text="yes" version="3.1">
  <xsl:param name="FacilityName" select="'Aventura Hospital'" />
  <xsl:template match="/">
    <XCSData>
      <Group key="">
        <Header>
          <FacilityName>{$FacilityName}</FacilityName>
        </Header>
        <Unknown />
      </Group>
      <xsl:variable name="HospitalAccountNumber" select="_600" />
      <xsl:for-each-group group-by="$HospitalAccountNumber" select="//XCSRecord">
        <xsl:variable name="ServiceYear" select="dtFormatter:format(SVCDATE,'MM/dd/yyyy','YYYY')" />
        <xsl:if test="$HospitalAccountNumber != 'null' and $ServiceYear &lt; '2025'">
          <Group key="{current-grouping-key()}">
            <PatientDemographics>
              <admpatstate>{substring(_1STCVGSTATE,1,2)}</admpatstate>
              <absAdmitdate>{concat('20',substring(ADMITDATE,5,7),substring(ADMITDATE,1,4))}</absAdmitdate>
              <!--NOTUSED-<absattendingdocupin>{substring(2003,1,6)}</absattendingdocupin>-->
              <absdischargedate>{concat('20',substring(DISCHARGE,5,7),substring(DISCHARGE,1,4))}</absdischargedate>
              <admemplname>{substring(EMP,1,30)}</admemplname>
              <admzipcode>{substring(ZIP,1,10)}</admzipcode>
              <!--NOTUSED-<absattendingdocmnem>{substring(OBRKE,1,10)}</absattendingdocmnem>-->
              <!--<absadmitdiag>{substring(ADMITDX,1,10)}</absadmitdiag>-->
              <absattendingdocname>{substring(ATTENDDRNAME,1,20)}</absattendingdocname>
              <admemplstreet>{substring(EMPADD,1,30)}</admemplstreet>
              <admAcctNum>{substring(CSN,1,12)}</admAcctNum>
              <admbirthdate>
                <xsl:if test="string-length(DOB) != 0">
                  <xsl:value-of select="dtFormatter:format(DOB,'MM/dd/yyyy','YYYYMMdd')" />
                </xsl:if>
              </admbirthdate>
              <admLocation>{substring(DEP,1,10)}</admLocation>
              <admpatsex>{substring(SEX,1,1)}</admpatsex>
              <admpatphone>{substring(PHONE,1,10)}</admpatphone>
              <admssn>{substring(translate(SSN,'-',''),1,9)}</admssn>
              <admname>{substring(NAME,1,30)}</admname>
              <admemplcity>{substring(EMPCITY,1,20)}</admemplcity>
              <!--NOTUSED-<ERDrNPI>{substring(1750712246,1,10)}</ERDrNPI>-->
              <admpatcity>{substring(CITY,1,20)}</admpatcity>
              <admFinClass>{substring(FINCLASS,1,12)}</admFinClass>
              <AttendDrNPI>{substring(ATTENDDRNPI,1,10)}</AttendDrNPI>
              <!--NOTUSED-<absPatientUnit>{substring(00713496,1,10)}</absPatientUnit>-->
              <admpatienttype>{substring(PATBASECLASS,1,1)}</admpatienttype>
              <admstreet>{substring(ADDLN1,1,30)}</admstreet>
              <admemplzip>{substring(EMPZIP,1,10)}</admemplzip>
              <ChiefComplaint />
              <!--NOTUSED-<admaccidentdate>{substring(20230228,1,8)}</admaccidentdate>-->
            </PatientDemographics>
            <DiagnosisCodes>
              <Diag1CodeSet>ICD10</Diag1CodeSet>
              <!--<Diag1>{substring-before(substring(FINALDX,1,10),',')}</Diag1>-->
              <radAcctNum>{substring(CSN,1,12)}</radAcctNum>
              <xsl:variable name="diags" select="tokenize(concat(ADMITDX,',',FINALDX),',')" />
              <xsl:for-each select="$diags">
                <xsl:variable name="elementName" select="concat('Diag', position())" />
                <xsl:element name="{$elementName}">
                  <xsl:value-of select="." />
                </xsl:element>
              </xsl:for-each>
            </DiagnosisCodes>
            <Insurance1>
              <adminsstate>{substring(_1STCVGSTATE,1,2)}</adminsstate>
              <adminspolicy>{substring(_1STCVGSUBID,1,30)}</adminspolicy>
              <subscribername>{substring(_1STCVGSUBNAME,1,30)}</subscribername>
              <adminszip>{substring(_1STCVGZIP,1,10)}</adminszip>
              <!--NOTUSED-<adminsPaCode>{substring(26150                   2,1,25)}</adminsPaCode>-->
              <!--NOTUSED-<absPatientUnit>{substring(00713496,1,10)}</absPatientUnit>-->
              <admInsName>{substring(_1STCVGPAYORNAME,1,30)}</admInsName>
              <admAcctNum>{substring(CSN,1,12)}</admAcctNum>
              <adminsinsuredrel>{substring(_1STCVGPATRELTOSUB,1,10)}</adminsinsuredrel>
              <adminsstreet>{substring(_1STCVGADDLN1,1,30)}</adminsstreet>
              <adminscity>{substring(_1STCVGCITY,1,20)}</adminscity>
              <adminsmne>{substring(_1STPLANID,1,10)}</adminsmne>
              <adminsinsuredname>{substring(_1STCVGSUBNAME,1,30)}</adminsinsuredname>
              <admInsPhone>{substring(_1STCVGPHONE,1,20)}</admInsPhone>
              <adminsgroup>{substring(_1STCVGSUBGPNUM,1,15)}</adminsgroup>
            </Insurance1>
            <Insurance2>
              <adminsstate>{substring(_2NDCVGSTATE,1,2)}</adminsstate>
              <adminspolicy>{substring(_2NDCVGSUBID,1,30)}</adminspolicy>
              <subscribername>{substring(_2NDCVGSUBNAME,1,30)}</subscribername>
              <adminszip>{substring(_2NDCVGZIP,1,10)}</adminszip>
              <admInsName>{substring(_2NDCVGPAYORNAME,1,30)}</admInsName>
              <admAcctNum>{substring(CSN,1,12)}</admAcctNum>
              <adminsinsuredrel>{substring(_2NDCVGPATRELTOSUB,1,10)}</adminsinsuredrel>
              <adminsstreet>{substring(_2NDCVGADDLN1,1,30)}</adminsstreet>
              <adminscity>{substring(_2NDCVGCITY,1,20)}</adminscity>
              <adminsmne>{substring(_2NDCVGPLANID,1,10)}</adminsmne>
              <adminsinsuredname>{substring(_2NDCVGSUBNAME,1,30)}</adminsinsuredname>
              <admInsPhone>{substring(_2NDCVGPHONE,1,20)}</admInsPhone>
              <adminsgroup>{substring(_2NDCVGSUBGPNUM,1,15)}</adminsgroup>
            </Insurance2>
            <Insurance3>
              <admAcctNum>{substring(CSN,1,12)}</admAcctNum>
              <!--NOTUSED-<absPatientUnit>{substring(00713496,1,10)}</absPatientUnit>-->
              <adminsgroup>{substring(_3RDCVGSUBGPNUM,1,15)}</adminsgroup>
            </Insurance3>
            <Guarantor>
              <admGuarCity>{substring(EARCITY,1,20)}</admGuarCity>
              <admGuarEmployer>{substring(EAREMP,1,10)}</admGuarEmployer>
              <admGuarAddr1>{substring(EARADDRESSLN1,1,30)}</admGuarAddr1>
              <admGuarHomePhone>{substring(EARPHONE,1,10)}</admGuarHomePhone>
              <admGuarZip>{substring(EARZIP,1,10)}</admGuarZip>
              <!--NOTUSED-<admPatientUnit>{substring(00713496,1,10)}</admPatientUnit>-->
              <admGuarEmplCity>{substring(EAREMPCITY,1,20)}</admGuarEmplCity>
              <admGuarEmplState>{substring(EAREMPSTATE,1,2)}</admGuarEmplState>
              <admGuarEmplZip>{substring(EAREMPZIP,1,10)}</admGuarEmplZip>
              <admGuarRel>{substring(EARRELTOPAT,1,10)}</admGuarRel>
              <admGuarName>
                <xsl:choose>
                  <xsl:when test="not(contains(EARNAME,','))">
                    <xsl:value-of select="concat(substring-after(substring(EARNAME,1,30),' '),', ',substring-before(substring(EARNAME,1,30),' '))" />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="substring(EARNAME,1,30)" />
                  </xsl:otherwise>
                </xsl:choose>
              </admGuarName>
              <!--NOTUSED-<npr1>{substring(5938278,1,16)}</npr1>-->
              <admGuarState>{substring(EARSTATE,1,2)}</admGuarState>
              <admGuarEmplAddr2>{substring(EARADDRESSLN2,1,30)}</admGuarEmplAddr2>
              <admAcctNum>{substring(CSN,1,12)}</admAcctNum>
              <admGuarEmplAddr1>{substring(EAREMPADD,1,30)}</admGuarEmplAddr1>
              <admGuarSSN>{substring(translate(EARSSN,'-',''),1,9)}</admGuarSSN>
            </Guarantor>
            <xsl:for-each select="current-group()">
              <Charge>
                <radExamServDate>
                  <xsl:if test="string-length(SVCDATE) != 0">
                    <xsl:value-of select="dtFormatter:format(SVCDATE,'MM/dd/yyyy','YYYYMMdd')" />
                  </xsl:if>
                </radExamServDate>
                <!--NOTUSED-<ExamApplication>{substring(LIS.L,1,15)}</ExamApplication>-->
                <radPatientName>{substring(NAME,1,30)}</radPatientName>
                <radExamBillingCode>{substring(PXCD,1,8)}</radExamBillingCode>
                <radExamCPT>{substring(CPT,1,10)}</radExamCPT>
                <!--NOTUSED-<misOrderingPhyCity>{substring(Brentwood,1,20)}</misOrderingPhyCity>-->
                <!--NOTUSED-<absPatientUnit>{substring(00713496,1,10)}</absPatientUnit>-->
                <radAcctNum>{substring(CSN,1,12)}</radAcctNum>
                <!--NOTUSED-<radOrderingPhyMne>{substring(SHAPR01,1,10)}</radOrderingPhyMne>-->
                <!--USED-<misOrderingPhyName>{substring(Sharma,Prerna  MD MD,1,30)}</misOrderingPhyName>-->
                <!--NOTUSED-<misOrderingPhyAddr>{substring(2000 Health Park Drive,1,30)}</misOrderingPhyAddr>-->
                <radNumOfTimes>{substring(QTY,1,10)}</radNumOfTimes>
              </Charge>
            </xsl:for-each>
          </Group>
        </xsl:if>
      </xsl:for-each-group>
    </XCSData>
  </xsl:template>
</xsl:stylesheet>

