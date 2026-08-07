<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:converter="xalan://com.pilotfish.eip.transform.ConverterProxy" xmlns:ns1="http://pilotfish.sqlxml" xmlns:ns2="http://ACORD.org/Standards/Life/2" exclude-result-prefixes="converter" extension-element-prefixes="converter" version="1.0">
  <xsl:template match="/ns2:TXLife">
    <converter:register class="com.pilotfish.eip.transform.converters.EchoConverter" name="EchoConverter" params="EchoField">
      <Mode>Echo</Mode>
    </converter:register>
    <ns1:SQLXML>
      <ns1:Execute as="results" into="results">
        <ns1:SQL>select a.BR_ORDNO, a.REMOTE_ID, a.REMOTE_NO, o.POLICY, '1' as QUERY
from WR_BRCHORD a, WR_ORDERS o 
where a.REMOTE_ID=? and a.REMOTE_NO=? and o.REMOTE_NO=a.REMOTE_NO and o.REMOTE_ID=a.REMOTE_ID</ns1:SQL>
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexRemoteID')" />
        </ns1:Params>
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexOrderNumber')" />
        </ns1:Params>
      </ns1:Execute>
      <!-- <ns1:If test="#results.getFieldValue('TRACKING_ID')!=null &amp;&amp; !'[Record Variable]'.equals(#results.getFieldValue('TRACKING_ID'))"> -->
      <ns1:If test="#results.getRecords().length &gt; 0">
        <ns1:XMLOut var="results" />
      </ns1:If>
      <!-- <ns1:If test="#results.getFieldValue('TRACKING_ID')==null || '[Record Variable]'.equals(#results.getFieldValue('TRACKING_ID'))"> -->
      <ns1:If test="#results.getRecords().length == 0">
        <ns1:Execute as="results" into="results">
          <ns1:SQL>select TOP 1 a.BR_ORDNO, a.REMOTE_ID, a.REMOTE_NO, o.POLICY, '2' as QUERY 
from WR_BRCHORD a, WR_ORDERS o 
where o.POLICY=? and o.REMOTE_NO=a.REMOTE_NO and o.REMOTE_ID=a.REMOTE_ID
order by o.ORDER_DATE desc</ns1:SQL>
          <ns1:Params>
            <xsl:value-of select="ns2:TXLifeRequest/ns2:OLifE/ns2:Holding/ns2:Policy/ns2:PolNumber" />
          </ns1:Params>
        </ns1:Execute>
        <ns1:XMLOut var="results" />
      </ns1:If>
    </ns1:SQLXML>
  </xsl:template>
</xsl:stylesheet>

