<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:err="http://www.pilotfishtechnology.com/eip/RouteErrorReport" version="1.0">
  <xsl:param name="AuthenticationValid" />
  <xsl:template match="/Messages">
    <err:errorReport>
      <err:errorRoute>Authentication and Validation</err:errorRoute>
      <xsl:choose>
        <xsl:when test="($AuthenticationValid = 'false') and Message[@level = 'error']">
          <err:exceptionMessage>Message failed validation and authentication</err:exceptionMessage>
        </xsl:when>
        <xsl:when test="Message[@level = 'error']">
          <err:exceptionMessage>Message failed validation</err:exceptionMessage>
        </xsl:when>
        <xsl:otherwise>
          <err:exceptionMessage>Message failed authentication</err:exceptionMessage>
        </xsl:otherwise>
      </xsl:choose>
      <err:exceptionTrace>
        <xsl:if test="$AuthenticationValid = 'false'">
          <xsl:text>The credentials provided are not valid</xsl:text>
        </xsl:if>
        <xsl:for-each select="Message[@level = 'error']">
          <xsl:if test="($AuthenticationValid = 'false') or (position() &gt; 1)">
            <xsl:text>/</xsl:text>
          </xsl:if>
          <xsl:value-of select="." />
        </xsl:for-each>
      </err:exceptionTrace>
    </err:errorReport>
  </xsl:template>
</xsl:stylesheet>

