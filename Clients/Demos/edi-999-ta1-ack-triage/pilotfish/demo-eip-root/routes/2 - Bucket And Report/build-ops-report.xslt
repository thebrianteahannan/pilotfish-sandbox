<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" indent="yes"/>
  <xsl:template match="/">
    <OpsReport>
      <Title>999/TA1 Acknowledgment Triage</Title>
      <xsl:copy-of select="/*"/>
      <Guidance>
        <xsl:choose>
          <xsl:when test="//DecisionBucket = 'accepted'">No action — functional group accepted.</xsl:when>
          <xsl:when test="//DecisionBucket = 'rejected'">Review IK3/IK4/IK5 or TA1 codes; fix and resubmit.</xsl:when>
          <xsl:otherwise>Unable to classify acknowledgment — inspect raw EDI.</xsl:otherwise>
        </xsl:choose>
      </Guidance>
    </OpsReport>
  </xsl:template>
</xsl:stylesheet>
