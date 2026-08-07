<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:converter="xalan://com.pilotfish.eip.transform.ConverterProxy" xmlns:ns1="http://pilotfish.sqlxml" xmlns:ns2="http://ACORD.org/Standards/Life/2" exclude-result-prefixes="converter" extension-element-prefixes="converter" version="1.0">
  <xsl:template match="/ns2:TXLife">
    <converter:register class="com.pilotfish.eip.transform.converters.EchoConverter" name="EchoConverter" params="EchoField">
      <Mode>Echo</Mode>
    </converter:register>
    <ns1:SQLXML>
      <ns1:Execute as="results" into="results">
        <ns1:SQL>select TRACKING_ID, REMOTE_ID, REMOTE_NO
								from ACCORD_XML
								where REMOTE_ID = ? and REMOTE_NO = ?</ns1:SQL>
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
        <ns1:Select as="results" into="results">
          <ACCORD_XML>
            <TRACKING_ID key="true">
              <xsl:value-of select="ns2:TXLifeRequest/ns2:OLifE/ns2:Holding/ns2:Policy/ns2:ApplicationInfo/ns2:TrackingID" />
            </TRACKING_ID>
            <REMOTE_ID />
            <REMOTE_NO />
          </ACCORD_XML>
        </ns1:Select>
        <ns1:Execute as="results" into="results">
          <ns1:SQL>select TOP 1 TRACKING_ID, REMOTE_ID, REMOTE_NO
								from ACCORD_XML
								where TRACKING_ID = ?  order by ORDER_DATE DESC</ns1:SQL>
          <ns1:Params>
            <xsl:value-of select="ns2:TXLifeRequest/ns2:OLifE/ns2:Holding/ns2:Policy/ns2:ApplicationInfo/ns2:TrackingID" />
          </ns1:Params>
        </ns1:Execute>
        <!-- <ns1:If test="#results.getFieldValue('REMOTE_ID')!=null &amp;&amp; !'[Record Variable]'.equals(#results.getFieldValue('REMOTE_ID'))"> -->
        <ns1:If test="#results.getRecords().length &gt; 0">
          <ns1:XMLOut var="results" />
        </ns1:If>
        <!-- <ns1:If test="#results.getFieldValue('REMOTEID')==null || '[Record Variable]'.equals(#results.getFieldValue('REMOTE_ID'))"> -->
        <ns1:If test="#results.getRecords().length == 0">
          <ns1:Execute as="results" into="results">
            <ns1:SQL>select TOP 1 a.REMOTE_ID as REMOTE_ID, a.REMOTE_NO as REMOTE_NO, b.TRACKING_ID as TRACKING_ID
								from WR_ORDERS a left join ACCORD_XML b
								on a.REMOTE_ID = b.REMOTE_ID and a.REMOTE_NO = b.REMOTE_NO
								where a.POLICY=? order by b.ORDER_DATE DESC, a.ORDER_DATE desc</ns1:SQL>
            <ns1:Params>
              <xsl:value-of select="ns2:TXLifeRequest/ns2:OLifE/ns2:Holding/ns2:Policy/ns2:PolNumber" />
            </ns1:Params>
          </ns1:Execute>
          <ns1:XMLOut var="results" />
        </ns1:If>
      </ns1:If>
    </ns1:SQLXML>
  </xsl:template>
</xsl:stylesheet>

