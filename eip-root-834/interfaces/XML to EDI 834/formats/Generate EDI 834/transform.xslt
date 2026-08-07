<?xml version="1.0" encoding="UTF-8"?>
<!-- Generic XML EnrollmentBatch -> minimal HIPAA X12 834 (synthetic demo data only) -->
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="text" encoding="UTF-8"/>
  <xsl:variable name="seg" select="'~'"/>
  <xsl:variable name="el" select="'*'"/>
  <xsl:variable name="now" select="current-dateTime()"/>
  <xsl:variable name="yyMMdd" select="format-dateTime($now, '[Y01][M01][D01]')"/>
  <xsl:variable name="yyyyMMdd" select="format-dateTime($now, '[Y0001][M01][D01]')"/>
  <xsl:variable name="HHmm" select="format-dateTime($now, '[H01][m01]')"/>

  <xsl:template name="pad-isa">
    <xsl:param name="value"/>
    <xsl:variable name="trimmed" select="normalize-space($value)"/>
    <xsl:value-of select="substring(concat($trimmed, '               '), 1, 15)"/>
  </xsl:template>

  <xsl:template match="/">
    <xsl:variable name="batch" select="EnrollmentBatch"/>
    <xsl:variable name="isaCtrl" select="format-number(number(($batch/Interchange/ControlNumber, '1')[1]), '000000000')"/>
    <xsl:variable name="gsCtrl" select="string(($batch/Group/GroupControlNumber, '1')[1])"/>
    <xsl:variable name="stCtrl" select="string(($batch/Transaction/TransactionSetControlNumber, '0001')[1])"/>
    <xsl:variable name="usage" select="string(($batch/Interchange/UsageIndicator, 'T')[1])"/>
    <xsl:variable name="sender">
      <xsl:call-template name="pad-isa">
        <xsl:with-param name="value" select="($batch/Interchange/SenderId, 'ACMEPAYER')[1]"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="receiver">
      <xsl:call-template name="pad-isa">
        <xsl:with-param name="value" select="($batch/Interchange/ReceiverId, 'ACMESPONSOR')[1]"/>
      </xsl:call-template>
    </xsl:variable>

    <!-- ISA -->
    <xsl:text>ISA</xsl:text><xsl:value-of select="$el"/>
    <xsl:text>00</xsl:text><xsl:value-of select="$el"/>
    <xsl:text>          </xsl:text><xsl:value-of select="$el"/>
    <xsl:text>00</xsl:text><xsl:value-of select="$el"/>
    <xsl:text>          </xsl:text><xsl:value-of select="$el"/>
    <xsl:text>ZZ</xsl:text><xsl:value-of select="$el"/>
    <xsl:value-of select="$sender"/><xsl:value-of select="$el"/>
    <xsl:text>ZZ</xsl:text><xsl:value-of select="$el"/>
    <xsl:value-of select="$receiver"/><xsl:value-of select="$el"/>
    <xsl:value-of select="$yyMMdd"/><xsl:value-of select="$el"/>
    <xsl:value-of select="$HHmm"/><xsl:value-of select="$el"/>
    <xsl:text>^</xsl:text><xsl:value-of select="$el"/>
    <xsl:text>00501</xsl:text><xsl:value-of select="$el"/>
    <xsl:value-of select="$isaCtrl"/><xsl:value-of select="$el"/>
    <xsl:text>0</xsl:text><xsl:value-of select="$el"/>
    <xsl:value-of select="$usage"/><xsl:value-of select="$el"/>
    <xsl:text>:</xsl:text><xsl:value-of select="$seg"/><xsl:text>&#10;</xsl:text>

    <!-- GS -->
    <xsl:text>GS</xsl:text><xsl:value-of select="$el"/>
    <xsl:text>BE</xsl:text><xsl:value-of select="$el"/>
    <xsl:value-of select="($batch/Group/ApplicationSender, $batch/Interchange/SenderId, 'ACMEPAYER')[1]"/><xsl:value-of select="$el"/>
    <xsl:value-of select="($batch/Group/ApplicationReceiver, $batch/Interchange/ReceiverId, 'ACMESPONSOR')[1]"/><xsl:value-of select="$el"/>
    <xsl:value-of select="$yyyyMMdd"/><xsl:value-of select="$el"/>
    <xsl:value-of select="$HHmm"/><xsl:value-of select="$el"/>
    <xsl:value-of select="$gsCtrl"/><xsl:value-of select="$el"/>
    <xsl:text>X</xsl:text><xsl:value-of select="$el"/>
    <xsl:text>005010X220A1</xsl:text><xsl:value-of select="$seg"/><xsl:text>&#10;</xsl:text>

    <!-- ST -->
    <xsl:text>ST</xsl:text><xsl:value-of select="$el"/>
    <xsl:text>834</xsl:text><xsl:value-of select="$el"/>
    <xsl:value-of select="$stCtrl"/><xsl:value-of select="$el"/>
    <xsl:text>005010X220A1</xsl:text><xsl:value-of select="$seg"/><xsl:text>&#10;</xsl:text>

    <!-- BGN -->
    <xsl:text>BGN</xsl:text><xsl:value-of select="$el"/>
    <xsl:value-of select="($batch/Transaction/PurposeCode, '00')[1]"/><xsl:value-of select="$el"/>
    <xsl:value-of select="($batch/Transaction/ReferenceId, 'BATCH001')[1]"/><xsl:value-of select="$el"/>
    <xsl:value-of select="$yyyyMMdd"/><xsl:value-of select="$el"/>
    <xsl:value-of select="$HHmm"/><xsl:value-of select="$el"/>
    <xsl:value-of select="$el"/><xsl:value-of select="$el"/><xsl:value-of select="$el"/>
    <xsl:text>4</xsl:text><xsl:value-of select="$seg"/><xsl:text>&#10;</xsl:text>

    <!-- N1 sponsor (P5) -->
    <xsl:text>N1</xsl:text><xsl:value-of select="$el"/>
    <xsl:text>P5</xsl:text><xsl:value-of select="$el"/>
    <xsl:value-of select="($batch/Sponsor/Name, 'ACME SPONSOR INC')[1]"/><xsl:value-of select="$el"/>
    <xsl:value-of select="($batch/Sponsor/IdQualifier, 'FI')[1]"/><xsl:value-of select="$el"/>
    <xsl:value-of select="($batch/Sponsor/Id, '123456789')[1]"/><xsl:value-of select="$seg"/><xsl:text>&#10;</xsl:text>

    <!-- N1 payer (IN) -->
    <xsl:text>N1</xsl:text><xsl:value-of select="$el"/>
    <xsl:text>IN</xsl:text><xsl:value-of select="$el"/>
    <xsl:value-of select="($batch/Payer/Name, 'ACME HEALTH PLAN')[1]"/><xsl:value-of select="$el"/>
    <xsl:value-of select="($batch/Payer/IdQualifier, 'FI')[1]"/><xsl:value-of select="$el"/>
    <xsl:value-of select="($batch/Payer/Id, '987654321')[1]"/><xsl:value-of select="$seg"/><xsl:text>&#10;</xsl:text>

    <!-- SE01 counts ST..SE inclusive (not ISA/GS/GE/IEA): ST BGN N1 N1 + members + SE -->
    <xsl:variable name="headerSegs" select="4"/>
    <xsl:variable name="memberSegs" select="count($batch/Members/Member) * 6"/>
    <xsl:variable name="seCount" select="$headerSegs + $memberSegs + 1"/>

    <xsl:for-each select="$batch/Members/Member">
      <!-- INS -->
      <xsl:text>INS</xsl:text><xsl:value-of select="$el"/>
      <xsl:text>Y</xsl:text><xsl:value-of select="$el"/>
      <xsl:value-of select="(RelationshipCode, '18')[1]"/><xsl:value-of select="$el"/>
      <xsl:value-of select="(MaintenanceTypeCode, '030')[1]"/><xsl:value-of select="$el"/>
      <xsl:value-of select="(MaintenanceReasonCode, 'XN')[1]"/><xsl:value-of select="$el"/>
      <xsl:value-of select="(BenefitStatusCode, 'A')[1]"/><xsl:value-of select="$el"/>
      <xsl:value-of select="$el"/><xsl:value-of select="$el"/>
      <xsl:value-of select="(EmploymentStatusCode, 'FT')[1]"/><xsl:value-of select="$seg"/><xsl:text>&#10;</xsl:text>

      <!-- REF*0F subscriber number -->
      <xsl:text>REF</xsl:text><xsl:value-of select="$el"/>
      <xsl:text>0F</xsl:text><xsl:value-of select="$el"/>
      <xsl:value-of select="(MemberId, concat('MEM', position()))[1]"/><xsl:value-of select="$seg"/><xsl:text>&#10;</xsl:text>

      <!-- NM1*IL member name -->
      <xsl:text>NM1</xsl:text><xsl:value-of select="$el"/>
      <xsl:text>IL</xsl:text><xsl:value-of select="$el"/>
      <xsl:text>1</xsl:text><xsl:value-of select="$el"/>
      <xsl:value-of select="(LastName, 'SAMPLE')[1]"/><xsl:value-of select="$el"/>
      <xsl:value-of select="(FirstName, 'MEMBER')[1]"/><xsl:value-of select="$el"/>
      <xsl:value-of select="$el"/><xsl:value-of select="$el"/><xsl:value-of select="$el"/>
      <xsl:value-of select="(IdQualifier, '34')[1]"/><xsl:value-of select="$el"/>
      <xsl:value-of select="(IdentificationNumber, format-number(position(), '000000000'))[1]"/><xsl:value-of select="$seg"/><xsl:text>&#10;</xsl:text>

      <!-- DMG -->
      <xsl:text>DMG</xsl:text><xsl:value-of select="$el"/>
      <xsl:text>D8</xsl:text><xsl:value-of select="$el"/>
      <xsl:value-of select="(BirthDate, '19900101')[1]"/><xsl:value-of select="$el"/>
      <xsl:value-of select="(GenderCode, 'U')[1]"/><xsl:value-of select="$seg"/><xsl:text>&#10;</xsl:text>

      <!-- HD health coverage -->
      <xsl:text>HD</xsl:text><xsl:value-of select="$el"/>
      <xsl:text>030</xsl:text><xsl:value-of select="$el"/>
      <xsl:value-of select="$el"/>
      <xsl:text>HLT</xsl:text><xsl:value-of select="$el"/>
      <xsl:value-of select="(PlanId, 'PLANDEMO')[1]"/><xsl:value-of select="$seg"/><xsl:text>&#10;</xsl:text>

      <!-- DTP*348 coverage begin -->
      <xsl:text>DTP</xsl:text><xsl:value-of select="$el"/>
      <xsl:text>348</xsl:text><xsl:value-of select="$el"/>
      <xsl:text>D8</xsl:text><xsl:value-of select="$el"/>
      <xsl:value-of select="(CoverageStartDate, '20260101')[1]"/><xsl:value-of select="$seg"/><xsl:text>&#10;</xsl:text>
    </xsl:for-each>

    <!-- SE -->
    <xsl:text>SE</xsl:text><xsl:value-of select="$el"/>
    <xsl:value-of select="$seCount"/><xsl:value-of select="$el"/>
    <xsl:value-of select="$stCtrl"/><xsl:value-of select="$seg"/><xsl:text>&#10;</xsl:text>

    <!-- GE -->
    <xsl:text>GE</xsl:text><xsl:value-of select="$el"/>
    <xsl:text>1</xsl:text><xsl:value-of select="$el"/>
    <xsl:value-of select="$gsCtrl"/><xsl:value-of select="$seg"/><xsl:text>&#10;</xsl:text>

    <!-- IEA -->
    <xsl:text>IEA</xsl:text><xsl:value-of select="$el"/>
    <xsl:text>1</xsl:text><xsl:value-of select="$el"/>
    <xsl:value-of select="$isaCtrl"/><xsl:value-of select="$seg"/><xsl:text>&#10;</xsl:text>
  </xsl:template>
</xsl:stylesheet>
