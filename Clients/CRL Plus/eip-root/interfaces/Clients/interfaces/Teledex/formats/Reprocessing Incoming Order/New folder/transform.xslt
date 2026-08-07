<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:bo="http://ACORD.org/Standards/Life/2" xmlns:converter="xalan://com.pilotfish.eip.transform.ConverterProxy" xmlns:dyn="http://exslt.org/dynamic" xmlns:exsl="http://exslt.org/common" xmlns:java="http://xml.apache.org/xalan/java" xmlns:util="xalan://com.pilotfish.custom.crlplus.Utils" exclude-result-prefixes="converter" extension-element-prefixes="converter" version="1.0">
  <xsl:template match="XCSData">
    <converter:register class="com.pilotfish.eip.transform.converters.EchoConverter" name="EchoConverter" params="EchoField">
      <Mode>Echo</Mode>
    </converter:register>
		<xsl:variable name="order">
			<xsl:variable name="ord" select="converter:getAttributeString('Order')" />
			<xsl:variable name="Order" select="exsl:node-set(util:stringToNode($ord))" />
			<xsl:copy-of select="$Order" />
		</xsl:variable>
		<!--
    <xsl:variable name="ord" select="converter:getAttributeString('Order')" /> -->
    <bo:TXLife xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://ACORD.org/Standards/Life/2 TXLife2.10.00.XSD">
      <xsl:for-each select="XCSRecord">
	  <xsl:variable name="rowNum" select="position()" />
<!--
        <xsl:copy-of select="exsl:node-set($order)/TXLife/TXLifeRequest[$rowNUM]" /> -->
        <xsl:variable name="rowNum" select="position()" />
        <xsl:choose>
          <xsl:when test="ORDERNO/text()='ERROR'">
            <!--
					<xsl:copy-of select="dyn:evaluate($Order)/bo:TXLifeRequest[$rowNum]" /> -->
            <!--<xsl:copy-of select="$order/bo:TXLife/bo:TXLifeRequest[$rowNum]" />-->
            <!--
						<xsl:variable name="path" select="concat('bo:TXLife|bo:TXLifeRequest[',$rowNum,']')" />
						<xsl:value-of select="$path" />
						<xsl:copy-of select="exsl:node-set(util:xpathNode($ord,$path))" /> -->
		<xsl:copy-of select="exsl:node-set($order)/TXLife/TXLifeRequest[$rowNum]" />
          </xsl:when>
          <xsl:otherwise>
            <xsl:copy-of select="." />
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </bo:TXLife>
  </xsl:template>
</xsl:stylesheet>

