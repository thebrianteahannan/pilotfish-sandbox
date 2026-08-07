<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ns1="http://ACORD.org/Standards/Life/2" exclude-result-prefixes="ns1" version="1.0">
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>
  <xsl:template match="ns1:RequirementInfo[ns1:ReqCode/@tc='265' or ns1:ReqCode/@tc='13' or ns1:ReqCode/@tc='14' or ns1:ReqCode/@tc='265' or ns1:ReqCode/@tc='631' or ns1:Attachment/ns1:Description='CONSENT' or ns1:Attachment/ns1:Description='Admin Forms - HIV Consent' or ns1:Attachment/ns1:Description='Checklist' or ns1:Attachment/ns1:Description='Admin Forms - General' or ns1:Attachment/ns1:Description='Paramed Exam Order Form' or ns1:Attachment/ns1:AttachmentSource='Age-based Functional Test']" />
  <xsl:template match="ns1:Attachment[ns1:Description='Laboratory Report']" />
</xsl:stylesheet>

