<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" indent="yes" encoding="UTF-8"/>
  <xsl:variable name="d" select="(//AuthDecision | /AuthDecision)[1]"/>
  <xsl:variable name="trace" select="normalize-space(($d/AuthTraceNumber)[1])"/>
  <xsl:variable name="disp" select="upper-case(normalize-space(($d/Disposition)[1]))"/>
  <xsl:template match="/">
    <XCSData>
      <ORU_R01>
        <MSH>
          <MSH.1>|</MSH.1>
          <MSH.2><xsl:text>^~\&amp;</xsl:text></MSH.2>
          <MSH.3>PILOTFISH</MSH.3>
          <MSH.4>AUTHDEMO</MSH.4>
          <MSH.5>EHR</MSH.5>
          <MSH.6>HOSPITAL</MSH.6>
          <MSH.7>20260813120000</MSH.7>
          <MSH.8/>
          <MSH.9>
            <MSG.1>ORU</MSG.1>
            <MSG.2>R01</MSG.2>
            <MSG.3>ORU_R01</MSG.3>
          </MSH.9>
          <MSH.10><xsl:value-of select="$trace"/></MSH.10>
          <MSH.11>P</MSH.11>
          <MSH.12>2.5.1</MSH.12>
        </MSH>
        <PID>
          <PID.1>1</PID.1>
          <PID.3>
            <CX.1><xsl:value-of select="($d/MemberId)[1]"/></CX.1>
            <CX.5>MR</CX.5>
          </PID.3>
          <PID.5>
            <XPN.1><xsl:value-of select="($d/PatientLastName)[1]"/></XPN.1>
            <XPN.2><xsl:value-of select="($d/PatientFirstName)[1]"/></XPN.2>
          </PID.5>
        </PID>
        <OBR>
          <OBR.1>1</OBR.1>
          <OBR.3>
            <EI.1><xsl:value-of select="$trace"/></EI.1>
          </OBR.3>
          <OBR.4>
            <CWE.1><xsl:value-of select="($d/ProcedureCode)[1]"/></CWE.1>
            <CWE.2>Prior auth decision</CWE.2>
          </OBR.4>
          <OBR.7>20260813120000</OBR.7>
          <OBR.25>F</OBR.25>
        </OBR>
        <OBX>
          <OBX.1>1</OBX.1>
          <OBX.2>TX</OBX.2>
          <OBX.3>
            <CWE.1>AUTH</CWE.1>
            <CWE.2>Authorization disposition</CWE.2>
          </OBX.3>
          <OBX.5><xsl:value-of select="$disp"/></OBX.5>
          <OBX.11>F</OBX.11>
        </OBX>
      </ORU_R01>
    </XCSData>
  </xsl:template>
</xsl:stylesheet>
