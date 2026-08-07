<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:bo="http://ACORD.org/Standards/Life/2" xmlns:converter="xalan://com.pilotfish.eip.transform.ConverterProxy" xmlns:dyn="http://exslt.org/dynamic" xmlns:exsl="http://exslt.org/common" xmlns:java="http://xml.apache.org/xalan/java" xmlns:ns1="http://ACORD.org/Standards/Life/2" xmlns:ta="xalan://com.pilotfish.eip.TransactionAttributes" xmlns:td="xalan://com.pilotfish.eip.TransactionData" xmlns:util="xalan://com.pilotfish.custom.crlplus.Utils" exclude-result-prefixes="java converter util td ta dyn exsl" extension-element-prefixes="converter ta" version="1.0">
  <xsl:param name="eiPlatformTransactionData" />
  <xsl:template match="XCSData">
    <converter:register class="com.pilotfish.eip.transform.converters.EchoConverter" name="EchoConverter" params="EchoField">
      <Mode>Echo</Mode>
    </converter:register>
    <xsl:variable name="order">
      <xsl:variable name="ord" select="converter:getAttributeString('com.pilotfish.crl.original.txt')" />
      <xsl:variable name="Order" select="exsl:node-set(util:stringToNode($ord))" />
      <xsl:copy-of select="$Order" />
    </xsl:variable>
    <xsl:variable name="attributes" select="td:getAttributes($eiPlatformTransactionData)" />
    <xsl:choose>
      <xsl:when test="string-length(exsl:node-set($order)/ns1:TXLife/ns1:TXLifeRequest) &gt; 0">
        <ns1:TXLife xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://ACORD.org/Standards/Life/2 TXLife2.10.00.XSD">
          <!-- GET and SET Retry.Count -->
          <xsl:variable name="RetryInc" select="converter:getAttributeString('Retry.Count')+1" />
          <xsl:variable name="storeRetries" select="ta:setAttribute($attributes, 'Retry.Count', string($RetryInc))" />
          <!-- ADD UserAuthRequest Section -->
          <xsl:copy-of select="exsl:node-set($order)/ns1:TXLife/ns1:UserAuthRequest" />
          <xsl:for-each select="XCSRecord">
            <xsl:variable name="rowNum" select="position()" />
            <xsl:choose>
              <xsl:when test="ORDERNO[contains(.,'ERROR')]">
                <xsl:copy-of select="exsl:node-set($order)/ns1:TXLife/ns1:TXLifeRequest[$rowNum]" />
              </xsl:when>
              <xsl:otherwise>
                <xsl:copy-of select="." />
              </xsl:otherwise>
            </xsl:choose>
          </xsl:for-each>
        </ns1:TXLife>
      </xsl:when>
      <xsl:otherwise>
        <bo:TXLife xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://ACORD.org/Standards/Life/2 TXLife2.10.00.XSD">
          <!-- GET and SET Retry.Count -->
          <xsl:variable name="RetryInc" select="converter:getAttributeString('Retry.Count')+1" />
          <xsl:variable name="storeRetries" select="ta:setAttribute($attributes, 'Retry.Count', string($RetryInc))" />
          <!-- ADD UserAuthRequest Section -->
          <xsl:copy-of select="exsl:node-set($order)/TXLife/UserAuthRequest" />
          <xsl:for-each select="XCSRecord">
            <xsl:variable name="rowNum" select="position()" />
            <xsl:choose>
              <xsl:when test="ORDERNO[contains(.,'ERROR')]">
                <xsl:copy-of select="exsl:node-set($order)/TXLife/TXLifeRequest[$rowNum]" />
              </xsl:when>
              <xsl:otherwise>
                <xsl:copy-of select="." />
              </xsl:otherwise>
            </xsl:choose>
          </xsl:for-each>
        </bo:TXLife>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>