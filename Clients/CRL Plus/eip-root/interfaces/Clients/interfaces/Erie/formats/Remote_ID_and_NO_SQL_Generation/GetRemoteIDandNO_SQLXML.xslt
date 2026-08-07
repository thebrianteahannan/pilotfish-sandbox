<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:converter="xalan://com.pilotfish.eip.transform.ConverterProxy" xmlns:ns1="http://pilotfish.sqlxml" exclude-result-prefixes="converter" extension-element-prefixes="converter" version="1.0">
  <xsl:template match="/INCOMING103IMAGE">
    <converter:register class="com.pilotfish.eip.transform.converters.EchoConverter" name="EchoConverter" params="EchoField">
      <Mode>Echo</Mode>
    </converter:register>
    <ns1:SQLXML>
      <ns1:Execute as="results" into="results">
        <ns1:SQL>select max(a.REMOTE_ID) as REMOTE_ID, max(a.REMOTE_NO) as REMOTE_NO, max(o.POLICY) as POLICY 
				from WR_ATTACH a, WR_ORDERS o 
				where a.REMOTE_ID=o.REMOTE_ID and a.REMOTE_NO=o.REMOTE_NO and a.BR_ORDNO=?</ns1:SQL>
        <!-- TELEDEXNUM -->
        <ns1:Params>
          <xsl:value-of select="substring(TELEDEXNUM,1,6)" />
        </ns1:Params>
      </ns1:Execute>
      <ns1:XMLOut var="results" />
    </ns1:SQLXML>
  </xsl:template>
</xsl:stylesheet>

