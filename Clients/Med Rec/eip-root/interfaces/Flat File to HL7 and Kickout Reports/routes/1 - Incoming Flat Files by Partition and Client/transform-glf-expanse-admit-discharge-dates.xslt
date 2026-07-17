<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:local="http://local.functions" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs local" version="3.1">
  <xsl:output encoding="UTF-8" indent="yes" method="xml" version="1.0" />
  <!--
    GLF Expanse canonical post-processing:
    - PV1.44 (absAdmitdate): when blank, use the earliest charge service date in the Group.
    - PV1.45 (absdischargedate): leave blank when blank (identity transform).
    - PV2.28 (ARSA): downstream HL7 uses absAdmitdate; populating it here covers blank ARSA cases.
  -->
  <xsl:function as="xs:string?" name="local:earliestChargeDate">
    <xsl:param as="element(Group)" name="group" />
    <xsl:sequence select="min(       for $charge in $group/Charge[not(@stripped = 'true')]       return (         if (normalize-space($charge/radExamServDate) != '') then normalize-space($charge/radExamServDate)         else if (normalize-space($charge/ExamBillDate) != '') then normalize-space($charge/ExamBillDate)         else ()       )     )" />
  </xsl:function>
  <xsl:template match="@* | node()">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()" />
    </xsl:copy>
  </xsl:template>
  <xsl:template match="Group/PatientDemographics">
    <PatientDemographics>
      <xsl:apply-templates select="@*" />
      <xsl:for-each select="node()">
        <xsl:choose>
          <xsl:when test="self::absAdmitdate">
            <absAdmitdate>
              <xsl:variable name="group" select="ancestor::Group[1]" />
              <xsl:choose>
                <xsl:when test="normalize-space(.) != ''">
                  <xsl:value-of select="normalize-space(.)" />
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="local:earliestChargeDate($group)" />
                </xsl:otherwise>
              </xsl:choose>
            </absAdmitdate>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="." />
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
      <xsl:if test="not(absAdmitdate)">
        <absAdmitdate>
          <xsl:value-of select="local:earliestChargeDate(ancestor::Group[1])" />
        </absAdmitdate>
      </xsl:if>
    </PatientDemographics>
  </xsl:template>
</xsl:stylesheet>

