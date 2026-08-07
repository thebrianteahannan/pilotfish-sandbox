<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:bo="http://ACORD.org/Standards/Life/2" xmlns:converter="xalan://com.pilotfish.eip.transform.ConverterProxy" xmlns:dyn="http://exslt.org/dynamic" xmlns:exsl="http://exslt.org/common" xmlns:java="http://xml.apache.org/xalan/java" xmlns:util="xalan://com.pilotfish.custom.crlplus.Utils" exclude-result-prefixes="converter" extension-element-prefixes="converter" version="1.0">
  <xsl:template match="XCSData">
    <!--
		<xsl:variable name="orderClean">
			<xsl:variable name="Order">
				<xsl:value-of select="converter:getAttributeString('Order')" />
			</xsl:variable>
			<xsl:value-of select="exsl:node-set(java:com.pilotfish.custom.crlplus.Utils.stringToNode($Order))" />
		</xsl:variable>
		-->
    <converter:register class="com.pilotfish.eip.transform.converters.EchoConverter" name="EchoConverter" params="EchoField">
      <Mode>Echo</Mode>
    </converter:register>
    <xsl:variable name="order">
      <xsl:value-of select="converter:getAttribute('Order')" />
      <!--
			<xsl:variable name="Order" select="exsl:node-set(util:stringToNode($ord))" />-->
    </xsl:variable>
    <bo:TXLife xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://ACORD.org/Standards/Life/2 TXLife2.10.00.XSD">
      <xsl:for-each select="XCSRecord">
        <xsl:copy-of select="$order" />
        <xsl:variable name="rowNum" select="position()" />
        <xsl:choose>
          <xsl:when test="ORDERNO/text()='ERROR'">
            <!--
					<xsl:copy-of select="dyn:evaluate($Order)/bo:TXLifeRequest[$rowNum]" /> -->
          </xsl:when>
          <xsl:otherwise>
            <xsl:copy-of select="." />
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </bo:TXLife>
  </xsl:template>
</xsl:stylesheet>

