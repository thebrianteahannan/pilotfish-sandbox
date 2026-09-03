<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:dtFormatter="xalan://com.pilotfish.eip.gui.mapper.util.DateTimeFormatter" exclude-result-prefixes="dtFormatter" version="3.1">
  <xsl:template match="/XCSData">
    <patients>
      <xsl:for-each select="*">
        <patient>
          <mrn>
            <xsl:value-of select="//PID_Patient_identification_segment/PID.3_Patient_Identifier_List/CX.5_identifier_type_code" />
          </mrn>
          <lastName>
            <xsl:value-of select="//PID_Patient_identification_segment/PID.5_Patient_Name/XPN.1_family_name" />
          </lastName>
          <firstName>
            <xsl:value-of select="//PID_Patient_identification_segment/PID.5_Patient_Name/XPN.2_given_name" />
          </firstName>
          <dob>
            <xsl:value-of select="dtFormatter:format(//PID_Patient_identification_segment/PID.7_Date_Time_of_Birth,'yyyyMMdd','yyyy-MM-dd')" />
          </dob>
          <address>
            <xsl:value-of select="//PID_Patient_identification_segment/PID.11_Patient_Address/XAD.1_street_address" />
          </address>
          <city>
            <xsl:value-of select="//PID_Patient_identification_segment/PID.11_Patient_Address/XAD.3_city" />
          </city>
          <state>
            <xsl:value-of select="//PID_Patient_identification_segment/PID.11_Patient_Address/XAD.4_state_or_province" />
          </state>
          <postalCode>
            <xsl:value-of select="//PID_Patient_identification_segment/PID.11_Patient_Address/XAD.5_zip_or_postal_code" />
          </postalCode>
        </patient>
      </xsl:for-each>
    </patients>
  </xsl:template>
</xsl:stylesheet>

