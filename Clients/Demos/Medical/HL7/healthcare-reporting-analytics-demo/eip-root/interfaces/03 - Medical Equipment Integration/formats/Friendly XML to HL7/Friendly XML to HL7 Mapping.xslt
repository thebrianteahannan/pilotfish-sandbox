<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:template match="/XCSData">
    <XCSData>
      <ORU_R01_Unsolicited_transmission_of_an_observation_message>
        <MSH_Message_Header>
          <MSH.1_Field_Separator>
            <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/MSH_Message_Header/MSH.1_Field_Separator" />
          </MSH.1_Field_Separator>
          <MSH.2_Encoding_Characters>
            <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/MSH_Message_Header/MSH.2_Encoding_Characters" />
          </MSH.2_Encoding_Characters>
        </MSH_Message_Header>
      </ORU_R01_Unsolicited_transmission_of_an_observation_message>
    </XCSData>
  </xsl:template>
</xsl:stylesheet>

