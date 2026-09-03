<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ns1="http://pilotfish.sqlxml" version="1.0">
  <xsl:template match="/XCSData">
    <ns1:SQLXML>
      <xsl:for-each select="ORU_R01_Unsolicited_transmission_of_an_observation_message/ORU_R01.PATIENT_RESULT/ORU_R01.ORDER_OBSERVATION/ORU_R01.OBSERVATION">
        <ns1:Insert>
          <RESULTS>
            <MRN>
              <xsl:value-of select="../../ORU_R01.PATIENT/PID_Patient_Identification/PID.3_Patient_Identifier_List/CX.1_ID_Number" />
            </MRN>
            <FIRST_NAME>
              <xsl:value-of select="../../ORU_R01.PATIENT/PID_Patient_Identification/PID.5_Patient_Name/XPN.2_Given_Name" />
            </FIRST_NAME>
            <LAST_NAME>
              <xsl:value-of select="../../ORU_R01.PATIENT/PID_Patient_Identification/PID.5_Patient_Name/XPN.1_Family_Name" />
            </LAST_NAME>
            <RESULT_CODE>
              <xsl:value-of select="OBX_Observation_Result/OBX.3_Observation_Identifier/CWE.1_Identifier" />
            </RESULT_CODE>
            <RESULT_NAME>
              <xsl:value-of select="OBX_Observation_Result/OBX.3_Observation_Identifier/CWE.2_Text" />
            </RESULT_NAME>
            <RESULT_VALUE>
              <xsl:value-of select="concat(OBX_Observation_Result/OBX.5_Observation_Value,OBX_Observation_Result/OBX.6_Units/CWE.1_Identifier)" />
            </RESULT_VALUE>
          </RESULTS>
        </ns1:Insert>
      </xsl:for-each>
    </ns1:SQLXML>
  </xsl:template>
</xsl:stylesheet>

