<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  exclude-result-prefixes="xsl xs">
  <xsl:output method="xml" indent="yes" encoding="UTF-8"/>

  <xsl:param name="AuthTraceNumber" select="''"/>
  <xsl:param name="MemberId" select="''"/>
  <xsl:param name="PatientLastName" select="''"/>
  <xsl:param name="PatientFirstName" select="''"/>
  <xsl:param name="ProcedureCodeRaw" select="''"/>
  <xsl:param name="DiagnosisCodeRaw" select="''"/>
  <xsl:variable name="ProcedureCode" select="normalize-space(replace(replace(replace($ProcedureCodeRaw, '^HC[: ]*', '', 'i'), '\s+', ''), ':', ''))"/>
  <xsl:variable name="DiagnosisCode" select="normalize-space(replace(replace($DiagnosisCodeRaw, '^ABK[: ]*', '', 'i'), '\s+', ' '))"/>
  <xsl:param name="AttachmentFlag" select="'N'"/>
  <xsl:param name="RequiresDiagnosis" select="''"/>
  <xsl:param name="RequiresAttachment" select="''"/>
  <xsl:param name="DefaultDisposition" select="''"/>
  <xsl:param name="CatalogFound" select="''"/>
  <xsl:param name="SourceFile" select="''"/>

  <xsl:variable name="memberOk" select="string-length(normalize-space($MemberId)) &gt; 0"/>
  <xsl:variable name="nameOk" select="string-length(normalize-space($PatientLastName)) &gt; 0"/>
  <xsl:variable name="procOk" select="string-length(normalize-space($ProcedureCode)) &gt; 0"/>
  <xsl:variable name="dxRequired" select="
    if (normalize-space($RequiresDiagnosis) = '1' or upper-case(normalize-space($RequiresDiagnosis)) = 'TRUE')
    then true()
    else if (normalize-space($CatalogFound) != 'true') then true()
    else false()"/>
  <xsl:variable name="dxOk" select="
    if ($dxRequired) then string-length(normalize-space($DiagnosisCode)) &gt; 0 else true()"/>
  <xsl:variable name="attRequired" select="
    normalize-space($RequiresAttachment) = '1' or upper-case(normalize-space($RequiresAttachment)) = 'TRUE'"/>
  <xsl:variable name="attOk" select="
    if ($attRequired) then upper-case(normalize-space($AttachmentFlag)) = 'Y' else true()"/>
  <xsl:variable name="complete" select="$memberOk and $nameOk and $procOk and $dxOk and $attOk"/>

  <xsl:variable name="disposition" select="upper-case(normalize-space($DefaultDisposition))"/>
  <xsl:variable name="decisionBucket" select="
    if (not($complete)) then 'incomplete'
    else if ($disposition = 'DENY') then 'denied'
    else if ($disposition = 'PEND') then 'pended'
    else if ($disposition = 'APPROVE') then 'approved'
    else if (normalize-space($CatalogFound) != 'true') then 'incomplete'
    else 'pended'"/>
  <xsl:variable name="reason" select="
    if (not($memberOk)) then 'MISSING_MEMBER'
    else if (not($nameOk)) then 'MISSING_PATIENT_NAME'
    else if (not($procOk)) then 'MISSING_PROCEDURE'
    else if (not($dxOk)) then 'MISSING_DIAGNOSIS'
    else if (not($attOk)) then 'MISSING_ATTACHMENT'
    else if (normalize-space($CatalogFound) != 'true') then 'UNKNOWN_PROCEDURE'
    else if ($disposition = 'DENY') then 'PAYER_DENIED'
    else if ($disposition = 'PEND') then 'PAYER_PENDED'
    else if ($disposition = 'APPROVE') then 'PAYER_APPROVED'
    else 'PAYER_PENDED'"/>

  <xsl:template match="/">
    <AuthDecision>
      <AuthTraceNumber><xsl:value-of select="$AuthTraceNumber"/></AuthTraceNumber>
      <MemberId><xsl:value-of select="$MemberId"/></MemberId>
      <PatientLastName><xsl:value-of select="$PatientLastName"/></PatientLastName>
      <PatientFirstName><xsl:value-of select="$PatientFirstName"/></PatientFirstName>
      <PatientName>
        <xsl:value-of select="concat(normalize-space($PatientLastName), ',', normalize-space($PatientFirstName))"/>
      </PatientName>
      <ProcedureCode><xsl:value-of select="$ProcedureCode"/></ProcedureCode>
      <DiagnosisCode><xsl:value-of select="$DiagnosisCode"/></DiagnosisCode>
      <AttachmentFlag><xsl:value-of select="upper-case(normalize-space($AttachmentFlag))"/></AttachmentFlag>
      <RequiresDiagnosis><xsl:value-of select="if ($dxRequired) then 'true' else 'false'"/></RequiresDiagnosis>
      <RequiresAttachment><xsl:value-of select="if ($attRequired) then 'true' else 'false'"/></RequiresAttachment>
      <CatalogFound><xsl:value-of select="$CatalogFound"/></CatalogFound>
      <CompletenessOk><xsl:value-of select="if ($complete) then 'true' else 'false'"/></CompletenessOk>
      <DecisionBucket><xsl:value-of select="$decisionBucket"/></DecisionBucket>
      <Reason><xsl:value-of select="$reason"/></Reason>
      <SourceFile><xsl:value-of select="$SourceFile"/></SourceFile>
    </AuthDecision>
  </xsl:template>
</xsl:stylesheet>
