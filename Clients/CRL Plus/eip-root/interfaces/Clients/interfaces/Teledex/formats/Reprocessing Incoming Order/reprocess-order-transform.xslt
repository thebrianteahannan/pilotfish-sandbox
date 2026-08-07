<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:bo="http://ACORD.org/Standards/Life/2" xmlns:converter="xalan://com.pilotfish.eip.transform.ConverterProxy" xmlns:exsl="http://exslt.org/common" exclude-result-prefixes="converter" extension-element-prefixes="converter" version="1.0">
  <xsl:template match="XCSData">
    <xsl:value-of select="converter:getAttribute('Order')" />
  </xsl:template>
</xsl:stylesheet>

