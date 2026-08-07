<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:dtFormatter="xalan://com.pilotfish.eip.gui.mapper.util.DateTimeFormatter" xmlns:ns1="https://www.dell.com" xmlns:ns2="http://ACORD.org/Standards/Life/2" xmlns:ta="xalan://com.pilotfish.eip.TransactionAttributes" xmlns:td="xalan://com.pilotfish.eip.TransactionData" exclude-result-prefixes="ns1 dtFormatter ta td" version="1.0">
  <xsl:param name="eiPlatformTransactionData" />
  <xsl:variable name="attributes" select="td:getAttributes($eiPlatformTransactionData)" />
  <!-- IdentityTransform -->
  <xsl:template match="/ | @* | node()">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()" />
    </xsl:copy>
  </xsl:template>
  <xsl:template match="/ns2:TXLife">
    <xsl:variable name="TransType" select="*[local-name()='TXLifeRequest']/*[local-name()='TransType']/@tc" />
    <soap12:Envelope xmlns:soap12="http://www.w3.org/2003/05/soap-envelope" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <soap12:Body>
        <xsl:choose>
          <xsl:when test="$TransType='103'">
            <TXlifeProcessor xmlns="https://www.dell.com">
              <XML>
                <xsl:copy>
                  <xsl:apply-templates select="@* | node()" />
                </xsl:copy>
              </XML>
            </TXlifeProcessor>
          </xsl:when>
          <xsl:otherwise>
            <NoteProcessor xmlns="https://www.dell.com">
              <XML>
                <xsl:copy-of select="." />
              </XML>
            </NoteProcessor>
          </xsl:otherwise>
        </xsl:choose>
      </soap12:Body>
    </soap12:Envelope>
  </xsl:template>
  <!-- retrieve large attachments -->
  <xsl:template match="ns2:AttachmentData[string-length(.)&gt;0 and string-length(.)&lt;20]">
    <!-- for large attachments, the value of AttachmentData is actually the name of a 
			transaction attribute containing the base-64 encoded attachment -->
    <xsl:copy>
      <xsl:value-of select="ta:getAttribute($attributes, string(.))" />
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>

