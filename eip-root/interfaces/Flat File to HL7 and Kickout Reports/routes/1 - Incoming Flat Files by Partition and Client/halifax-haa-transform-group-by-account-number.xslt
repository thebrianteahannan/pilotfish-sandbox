<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:local="urn:local-functions" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs local" version="3.1">
  <xsl:output indent="yes" method="xml" />
  <xsl:strip-space elements="*" />
  <!-- Diagnosis fields are preserved from all grouped rows. -->
  <xsl:variable as="xs:string*" name="diagnosis-fields" select="(       'PRIM_DIAGNOSIS_CODE',       'SECONDARY_DIAGNOSIS_CODE1',       'SECONDARY_DIAG_CODE2',       'SECONDARY_DIAG_CODE3',       'SECONDARY_DIAG_CODE4',       'SECONDARY_DIAG_CODE5',       'SECONDARY_DIAG_CODE6',       'SECONDARY_DIAG_CODE7',       'SECONDARY_DIAG_CODE8'     )" />
  <!-- Per-charge-line fields: taken from each source row so PROCEDURE_CODE, qty, service date, etc. are not lost when grouping by account. -->
  <xsl:variable as="xs:string*" name="charge-line-fields" select="(       'QUANTITY',       'SERVICE_DATE',       'PROCEDURE_CODE',       'SPECIMEN_EXTERNAL_ID',       'BILLING_PROV_NPI',       'BILLING_PROV'     )" />
  <!-- Parse dates like M/D/YYYY or MMDDYYYY to sortable YYYYMMDD number. -->
  <xsl:function as="xs:integer" name="local:date-key">
    <xsl:param as="xs:string?" name="value" />
    <xsl:variable name="v" select="normalize-space($value)" />
    <xsl:choose>
      <xsl:when test="matches($v, '^\d{1,2}/\d{1,2}/\d{4}$')">
        <xsl:variable name="parts" select="tokenize($v, '/')" />
        <xsl:sequence select="xs:integer(concat(           $parts[3],           format-number(xs:integer($parts[1]), '00'),           format-number(xs:integer($parts[2]), '00')         ))" />
      </xsl:when>
      <xsl:when test="matches($v, '^\d{8}$')">
        <xsl:sequence select="xs:integer(concat(substring($v, 5, 4), substring($v, 1, 4)))" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="0" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  <xsl:template match="/XCSData">
    <XCSData>
      <xsl:for-each-group group-by="normalize-space(HSP_CSN)" select="XCSRecord">
        <xsl:variable as="element(XCSRecord)*" name="group" select="current-group()" />
        <xsl:variable as="xs:integer" name="latest-date" select="max(for $r in $group return local:date-key(string($r/SERVICE_DATE[1])))" />
        <xsl:variable as="element(XCSRecord)*" name="latest-records" select="$group[local:date-key(string(SERVICE_DATE[1])) = $latest-date]" />
        <xsl:variable as="element(XCSRecord)" name="first-latest" select="$latest-records[1]" />
        <xsl:variable as="xs:string*" name="all-diag-codes-raw">
          <xsl:for-each select="$group">
            <xsl:variable as="element(XCSRecord)" name="rec" select="." />
            <xsl:for-each select="$diagnosis-fields">
              <xsl:variable as="xs:string" name="diag-name" select="." />
              <xsl:variable as="xs:string" name="diag-value" select="normalize-space(string($rec/*[name() = $diag-name][1]))" />
              <xsl:if test="$diag-value ne ''">
                <xsl:sequence select="$diag-value" />
              </xsl:if>
            </xsl:for-each>
          </xsl:for-each>
        </xsl:variable>
        <xsl:variable as="xs:string*" name="all-diag-codes" select="distinct-values($all-diag-codes-raw)" />
        <xsl:variable as="xs:integer" name="group-pos" select="position()" />
        <xsl:for-each select="$group">
          <xsl:variable as="element(XCSRecord)" name="rec" select="." />
          <XCSRecord row="{($group-pos - 1) * 10000 + position() - 1}">
            <xsl:for-each select="$first-latest/*">
              <xsl:variable as="xs:string" name="field-name" select="name()" />
              <xsl:choose>
                <xsl:when test="$field-name = $diagnosis-fields">
                  <xsl:element name="{$field-name}">
                    <xsl:variable as="xs:integer" name="diag-index" select="index-of($diagnosis-fields, $field-name)[1]" />
                    <xsl:value-of select="$all-diag-codes[$diag-index]" />
                  </xsl:element>
                </xsl:when>
                <xsl:when test="$field-name = $charge-line-fields">
                  <xsl:element name="{$field-name}">
                    <xsl:value-of select="$rec/*[name() = $field-name]" />
                  </xsl:element>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:copy-of select="." />
                </xsl:otherwise>
              </xsl:choose>
            </xsl:for-each>
          </XCSRecord>
        </xsl:for-each>
      </xsl:for-each-group>
    </XCSData>
  </xsl:template>
</xsl:stylesheet>

