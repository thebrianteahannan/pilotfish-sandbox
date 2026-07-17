<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:param name="txtPartition" />
  <xsl:param name="txtInterfaceType" />
  <xsl:template match="/XCSData">
    <XCSExcelBook>
      <XCSExcelSheet>
        <!--Header row-->
        <XCSExcelRow>
          <Partition>Partition</Partition>
          <Interface_Type>Interface_Type</Interface_Type>
          <Location>Location</Location>
          <Account_Number>Account_Number</Account_Number>
          <Patient_Name>Patient_Name</Patient_Name>
          <DOS>DOS</DOS>
          <Units>Units</Units>
          <CDM>CDM</CDM>
          <CPT>CPT</CPT>
		  
        </XCSExcelRow>
        <!--TODO-->
      </XCSExcelSheet>
    </XCSExcelBook>
  </xsl:template>
</xsl:stylesheet>

