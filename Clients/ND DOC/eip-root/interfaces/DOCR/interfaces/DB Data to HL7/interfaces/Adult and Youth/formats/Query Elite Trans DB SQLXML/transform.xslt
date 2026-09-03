<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ns1="http://pilotfish.sqlxml" version="3.1">
  <xsl:template match="/">
    <ns1:SQLXML>
      <ns1:Execute as="event" into="recent_events">
        <ns1:SQL>SELECT * FROM Elite_Trans E WHERE NOT EXISTS (SELECT * FROM PilotFish_HL7_Log L WHERE L.ET_TRANS_ID = E.ET_TRANS_ID AND L.HL7_SEND_STATUS = 1)</ns1:SQL>
      </ns1:Execute>
      <ns1:XMLOut var="recent_events" />
    </ns1:SQLXML>
  </xsl:template>
</xsl:stylesheet>

