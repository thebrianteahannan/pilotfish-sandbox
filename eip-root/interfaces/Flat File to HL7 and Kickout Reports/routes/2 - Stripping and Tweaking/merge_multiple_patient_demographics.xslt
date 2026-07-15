<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:template match="/">
    <XSCData>
      <xsl:for-each select="//Group[string-length(@key) != 0]">
        <Group>
          <xsl:attribute name="key" select="@key" />
          <!--Merge patient demographics records because we can only have one PatientDemographics record.-->
          <!--Include the most recently populated value for each demographic value only.-->
          <PatientDemographics>
            <absadmitdiag>
              <xsl:for-each select="PatientDemographics/absadmitdiag[string-length(.) != 0]">
                <xsl:sort data-type="text" order="descending" select="../absAdmitDate" />
                <xsl:if test="position() = 1">
                  <xsl:value-of select="." />
                </xsl:if>
              </xsl:for-each>
            </absadmitdiag>
            <admpatstate>
              <xsl:for-each select="PatientDemographics/admpatstate[string-length(.) != 0]">
                <xsl:sort data-type="text" order="descending" select="../absAdmitDate" />
                <xsl:if test="position() = 1">
                  <xsl:value-of select="." />
                </xsl:if>
              </xsl:for-each>
            </admpatstate>
            <absAdmitdate>
              <xsl:for-each select="PatientDemographics/absAdmitdate[string-length(.) != 0]">
                <xsl:sort data-type="text" order="descending" select="../absAdmitdate" />
                <xsl:if test="position() = 1">
                  <xsl:value-of select="." />
                </xsl:if>
              </xsl:for-each>
            </absAdmitdate>
            <absattendingdocupin>
              <xsl:for-each select="PatientDemographics/absattendingdocupin[string-length(.) != 0]">
                <xsl:sort data-type="text" order="descending" select="../absAdmitDate" />
                <xsl:if test="position() = 1">
                  <xsl:value-of select="." />
                </xsl:if>
              </xsl:for-each>
            </absattendingdocupin>
            <absdischargedate>
              <xsl:for-each select="PatientDemographics/absdischargedate[string-length(.) != 0]">
                <xsl:sort data-type="text" order="descending" select="../absAdmitDate" />
                <xsl:if test="position() = 1">
                  <xsl:value-of select="." />
                </xsl:if>
              </xsl:for-each>
            </absdischargedate>
            <admemplname>
              <xsl:for-each select="PatientDemographics/admemplname[string-length(.) != 0]">
                <xsl:sort data-type="text" order="descending" select="../absAdmitDate" />
                <xsl:if test="position() = 1">
                  <xsl:value-of select="." />
                </xsl:if>
              </xsl:for-each>
            </admemplname>
            <admzipcode>
              <xsl:for-each select="PatientDemographics/admzipcode[string-length(.) != 0]">
                <xsl:sort data-type="text" order="descending" select="../absAdmitDate" />
                <xsl:if test="position() = 1">
                  <xsl:value-of select="." />
                </xsl:if>
              </xsl:for-each>
            </admzipcode>
            <absattendingdocmnem>
              <xsl:for-each select="PatientDemographics/absattendingdocmnem[string-length(.) != 0]">
                <xsl:sort data-type="text" order="descending" select="../absAdmitDate" />
                <xsl:if test="position() = 1">
                  <xsl:value-of select="." />
                </xsl:if>
              </xsl:for-each>
            </absattendingdocmnem>
            <absattendingdocname>
              <xsl:for-each select="PatientDemographics/absattendingdocname[string-length(.) != 0]">
                <xsl:sort data-type="text" order="descending" select="../absAdmitDate" />
                <xsl:if test="position() = 1">
                  <xsl:value-of select="." />
                </xsl:if>
              </xsl:for-each>
            </absattendingdocname>
            <admemplstreet>
              <xsl:for-each select="PatientDemographics/admemplstreet[string-length(.) != 0]">
                <xsl:sort data-type="text" order="descending" select="../absAdmitDate" />
                <xsl:if test="position() = 1">
                  <xsl:value-of select="." />
                </xsl:if>
              </xsl:for-each>
            </admemplstreet>
            <admAcctNum>
              <xsl:for-each select="PatientDemographics/admAcctNum[string-length(.) != 0]">
                <xsl:sort data-type="text" order="descending" select="../absAdmitDate" />
                <xsl:if test="position() = 1">
                  <xsl:value-of select="." />
                </xsl:if>
              </xsl:for-each>
            </admAcctNum>
            <admbirthdate>
              <xsl:for-each select="PatientDemographics/admbirthdate[string-length(.) != 0]">
                <xsl:sort data-type="text" order="descending" select="../absAdmitDate" />
                <xsl:if test="position() = 1">
                  <xsl:value-of select="." />
                </xsl:if>
              </xsl:for-each>
            </admbirthdate>
            <admLocation>
              <xsl:for-each select="PatientDemographics/admLocation[string-length(.) != 0]">
                <xsl:sort data-type="text" order="descending" select="../absAdmitDate" />
                <xsl:if test="position() = 1">
                  <xsl:value-of select="." />
                </xsl:if>
              </xsl:for-each>
            </admLocation>
            <LabName>
              <xsl:for-each select="PatientDemographics/LabName[string-length(.) != 0]">
                <xsl:sort data-type="text" order="descending" select="../absAdmitDate" />
                <xsl:if test="position() = 1">
                  <xsl:value-of select="." />
                </xsl:if>
              </xsl:for-each>
            </LabName>
            <admpatsex>
              <xsl:for-each select="PatientDemographics/admpatsex[string-length(.) != 0]">
                <xsl:sort data-type="text" order="descending" select="../absAdmitDate" />
                <xsl:if test="position() = 1">
                  <xsl:value-of select="." />
                </xsl:if>
              </xsl:for-each>
            </admpatsex>
            <admpatphone>
              <xsl:for-each select="PatientDemographics/admpatphone[string-length(.) != 0]">
                <xsl:sort data-type="text" order="descending" select="../absAdmitDate" />
                <xsl:if test="position() = 1">
                  <xsl:value-of select="." />
                </xsl:if>
              </xsl:for-each>
            </admpatphone>
            <admssn>
              <xsl:for-each select="PatientDemographics/admssn[string-length(.) != 0]">
                <xsl:sort data-type="text" order="descending" select="../absAdmitDate" />
                <xsl:if test="position() = 1">
                  <xsl:value-of select="." />
                </xsl:if>
              </xsl:for-each>
            </admssn>
            <admname>
              <xsl:for-each select="PatientDemographics/admname[string-length(.) != 0]">
                <xsl:sort data-type="text" order="descending" select="../absAdmitDate" />
                <xsl:if test="position() = 1">
                  <xsl:value-of select="." />
                </xsl:if>
              </xsl:for-each>
            </admname>
            <admemplcity>
              <xsl:for-each select="PatientDemographics/admemplcity[string-length(.) != 0]">
                <xsl:sort data-type="text" order="descending" select="../absAdmitDate" />
                <xsl:if test="position() = 1">
                  <xsl:value-of select="." />
                </xsl:if>
              </xsl:for-each>
            </admemplcity>
            <admpatcity>
              <xsl:for-each select="PatientDemographics/admpatcity[string-length(.) != 0]">
                <xsl:sort data-type="text" order="descending" select="../absAdmitDate" />
                <xsl:if test="position() = 1">
                  <xsl:value-of select="." />
                </xsl:if>
              </xsl:for-each>
            </admpatcity>
            <admFinClass>
              <xsl:for-each select="PatientDemographics/admFinClass[string-length(.) != 0]">
                <xsl:sort data-type="text" order="descending" select="../absAdmitDate" />
                <xsl:if test="position() = 1">
                  <xsl:value-of select="." />
                </xsl:if>
              </xsl:for-each>
            </admFinClass>
            <AttendDrNPI>
              <xsl:for-each select="PatientDemographics/AttendDrNPI[string-length(.) != 0]">
                <xsl:sort data-type="text" order="descending" select="../absAdmitDate" />
                <xsl:if test="position() = 1">
                  <xsl:value-of select="." />
                </xsl:if>
              </xsl:for-each>
            </AttendDrNPI>
            <absPatientUnit>
              <xsl:for-each select="PatientDemographics/absPatientUnit[string-length(.) != 0]">
                <xsl:sort data-type="text" order="descending" select="../absAdmitDate" />
                <xsl:if test="position() = 1">
                  <xsl:value-of select="." />
                </xsl:if>
              </xsl:for-each>
            </absPatientUnit>
            <admpatienttype>
              <xsl:for-each select="PatientDemographics/admpatienttype[string-length(.) != 0]">
                <xsl:sort data-type="text" order="descending" select="../absAdmitDate" />
                <xsl:if test="position() = 1">
                  <xsl:value-of select="." />
                </xsl:if>
              </xsl:for-each>
            </admpatienttype>
            <admstreet>
              <xsl:for-each select="PatientDemographics/admstreet[string-length(.) != 0]">
                <xsl:sort data-type="text" order="descending" select="../absAdmitDate" />
                <xsl:if test="position() = 1">
                  <xsl:value-of select="." />
                </xsl:if>
              </xsl:for-each>
            </admstreet>
            <admstreet2>
              <xsl:for-each select="PatientDemographics/admstreet2[string-length(.) != 0]">
                <xsl:sort data-type="text" order="descending" select="../absAdmitDate" />
                <xsl:if test="position() = 1">
                  <xsl:value-of select="." />
                </xsl:if>
              </xsl:for-each>
            </admstreet2>
            <admemplzip>
              <xsl:for-each select="PatientDemographics/admemplzip[string-length(.) != 0]">
                <xsl:sort data-type="text" order="descending" select="../absAdmitDate" />
                <xsl:if test="position() = 1">
                  <xsl:value-of select="." />
                </xsl:if>
              </xsl:for-each>
            </admemplzip>
            <ChiefComplaint>
              <xsl:for-each select="PatientDemographics/ChiefComplaint[string-length(.) != 0]">
                <xsl:sort data-type="text" order="descending" select="../absAdmitDate" />
                <xsl:if test="position() = 1">
                  <xsl:value-of select="." />
                </xsl:if>
              </xsl:for-each>
            </ChiefComplaint>
            <admaccidentdate>
              <xsl:for-each select="PatientDemographics/admaccidentdate[string-length(.) != 0]">
                <xsl:sort data-type="text" order="descending" select="../absAdmitDate" />
                <xsl:if test="position() = 1">
                  <xsl:value-of select="." />
                </xsl:if>
              </xsl:for-each>
            </admaccidentdate>
            <Filler2>
              <xsl:for-each select="PatientDemographics/Filler2[string-length(.) != 0]">
                <xsl:sort data-type="text" order="descending" select="../absAdmitDate" />
                <xsl:if test="position() = 1">
                  <xsl:value-of select="." />
                </xsl:if>
              </xsl:for-each>
            </Filler2>
            <admmaritalstatus>
              <xsl:for-each select="PatientDemographics/admmaritalstatus[string-length(.) != 0]">
                <xsl:sort data-type="text" order="descending" select="../absAdmitDate" />
                <xsl:if test="position() = 1">
                  <xsl:value-of select="." />
                </xsl:if>
              </xsl:for-each>
            </admmaritalstatus>
            <ClientID>
              <xsl:for-each select="PatientDemographics/ClientID[string-length(.) != 0]">
                <xsl:sort data-type="text" order="descending" select="../absAdmitDate" />
                <xsl:if test="position() = 1">
                  <xsl:value-of select="." />
                </xsl:if>
              </xsl:for-each>
            </ClientID>
          </PatientDemographics>
          <xsl:for-each select="Charge">
            <xsl:copy-of select="." />
          </xsl:for-each>
          <xsl:copy-of select="Guarantor" />
          <xsl:copy-of select="DiagnosisCodes" />
          <xsl:copy-of select="Insurance1" />
          <xsl:copy-of select="Insurance2" />
          <xsl:copy-of select="Insurance3" />
        </Group>
      </xsl:for-each>
    </XSCData>
  </xsl:template>
</xsl:stylesheet>

