<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:converter="xalan://com.pilotfish.eip.transform.ConverterProxy" xmlns:ns1="http://pilotfish.sqlxml" exclude-result-prefixes="converter" extension-element-prefixes="converter" version="1.0">
  <xsl:template match="/INCOMING103IMAGE">
    <converter:register class="com.pilotfish.eip.transform.converters.EchoConverter" name="EchoConverter" params="EchoField">
      <Mode>Echo</Mode>
    </converter:register>
    <ns1:SQLXML>
      <ns1:Execute as="results" into="results">
        <ns1:SQL>select max(TRANSACTION_ID) as TRANSACTION_ID, max(FLOWNET_ORDER_NUM) as FLOWNET_ORDER_NUM 
						from CRLTRANSACTION 
						WHERE TELEDEX_REMOTE_ID=? AND TELEDEX_ORDER_NUM=? and FLOWNET_ORDER_NUM&lt;&gt;'INVALID'</ns1:SQL>
        <!--REMOTE_ID-->
        <ns1:Params>
          <xsl:value-of select="REMOTE_ID" />
        </ns1:Params>
        <!--REMOTE_NO-->
        <ns1:Params>
          <xsl:value-of select="REMOTE_NO" />
        </ns1:Params>
      </ns1:Execute>
      <ns1:If test="#results.getRecords().length &gt; 0 &amp;&amp; #results.getRecords()[0].getFieldValue('FLOWNET_ORDER_NUM')!=null">
        <!-- <ns1:If test="#results.getFieldValue('FLOWNET_ORDER_NUM')!=null &amp;&amp; !'[Record Variable]'.equals(#results.getFieldValue('FLOWNET_ORDER_NUM'))"> -->
        <ns1:XMLOut var="results" />
      </ns1:If>
      <ns1:If test="#results.getRecords().length == 0 || #results.getRecords()[0].getFieldValue('FLOWNET_ORDER_NUM')==null">
        <!-- <ns1:If test="#results.getFieldValue('FLOWNET_ORDER_NUM')==null || '[Record Variable]'.equals(#results.getFieldValue('FLOWNET_ORDER_NUM'))"> -->
        <ns1:Execute as="results" into="results">
          <ns1:SQL>SELECT  max(t.TRANSACTION_ID) as TRANSACTION_ID, max(t.FLOWNET_ORDER_NUM) as FLOWNET_ORDER_NUM 
						FROM CRLTRANSACTION t, POLICY p
						WHERE t.TRANSACTION_ID=p.TRANSACTION_ID AND p.POLNUMBER=? AND t.FLOWNET_ORDER_NUM&lt;&gt;'INVALID'</ns1:SQL>
          <!--POLICY-->
          <ns1:Params>
            <xsl:value-of select="POLICY" />
          </ns1:Params>
        </ns1:Execute>
        <ns1:XMLOut var="results" />
      </ns1:If>
    </ns1:SQLXML>
  </xsl:template>
</xsl:stylesheet>

