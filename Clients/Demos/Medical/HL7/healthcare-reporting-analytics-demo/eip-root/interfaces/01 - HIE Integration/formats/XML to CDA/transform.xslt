<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:template match="/patients">
    <ClinicalDocument xmlns="urn:hl7-org:v3" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <realmCode code="US" />
      <typeId extension="POCD_HD000040" root="2.16.840.1.113883.1.3" />
      <templateId extension="IMPL_CDAR2_LEVEL1" root="2.16.840.1.113883.10" />
      <templateId root="2.16.840.1.113883.10.20.22.1.1" />
      <templateId root="2.16.840.1.113883.10.20.22.1.8" />
      <id extension="0" root="1.3.6.1.4.1.22812.11.0.100610.1" />
      <code code="18842-5" codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" displayName="DISCHARGE SUMMARIZATION NOTE" />
      <title>Patient Summary</title>
      <effectiveTime value="20130617091404-0400" />
      <confidentialityCode code="N" codeSystem="2.16.840.1.113883.5.25" />
      <languageCode code="en-US" />
      <recordTarget>
        <patientRole>
          <id extension="101693" root="1.3.6.1.4.1.22812.11.0.100610">
            <xsl:value-of select="patient/mrn" />
          </id>
          <addr nullFlavor="UNK">
            <streetAddressLine nullFlavor="UNK">
              <xsl:value-of select="patient/address" />
            </streetAddressLine>
            <city nullFlavor="UNK">
              <xsl:value-of select="patient/city" />
            </city>
            <state nullFlavor="UNK">
              <xsl:value-of select="patient/state" />
            </state>
            <postalCode nullFlavor="UNK">
              <xsl:value-of select="patient/postalCode" />
            </postalCode>
            <country nullFlavor="UNK" />
          </addr>
          <telecom nullFlavor="UNK" />
          <patient>
            <name use="L">
              <family>
                <xsl:value-of select="patient/lastName" />
              </family>
              <given>
                <xsl:value-of select="patient/firstName" />
              </given>
              <given>CCDA</given>
            </name>
            <birthTime value="{patient/dob}" />
          </patient>
        </patientRole>
      </recordTarget>
    </ClinicalDocument>
  </xsl:template>
</xsl:stylesheet>

