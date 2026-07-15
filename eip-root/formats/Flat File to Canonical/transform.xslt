<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:param name="softwareID" />
  <xsl:template match="/XCSData">
    <Import>
      <xsl:for-each select="Patient-Demographics">
        <PatientDemographics>
          <admAcctNum>
            <xsl:value-of select="cpcs-account-" />
          </admAcctNum>
          <absAdmitdate>
            <xsl:value-of select="cpcs-adm-ser-date" />
          </absAdmitdate>
          <admname>
            <xsl:value-of select="cpcs-name-full" />
          </admname>
          <admstreet>
            <xsl:value-of select="cpcs-street" />
          </admstreet>
          <admstreet2>
            <xsl:value-of select="cpcs-street-2" />
          </admstreet2>
          <admpatcity>
            <xsl:value-of select="cpcs-city" />
          </admpatcity>
          <admpatstate>
            <xsl:value-of select="cpcs-state" />
          </admpatstate>
          <admzipcode>
            <xsl:value-of select="cpcs-zip-code" />
          </admzipcode>
          <admpatsex>
            <xsl:value-of select="cpcs-sex" />
          </admpatsex>
          <admbirthdate>
            <xsl:value-of select="cpcs-birthdate" />
          </admbirthdate>
          <admpatienttype>
            <xsl:value-of select="cpcs-patient-status" />
          </admpatienttype>
          <admFinClass>
            <xsl:value-of select="cpcs-fin-class" />
          </admFinClass>
          <admpatphone>
            <xsl:value-of select="cpcs-phone" />
          </admpatphone>
          <admssn>
            <xsl:value-of select="cpcs-ss-number" />
          </admssn>
          <xsl:choose>
            <xsl:when test="$softwareID = ('283', '284', '285')">
              <absattendingdocname>
                <xsl:value-of select="cpcs-attend-doc-name" />
              </absattendingdocname>
              <absattendingdocmnem>
                <xsl:value-of select="cpcs-attend-doc-mnem" />
              </absattendingdocmnem>
              <absattendingdocupin>
                <xsl:value-of select="cpcs-attend-doc-upin" />
              </absattendingdocupin>
              <absattendingdocNPI>
                <xsl:value-of select="cpcs-attend-doc-npi" />
              </absattendingdocNPI>
            </xsl:when>
            <xsl:when test="$softwareID = '260'">
              <absattendingdocname>
                <xsl:value-of select="concat(substring(adm-er-doc, 8), substring(adm-er-doc-name, 1, 20))" />
              </absattendingdocname>
              <absattendingdocmnem>
                <xsl:value-of select="adm-er-doc-npi" />
              </absattendingdocmnem>
            </xsl:when>
            <xsl:otherwise>
              <absattendingdocname>
                <xsl:value-of select="cpcs-attend-doc-name" />
              </absattendingdocname>
              <absattendingdocmnem>
                <xsl:value-of select="cpcs-attend-doc-mnem" />
              </absattendingdocmnem>
              <absattendingdocupin>
                <xsl:value-of select="cpcs-attend-doc-upin" />
              </absattendingdocupin>
              <xsl:if test="string-length(cpcs-attend-doc-npi) &gt; 0">
                <AttendDrNPI>
                  <xsl:value-of select="cpcs-attend-doc-npi" />
                </AttendDrNPI>
                <RefDrNPI>
                  <xsl:value-of select="cpcs-refer-doc-npi" />
                </RefDrNPI>
                <ERDrNPI>
                  <xsl:value-of select="adm-er-doc-npi" />
                </ERDrNPI>
              </xsl:if>
            </xsl:otherwise>
          </xsl:choose>
          <admOccurrenceCode>
            <xsl:value-of select="cpcs-ub82-code" />
          </admOccurrenceCode>
          <absdischargedate>
            <xsl:value-of select="cpcs-dischg-date" />
          </absdischargedate>
          <admaccidentdate>
            <xsl:value-of select="cpcs-accident-date" />
          </admaccidentdate>
          <admemplphone>
            <xsl:value-of select="substring(cpcs-filler03, 4, 25)" />
          </admemplphone>
          <absadmitdiag>
            <xsl:value-of select="cpcs-admit-dx" />
          </absadmitdiag>
          <admLocation>
            <xsl:value-of select="adm-location" />
          </admLocation>
          <radrefphyname>
            <xsl:value-of select="cpcs-refer-doc-name" />
          </radrefphyname>
          <radrefphymne>
            <xsl:value-of select="cpcs-refer-doc-mnem" />
          </radrefphymne>
          <radrefphyupin>
            <xsl:value-of select="cpcs-refer-doc-upin" />
          </radrefphyupin>
          <absPatientUnit>
            <xsl:value-of select="cpcs-unit-number" />
          </absPatientUnit>
          <reflabBillType>
            <xsl:value-of select="cpcs-filler09" />
          </reflabBillType>
          <Filler2>
            <xsl:value-of select="adm-client-mnem" />
          </Filler2>
          <admemplname>
            <xsl:value-of select="cpcs-emp-name-out" />
          </admemplname>
          <admemplstreet>
            <xsl:value-of select="cpcs-emp-street" />
          </admemplstreet>
          <admemplcity>
            <xsl:value-of select="cpcs-emp-city" />
          </admemplcity>
          <admemplstate>
            <xsl:value-of select="cpcs-emp-state" />
          </admemplstate>
          <admemplzip>
            <xsl:value-of select="cpcs-emp-zip-code" />
          </admemplzip>
          <ChiefComplaint>
            <xsl:value-of select="adm-visit-reason" />
          </ChiefComplaint>
        </PatientDemographics>
      </xsl:for-each>
      <xsl:for-each select="Insurance-1">
        <Insurance1>
          <admAcctNum>
            <xsl:value-of select="cpcs-account-" />
          </admAcctNum>
          <adminsmne>
            <xsl:value-of select="cpcs-ins1-mnem" />
          </adminsmne>
          <admInsName>
            <xsl:value-of select="cpcs-ins1-zcus-name" />
          </admInsName>
          <adminsstreet>
            <xsl:value-of select="cpcs-ins1-street" />
          </adminsstreet>
          <adminscity>
            <xsl:value-of select="cpcs-ins1-city" />
          </adminscity>
          <adminsstate>
            <xsl:value-of select="cpcs-ins1-state" />
          </adminsstate>
          <adminszip>
            <xsl:value-of select="cpcs-ins1-zip-code" />
          </adminszip>
          <admInsPhone>
            <xsl:value-of select="cpcs-ins1-phone" />
          </admInsPhone>
          <adminsinsuredname>
            <xsl:value-of select="cpcs-ins1-insured" />
          </adminsinsuredname>
          <adminsinsuredrel>
            <xsl:value-of select="cpcs-ins1-relation" />
          </adminsinsuredrel>
          <absPatientUnit>
            <xsl:value-of select="cpcs-unit-number" />
          </absPatientUnit>
          <adminstreatmentauth>
            <xsl:value-of select="cpcs-filler01" />
          </adminstreatmentauth>
          <adminsPaCode>
            <xsl:value-of select="cpcs-ins1-pa-code" />
          </adminsPaCode>
          <adminsgroup>
            <xsl:value-of select="cpcs-ins1-group-" />
          </adminsgroup>
          <adminspolicy>
            <xsl:value-of select="cpcs-ins1-policy-" />
          </adminspolicy>
        </Insurance1>
      </xsl:for-each>
      <xsl:for-each select="Insurance-2">
        <Insurance2>
          <admAcctNum>
            <xsl:value-of select="cpcs-account-" />
          </admAcctNum>
          <adminsmne>
            <xsl:value-of select="cpcs-ins2-mnem" />
          </adminsmne>
          <admInsName>
            <xsl:value-of select="cpcs-ins2-zcus-name" />
          </admInsName>
          <adminsstreet>
            <xsl:value-of select="cpcs-ins2-street" />
          </adminsstreet>
          <adminscity>
            <xsl:value-of select="cpcs-ins2-city" />
          </adminscity>
          <adminsstate>
            <xsl:value-of select="cpcs-ins2-state" />
          </adminsstate>
          <adminszip>
            <xsl:value-of select="cpcs-ins2-zip-code" />
          </adminszip>
          <admInsPhone>
            <xsl:value-of select="cpcs-ins2-phone" />
          </admInsPhone>
          <adminsinsuredname>
            <xsl:value-of select="cpcs-ins2-insured" />
          </adminsinsuredname>
          <adminsinsuredrel>
            <xsl:value-of select="cpcs-ins2-relation" />
          </adminsinsuredrel>
          <absPatientUnit>
            <xsl:value-of select="cpcs-unit-number" />
          </absPatientUnit>
          <adminstreatmentauth>
            <xsl:value-of select="cpcs-filler01" />
          </adminstreatmentauth>
          <adminsPaCode>
            <xsl:value-of select="cpcs-ins2-pa-code" />
          </adminsPaCode>
          <adminsgroup>
            <xsl:value-of select="cpcs-ins2-group-" />
          </adminsgroup>
          <adminspolicy>
            <xsl:value-of select="cpcs-ins2-policy-" />
          </adminspolicy>
        </Insurance2>
      </xsl:for-each>
      <xsl:for-each select="Insurance-3">
        <Insurance3>
          <admAcctNum>
            <xsl:value-of select="cpcs-account-" />
          </admAcctNum>
          <adminsmne>
            <xsl:value-of select="cpcs-ins3-mnem" />
          </adminsmne>
          <admInsName>
            <xsl:value-of select="cpcs-ins3-zcus-name" />
          </admInsName>
          <adminsstreet>
            <xsl:value-of select="cpcs-ins3-street" />
          </adminsstreet>
          <adminscity>
            <xsl:value-of select="cpcs-ins3-city" />
          </adminscity>
          <adminsstate>
            <xsl:value-of select="cpcs-ins3-state" />
          </adminsstate>
          <adminszip>
            <xsl:value-of select="cpcs-ins3-zip-code" />
          </adminszip>
          <admInsPhone>
            <xsl:value-of select="cpcs-ins3-phone" />
          </admInsPhone>
          <adminsinsuredname>
            <xsl:value-of select="cpcs-ins3-insured" />
          </adminsinsuredname>
          <adminsinsuredrel>
            <xsl:value-of select="cpcs-ins3-relation" />
          </adminsinsuredrel>
          <absPatientUnit>
            <xsl:value-of select="cpcs-unit-number" />
          </absPatientUnit>
          <adminstreatmentauth>
            <xsl:value-of select="cpcs-filler01" />
          </adminstreatmentauth>
          <adminsPaCode>
            <xsl:value-of select="cpcs-ins3-pa-code" />
          </adminsPaCode>
          <adminsgroup>
            <xsl:value-of select="cpcs-ins3-group-" />
          </adminsgroup>
          <adminspolicy>
            <xsl:value-of select="cpcs-ins3-policy-" />
          </adminspolicy>
        </Insurance3>
      </xsl:for-each>
      <xsl:for-each select="Guarantor">
        <Guarantor>
          <admAcctNum>
            <xsl:value-of select="cpcs-account-" />
          </admAcctNum>
          <admGuarName>
            <xsl:value-of select="cpcs-guar-name" />
          </admGuarName>
          <admGuarAddr1>
            <xsl:value-of select="cpcs-guar-street" />
          </admGuarAddr1>
          <admGuarAddr2>
            <xsl:value-of select="cpcs-guar-street-2" />
          </admGuarAddr2>
          <admGuarCity>
            <xsl:value-of select="cpcs-guar-city" />
          </admGuarCity>
          <admGuarState>
            <xsl:value-of select="cpcs-guar-state" />
          </admGuarState>
          <admGuarZip>
            <xsl:value-of select="cpcs-guar-zip-code" />
          </admGuarZip>
          <admGuarHomePhone>
            <xsl:value-of select="cpcs-guar-phone" />
          </admGuarHomePhone>
          <admGuarEmployer>
            <xsl:value-of select="cpcs-guar-emp-nam-v2" />
          </admGuarEmployer>
          <admGuarEmplAddr1>
            <xsl:value-of select="cpcs-guar-emp-addr" />
          </admGuarEmplAddr1>
          <admGuarEmplAddr2>
            <xsl:value-of select="cpcs-guar-emp-addr-2" />
          </admGuarEmplAddr2>
          <admGuarEmplCity>
            <xsl:value-of select="cpcs-guar-emp-city" />
          </admGuarEmplCity>
          <admGuarEmplState>
            <xsl:value-of select="cpcs-guar-emp-state" />
          </admGuarEmplState>
          <admGuarEmplZip>
            <xsl:value-of select="cpcs-guar-emp-zip" />
          </admGuarEmplZip>
          <admGuarEmplPhone>
            <xsl:value-of select="cpcs-guar-emp-phone" />
          </admGuarEmplPhone>
          <admGuarSSN>
            <xsl:value-of select="cpcs-guar-ss-num" />
          </admGuarSSN>
          <admGuarRel>
            <xsl:value-of select="cpcs-guar-relation" />
          </admGuarRel>
          <admPatientUnit>
            <xsl:value-of select="cpcs-unit-number" />
          </admPatientUnit>
          <npr1 />
        </Guarantor>
      </xsl:for-each>
      <xsl:for-each select="Charge-Record">
        <Charge>
          <radAcctNum>
            <xsl:value-of select="cpcs-chg-pat-acct-" />
          </radAcctNum>
          <radExamServDate>
            <xsl:value-of select="cpcs-chg-ser-date" />
          </radExamServDate>
          <radExamBillingCode>
            <xsl:value-of select="cpcs-chg-bill-code" />
          </radExamBillingCode>
          <radStatus>
            <xsl:value-of select="cpcs-chg-status" />
          </radStatus>
          <radCRDBIndicator>
            <xsl:value-of select="cpcs-chg-creddebit" />
          </radCRDBIndicator>
          <radPatientName>
            <xsl:value-of select="cpcs-chg-pat-name" />
          </radPatientName>
          <radExamLocation />
          <xsl:value-of select="rad-exam-campus" />
          <radOrderingPhyMne>
            <xsl:value-of select="cpcs-chg-ord-dc-mnem" />
          </radOrderingPhyMne>
          <misOrderingPhyName>
            <xsl:value-of select="cpcs-chg-ord-dc-name" />
          </misOrderingPhyName>
          <misOrderingPhyAddr>
            <xsl:value-of select="cpcs-chg-ord-dc-addr" />
          </misOrderingPhyAddr>
          <misOrderingPhyCity>
            <xsl:value-of select="cpcs-chg-ord-dc-city" />
          </misOrderingPhyCity>
          <radOrderingPhyUPIN>
            <xsl:value-of select="cpcs-chg-ord-dc-upin" />
          </radOrderingPhyUPIN>
          <radOrderingPhyLic>
            <xsl:value-of select="cpcs-ord-doc-dft-lic" />
          </radOrderingPhyLic>
          <radExamPerformingPhyMne>
            <xsl:value-of select="cpcs-chg-per-dc-mnem" />
          </radExamPerformingPhyMne>
          <misPerfPhyName>
            <xsl:value-of select="cpcs-chg-per-dc-name" />
          </misPerfPhyName>
          <misPerfPhyAddr>
            <xsl:value-of select="cpcs-chg-per-dc-addr" />
          </misPerfPhyAddr>
          <misPerfPhyLic>
            <xsl:value-of select="cpcs-per-doc-dft-lic" />
          </misPerfPhyLic>
          <misPerfPhyCity>
            <xsl:value-of select="cpcs-chg-per-dc-city" />
          </misPerfPhyCity>
          <radPerfPhyUPIN>
            <xsl:value-of select="cpcs-chg-per-dc-upin" />
          </radPerfPhyUPIN>
          <radExamCPT>
            <xsl:value-of select="cpcs-chg-cpt-code" />
          </radExamCPT>
          <radExamDept>
            <xsl:value-of select="cpcs-chg-dept" />
          </radExamDept>
          <radNumOfTimes>
            <xsl:value-of select="cpcs-chg-quantity" />
          </radNumOfTimes>
          <absPatientUnit>
            <xsl:value-of select="cpcs-unit-number" />
          </absPatientUnit>
          <ExamApplication>
            <xsl:value-of select="cpcs-chg-mtech-appl" />
          </ExamApplication>
          <examdesc>
            <xsl:value-of select="cpcs-chg-desc" />
          </examdesc>
          <radExamNumber>
            <xsl:value-of select="cpcs-chg-rad-exam-" />
          </radExamNumber>
          <ExamHCPCCode>
            <xsl:value-of select="cpcs-chg-hcpc-code" />
          </ExamHCPCCode>
          <ExamCharge>
            <xsl:value-of select="cpcs-chg-bill-date" />
          </ExamCharge>
          <ExamBillDate />
          <FileName />
        </Charge>
      </xsl:for-each>
      <xsl:for-each select="Diagnosis-Codes">
        <DiagnosisCodes>
          <radAcctNum>
            <xsl:value-of select="cpcs-account-" />
          </radAcctNum>
          <Diag1>
            <xsl:value-of select="cpcs-dischg-dx-1" />
          </Diag1>
          <Diag1CodeSet>
            <xsl:value-of select="cpcs-dischg-dx-1-nam" />
          </Diag1CodeSet>
          <Diag2>
            <xsl:value-of select="cpcs-dischg-dx-2" />
          </Diag2>
          <Diag3>
            <xsl:value-of select="cpcs-dischg-dx-3" />
          </Diag3>
          <Diag4>
            <xsl:value-of select="cpcs-dischg-dx-4" />
          </Diag4>
          <Diag5>
            <xsl:value-of select="cpcs-dischg-dx-5" />
          </Diag5>
          <Diag6>
            <xsl:value-of select="cpcs-dischg-dx-6" />
          </Diag6>
          <Diag7>
            <xsl:value-of select="cpcs-dischg-dx-7" />
          </Diag7>
          <Diag8>
            <xsl:value-of select="cpcs-dischg-dx-8" />
          </Diag8>
          <Diag9>
            <xsl:value-of select="cpcs-dischg-dx-9" />
          </Diag9>
          <Diag10>
            <xsl:value-of select="cpcs-rfv-dx-1" />
          </Diag10>
          <Diag11>
            <xsl:value-of select="cpcs-rfv-dx-2" />
          </Diag11>
          <Diag12>
            <xsl:value-of select="cpcs-rfv-dx-3" />
          </Diag12>
          <FileName />
        </DiagnosisCodes>
      </xsl:for-each>
    </Import>
  </xsl:template>
</xsl:stylesheet>

