<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ns1="http://pilotfish.sqlxml" version="3.1">
  <xsl:param name="Partition" />
  <xsl:param name="SoftwareId" />
  <xsl:template match="/">
    <ns1:SQLXML>
      <ns1:Select as="Client" into="PartitionConfig">
        <CLIENT_SPLITS>
          <SOFTWAREID key="true">
            <xsl:value-of select="$SoftwareId" />
          </SOFTWAREID>
          <CLIENTNAME />
          <PARTITION />
          <CLIENT />
          <FACILITY />
          <FACILITY_CODE />
          <DEFAULT_PERF_DR />
          <ACCOUNT_NUM_ALPHA />
          <DATE_RANGE />
          <IS_DEFAULT />
        </CLIENT_SPLITS>
      </ns1:Select>
      <ns1:XMLOut var="PartitionConfig" />
      <ns1:Select as="SplitCode" into="SplitCodes">
        <CLIENT_CODES>
          <FACILITY />
          <CODE />
          <COMPARATOR />
          <SOFTWARE_ID key="true">
            <xsl:value-of select="$SoftwareId" />
          </SOFTWARE_ID>
        </CLIENT_CODES>
      </ns1:Select>
      <ns1:XMLOut appendTo="PartitionConfig" var="SplitCodes" />
      <ns1:Select as="FlagLocation" into="FlagLocations">
        <FLG_LOCATIONS>
          <CODE />
          <DESCRIPTION />
          <SOFTWARE_ID key="true">
            <xsl:value-of select="$SoftwareId" />
          </SOFTWARE_ID>
        </FLG_LOCATIONS>
      </ns1:Select>
      <ns1:XMLOut appendTo="PartitionConfig" var="FlagLocations" />
      <ns1:Select as="MUE_Edit" into="MUE_Edits">
        <MUE_EDITS>
          <SOFTWARE_ID key="true">
            <xsl:value-of select="$SoftwareId" />
          </SOFTWARE_ID>
          <CPT />
          <MAX_VALUE_PER_LINE />
          <CDM />
        </MUE_EDITS>
      </ns1:Select>
      <ns1:XMLOut appendTo="PartitionConfig" var="MUE_Edits" />
      <ns1:Select as="StripLocation" into="StripLocations">
        <STRIP_LOCATIONS>
          <LOCATION />
          <LOCATION2 />
          <SOFTWARE_ID key="true">
            <xsl:value-of select="$SoftwareId" />
          </SOFTWARE_ID>
        </STRIP_LOCATIONS>
      </ns1:Select>
      <ns1:XMLOut appendTo="PartitionConfig" var="StripLocations" />
    </ns1:SQLXML>
  </xsl:template>
</xsl:stylesheet>

