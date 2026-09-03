<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:err="http://www.pilotfishtechnology.com/eip/RouteErrorReport" xmlns:ns1="http://pilotfish.sqlxml" version="3.1">
  <xsl:param name="UniqueControlID" />
  <xsl:param name="MSHGUID" />
  <xsl:template match="err:errorReport">
    <ns1:SQLXML>
      <ns1:Insert>
        <PilotFish_ErrorLog>
          <Error_Message>
            <xsl:value-of select="err:rootExceptionMessage" />
          </Error_Message>
          <!--1 - TIMEOUT-->
          <!--2 - JAVA-->
          <Error_Type>
            <xsl:choose>
              <xsl:when test="contains(err:exceptionTrace,'timeout')">TIMEOUT</xsl:when>
              <xsl:otherwise>JAVA</xsl:otherwise>
            </xsl:choose>
          </Error_Type>
          <Error_Exception>
            <xsl:value-of select="err:exceptionTrace" />
          </Error_Exception>
          <ET_TRANS_ID>
            <xsl:value-of select="$UniqueControlID" />
          </ET_TRANS_ID>
          <Creation_Date />
        </PilotFish_ErrorLog>
      </ns1:Insert>
      <ns1:Execute>
        <ns1:SQL>UPDATE PilotFish_HL7_Log SET HL7_SEND_STATUS = -1, AV_ACCEPTED_DATE = GETDATE() WHERE PF_CONTROL_ID = ?</ns1:SQL>
        <ns1:Params>
          <xsl:value-of select="$MSHGUID" />
        </ns1:Params>
      </ns1:Execute>
    </ns1:SQLXML>
  </xsl:template>
</xsl:stylesheet>

