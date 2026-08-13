<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" indent="yes" encoding="UTF-8"/>
  <xsl:param name="AuthTraceNumber"/>
  <xsl:param name="MemberId"/>
  <xsl:param name="PatientLast"/>
  <xsl:param name="PatientFirst"/>
  <xsl:param name="ProcedureCode"/>
  <xsl:param name="DiagnosisCode"/>
  <xsl:param name="AttachmentFlag"/>
  <xsl:param name="RequiresDiagnosis"/>
  <xsl:param name="RequiresAttachment"/>
  <xsl:param name="DefaultDisposition"/>
  <xsl:variable name="dx" select="normalize-space($DiagnosisCode)"/>
  <xsl:variable name="att" select="upper-case(normalize-space($AttachmentFlag))"/>
  <xsl:variable name="needDx" select="normalize-space($RequiresDiagnosis) = '1' or upper-case(normalize-space($RequiresDiagnosis)) = 'TRUE'"/>
  <xsl:variable name="needAtt" select="normalize-space($RequiresAttachment) = '1' or upper-case(normalize-space($RequiresAttachment)) = 'TRUE'"/>
  <xsl:variable name="missingDx" select="$needDx and $dx = ''"/>
  <xsl:variable name="missingAtt" select="$needAtt and not($att = 'Y' or $att = '1' or $att = 'TRUE')"/>
  <xsl:variable name="incomplete" select="$missingDx or $missingAtt"/>
  <xsl:variable name="disp" select="upper-case(normalize-space($DefaultDisposition))"/>
  <xsl:template match="/">
    <AuthDecision>
      <AuthTraceNumber><xsl:value-of select="$AuthTraceNumber"/></AuthTraceNumber>
      <MemberId><xsl:value-of select="$MemberId"/></MemberId>
      <PatientLastName><xsl:value-of select="$PatientLast"/></PatientLastName>
      <PatientFirstName><xsl:value-of select="$PatientFirst"/></PatientFirstName>
      <ProcedureCode><xsl:value-of select="$ProcedureCode"/></ProcedureCode>
      <DiagnosisCode><xsl:value-of select="$dx"/></DiagnosisCode>
      <AttachmentFlag><xsl:value-of select="if ($att='') then 'N' else $att"/></AttachmentFlag>
      <xsl:choose>
        <xsl:when test="$incomplete">
          <Disposition>INCOMPLETE</Disposition>
          <DecisionBucket>incomplete</DecisionBucket>
          <Notes>
            <xsl:if test="$missingDx">MISSING_DIAGNOSIS</xsl:if>
            <xsl:if test="$missingDx and $missingAtt"> </xsl:if>
            <xsl:if test="$missingAtt">MISSING_ATTACHMENT</xsl:if>
          </Notes>
        </xsl:when>
        <xsl:when test="$disp = 'DENY'">
          <Disposition>DENIED</Disposition>
          <DecisionBucket>denied</DecisionBucket>
          <Notes>Catalog disposition DENY</Notes>
        </xsl:when>
        <xsl:when test="$disp = 'PEND'">
          <Disposition>PENDED</Disposition>
          <DecisionBucket>pended</DecisionBucket>
          <Notes>Catalog disposition PEND</Notes>
        </xsl:when>
        <xsl:otherwise>
          <Disposition>APPROVED</Disposition>
          <DecisionBucket>approved</DecisionBucket>
          <Notes>Catalog disposition APPROVE</Notes>
        </xsl:otherwise>
      </xsl:choose>
    </AuthDecision>
  </xsl:template>
</xsl:stylesheet>
