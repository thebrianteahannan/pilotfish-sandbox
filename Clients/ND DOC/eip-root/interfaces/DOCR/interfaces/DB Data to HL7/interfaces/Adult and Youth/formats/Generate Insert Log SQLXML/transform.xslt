<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:datetime="http://exslt.org/dates-and-times" xmlns:ns1="http://pilotfish.sqlxml" xmlns:uuid="java:java.util.UUID" exclude-result-prefixes="datetime" version="3.1">
  <xsl:param name="EventType" />
  <xsl:param name="HL7Type" />
  <xsl:param name="Status" />
  <xsl:param name="UniqueControlID" />
  <xsl:param name="MSHGUID" />
  <xsl:param name="HL7Data" />
  <xsl:param name="SequenceNo" />
  <xsl:param name="SetNo" />
  <xsl:template match="/">
    <ns1:SQLXML>
      <ns1:Insert>
        <PilotFish_HL7_Log>
          <PF_CONTROL_ID>
            <xsl:value-of select="$MSHGUID" />
          </PF_CONTROL_ID>
          <!--leave blank and it will put GETDATE() in when inserted by the db-->
          <CREATION_DATE>
            <xsl:value-of select="substring-before(replace(datetime:dateTime(),'T',' '),'.')" />
          </CREATION_DATE>
          <INTERFACE_MODE>
            <xsl:value-of select="'T'" />
          </INTERFACE_MODE>
          <MESSAGE_TYPE>
            <xsl:value-of select="$HL7Type" />
          </MESSAGE_TYPE>
          <ET_TRANS_ID>
            <xsl:value-of select="$UniqueControlID" />
          </ET_TRANS_ID>
          <AV_ACCEPTED_DATE>
            <!--blank to start then will get updated after send-->
          </AV_ACCEPTED_DATE>
          <SEQUENCE_NO>
            <xsl:value-of select="$SequenceNo" />
          </SEQUENCE_NO>
          <SET_NO>
            <xsl:value-of select="$SetNo" />
          </SET_NO>
          <HL7_DATA>
            <xsl:value-of select="$HL7Data" />
          </HL7_DATA>
          <HL7_SEND_STATUS>
            <xsl:value-of select="'0'" />
          </HL7_SEND_STATUS>
          <AV_FILING_EXCEPTIONS />
          <AV_FILING_STATUS>
            <!--defaults to zero-->
          </AV_FILING_STATUS>
        </PilotFish_HL7_Log>
      </ns1:Insert>
    </ns1:SQLXML>
  </xsl:template>
</xsl:stylesheet>

