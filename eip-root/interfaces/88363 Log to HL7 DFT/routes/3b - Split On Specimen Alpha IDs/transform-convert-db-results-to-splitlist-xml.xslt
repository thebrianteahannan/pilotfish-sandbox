<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:template match="/">
    <Splits>
      <xsl:for-each-group group-by="FACILITY" select="RESULT/SIMPLEQUERY">
        <Split>
          <xsl:attribute name="name" select="current-grouping-key()" />
          <xsl:attribute name="prefix" select="ACCTNOPREFIX" />
          <xsl:attribute name="shortname" select="NAME" />
          <Codes>
            <xsl:for-each select="current-group()/CODE">
              <Code>
                <xsl:value-of select="." />
              </Code>
            </xsl:for-each>
          </Codes>
        </Split>
      </xsl:for-each-group>
    </Splits>
  </xsl:template>
</xsl:stylesheet>

