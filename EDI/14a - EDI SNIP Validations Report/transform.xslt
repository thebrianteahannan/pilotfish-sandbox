<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fun="http://www.w3.org/2005/xpath-functions" exclude-result-prefixes="fun" version="3.1">
  <xsl:param name="segment-delimiter" />
  <xsl:param name="element-delimiter" />
  <xsl:variable name="escaped-segment-delimiter" select="if (fun:matches($segment-delimiter, '[\.\+\*\?\^\$\(\)\[\]\}\{\|]')) then fun:replace($segment-delimiter ,'[\.\+\*\?\^\$\(\)\[\]\}\{\|]', fun:concat('\\', $segment-delimiter)) else $segment-delimiter" />
  <xsl:variable name="escaped-element-delimiter" select="if (fun:matches($element-delimiter ,'[\.\+\*\?\^\$\(\)\[\]\}\{\|]')) then fun:replace($element-delimiter ,'[\.\+\*\?\^\$\(\)\[\]\}\{\|]', fun:concat('\\', $element-delimiter)) else $element-delimiter" />
  <xsl:template match="/">
    <map>
      <xsl:variable name="parse">
        <xsl:for-each select="fun:tokenize(./XCSData/text(), $escaped-segment-delimiter)">
          <seg>
            <xsl:variable name="line-number" select="position()" />
            <xsl:attribute name="ln">
              <xsl:value-of select="position()" />
            </xsl:attribute>
            <xsl:attribute name="id">
              <xsl:value-of select="normalize-space((fun:tokenize(., $escaped-element-delimiter))[1])" />
            </xsl:attribute>
            <xsl:for-each select="fun:tokenize(., $escaped-element-delimiter)">
              <ele>
                <xsl:value-of select="normalize-space(.)" />
              </ele>
            </xsl:for-each>
          </seg>
        </xsl:for-each>
      </xsl:variable>
      <xsl:variable name="map">
        <xsl:for-each select="$parse//seg">
          <seg>
            <xsl:attribute name="ln">
              <xsl:value-of select="@ln" />
            </xsl:attribute>
            <xsl:attribute name="tpar">
              <xsl:value-of select="((self::*|preceding-sibling::*)[@id='ST']/@ln)[last()]" />
            </xsl:attribute>
            <xsl:attribute name="gpar">
              <xsl:value-of select="((self::*|preceding-sibling::*)[@id='GS']/@ln)[last()]" />
            </xsl:attribute>
            <xsl:variable name="parent" select="./@ln - ((self::*|preceding-sibling::seg)[@id='ST']/@ln)[last()]+1" />
            <xsl:attribute name="tseg">
              <xsl:value-of select="$parent" />
            </xsl:attribute>
            <xsl:attribute name="id">
              <xsl:value-of select="@id" />
            </xsl:attribute>
            <xsl:attribute name="gp">
              <xsl:value-of select="count((self::*|preceding-sibling::*)[@id='GS'])" />
            </xsl:attribute>
            <xsl:attribute name="tr">
              <xsl:value-of select="count((self::*|preceding-sibling::*)[@id='ST'])" />
            </xsl:attribute>
            <xsl:copy-of select="./*[position() &gt; 1]" />
          </seg>
        </xsl:for-each>
      </xsl:variable>
      <xsl:copy-of select="$map" />
    </map>
  </xsl:template>
</xsl:stylesheet>

