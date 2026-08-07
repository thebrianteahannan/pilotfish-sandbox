<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:converter="xalan://com.pilotfish.eip.transform.ConverterProxy" xmlns:sql="http://pilotfish.sqlxml" exclude-result-prefixes="converter" extension-element-prefixes="converter" version="1.0">
  <xsl:template match="/">
    <converter:register class="com.pilotfish.eip.transform.converters.EchoConverter" name="EchoConverter" params="EchoField,SuppressValue">
      <Mode>Store</Mode>
      <UseEchoPrefix>False</UseEchoPrefix>
    </converter:register>
    <sql:SQLXML>
      <sql:Execute as="RECORD" into="RESULTS">
        <SQL>select max(TRANSREFGUID) from CRLTRANSACTION where TRANSREFGUID like ?</SQL>
        <Params>
          <xsl:value-of select="//TransRefGUIDPattern" />
        </Params>
      </sql:Execute>
      <sql:XMLOut var="RESULTS" />
      <converter:convert EchoField="TransRefPattern" SuppressValue="true" name="EchoConverter">
        <xsl:value-of select="//TransRefGUIDPattern" />
      </converter:convert>
    </sql:SQLXML>
  </xsl:template>
</xsl:stylesheet>

