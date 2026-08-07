<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:converter="xalan://com.pilotfish.eip.transform.ConverterProxy" xmlns:ns1="http://pilotfish.sqlxml" exclude-result-prefixes="converter" extension-element-prefixes="converter" version="1.0">
  <xsl:template match="/">
    <converter:register class="com.pilotfish.eip.transform.converters.EchoConverter" name="EchoConverter" params="EchoField">
      <Mode>Echo</Mode>
    </converter:register>
    <ns1:SQLXML>
      <!-- DO THE INSERTING OF THE 121 ORIGINAL TEXT INTO THE TRANSACTION_TEXT TABLE -->
      <ns1:Insert>
        <TRANSACTION_TEXT>
          <ORIGINAL_TXT>
            <xsl:value-of select="converter:getAttributeString('Incoming121XMLEscaped')" />
          </ORIGINAL_TXT>
          <ORIGINAL_TYPE>121</ORIGINAL_TYPE>
        </TRANSACTION_TEXT>
      </ns1:Insert>
      <!-- NOW THAT WE'VE INSERTED THE ORIGINAL TRANSACTION TEXT INTO THE DATABASE, LET'S GET THAT NEW ROW'S SEQUENCE NUMBER FOR USE LATER -->
      <ns1:Execute into="results">
        <ns1:SQL>SELECT TRANSACTION_TEXT_SEQ.CURRVAL AS CURR_TRANSACTION_TEXT_ID FROM TRANSACTION_TEXT WHERE ROWNUM &lt;= 1</ns1:SQL>
      </ns1:Execute>
      <ns1:XMLOut var="results" />
    </ns1:SQLXML>
  </xsl:template>
</xsl:stylesheet>

