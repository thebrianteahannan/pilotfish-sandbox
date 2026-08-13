<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:saxon="http://saxon.sf.net/" xmlns:xip="com.pilotfish.xquery.library" extension-element-prefix="saxon xip fn xs" version="3.1">
  <xsl:output cdata-section-elements="Text" method="xml" />
  <xsl:param name="map" />
  <xsl:variable name="map-document" select="fn:parse-xml($map)" />
  <xsl:template match="/">
    <xsl:copy>
      <xsl:apply-templates select="node()| @*" />
    </xsl:copy>
  </xsl:template>
  <xsl:template match="node() | @*">
    <xsl:copy>
      <xsl:apply-templates select="node() | @*" />
    </xsl:copy>
  </xsl:template>
  <xsl:template match="error">
    <xsl:variable name="Group" select="./Group" />
    <xsl:variable name="Transaction" select="./Transaction" />
    <xsl:variable name="Segment" select="./SegmentID" />
    <xsl:variable name="Segmentpos" select="./SegPosition" />
    <xsl:choose>
      <xsl:when test="./ViolationType=('Interchange', 'Group')">
        <xsl:copy>
          <xsl:copy-of select="./*" />
          <xsl:copy-of select="if (ViolationType='Group') then $map-document//seg[@id=$Segment and @gp=$Group] else $map-document//seg[@id=$Segment]" />
        </xsl:copy>
      </xsl:when>
      <xsl:when test="./ViolationType=('Segment', 'Transaction', 'Element', 'SNIP5')">
        <xsl:copy>
          <xsl:copy-of select="./*" />
          <xsl:variable name="Segmentpos" select="./SegPosition | (.//SegPosition)[1]" />
          <debug>
            <group>
              <xsl:value-of select="$Group" />
            </group>
            <trans>
              <xsl:value-of select="$Transaction" />
            </trans>
            <seg>
              <xsl:value-of select="$Segment" />
            </seg>
            <pos>
              <xsl:value-of select="$Segmentpos" />
            </pos>
          </debug>
          <xsl:variable name="noMatchLine" select="string-length($Segmentpos)=0 or $Segmentpos = '0'" />
          <xsl:choose>
            <xsl:when test="$noMatchLine">
              <!--Report error at end of SE segment if segment postion is not available-->
              <xsl:copy-of select="$map-document//seg[(@id='SE' and @gp=$Group and @tr=$Transaction)]" />
            </xsl:when>
            <xsl:otherwise>
              <xsl:copy-of select="$map-document//seg[(@id=$Segment and @gp=$Group and @tr=$Transaction and @tseg=$Segmentpos ) or (@gp=$Group and @tr=$Transaction and @tseg=$Segmentpos)]" />
            </xsl:otherwise>
          </xsl:choose>
        </xsl:copy>
      </xsl:when>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>

